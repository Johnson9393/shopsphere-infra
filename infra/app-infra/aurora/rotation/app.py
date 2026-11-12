"""Rotate one environment's Aurora login and copy it to that environment's service secrets."""

import json
import secrets
import ssl
import string

import boto3
import pg8000.native

sm = boto3.client("secretsmanager")
SERVICES = ["product-service", "user-service", "order-service", "payment-service"]


def handler(event, context):
    step = event["Step"]
    secret_id = event["SecretId"]
    token = event["ClientRequestToken"]
    metadata = sm.describe_secret(SecretId=secret_id)
    versions = metadata["VersionIdsToStages"]
    if token not in versions:
        raise ValueError("Secret version is not set for this rotation")
    if "AWSCURRENT" in versions[token]:
        return
    if "AWSPENDING" not in versions[token]:
        raise ValueError("Secret version is not pending")

    if step == "createSecret":
        create_secret(secret_id, token)
    elif step == "setSecret":
        set_secret(secret_id, token)
    elif step == "testSecret":
        test_secret(secret_id, token)
    elif step == "finishSecret":
        finish_secret(secret_id, token)
    else:
        raise ValueError("Unknown rotation step")


def create_secret(secret_id, token):
    current = get_json(secret_id, "AWSCURRENT")
    try:
        sm.get_secret_value(SecretId=secret_id, VersionId=token, VersionStage="AWSPENDING")
        return
    except sm.exceptions.ResourceNotFoundException:
        pass
    pending = dict(current)
    pending["password"] = new_password()
    sm.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=token,
        SecretString=json.dumps(pending),
        VersionStages=["AWSPENDING"],
    )


def set_secret(secret_id, token):
    pending = get_json(secret_id, "AWSPENDING", token)
    admin = get_json(master_arn(), "AWSCURRENT")
    env = environment_of(secret_id)
    connect(admin, "postgres").run(
        f"ALTER USER {pg8000.native.identifier(pending['username'])} PASSWORD {pg8000.native.literal(pending['password'])}"
    )
    for service in SERVICES:
        copy_password(f"shopsphere/{env}/{service}", pending["password"])


def test_secret(secret_id, token):
    pending = get_json(secret_id, "AWSPENDING", token)
    admin = get_json(master_arn(), "AWSCURRENT")
    pending = dict(pending)
    pending["host"] = admin["host"]
    connect(pending, pending.get("dbname", "postgres")).run("SELECT 1")


def finish_secret(secret_id, token):
    metadata = sm.describe_secret(SecretId=secret_id)
    current_version = None
    for version, stages in metadata["VersionIdsToStages"].items():
        if "AWSCURRENT" in stages:
            if version == token:
                return
            current_version = version
            break
    sm.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage="AWSCURRENT",
        MoveToVersionId=token,
        RemoveFromVersionId=current_version,
    )


def copy_password(secret_name, password):
    try:
        current = get_json(secret_name, "AWSCURRENT")
    except sm.exceptions.ResourceNotFoundException:
        return
    current["password"] = password
    sm.put_secret_value(SecretId=secret_name, SecretString=json.dumps(current))


def connect(values, database):
    return pg8000.native.Connection(
        user=values["username"],
        password=values["password"],
        host=values["host"],
        port=int(values.get("port", 5432)),
        database=database,
        ssl_context=ssl.create_default_context(),
    )


def get_json(secret_id, stage, version_id=None):
    args = {"SecretId": secret_id, "VersionStage": stage}
    if version_id:
        args["VersionId"] = version_id
    return json.loads(sm.get_secret_value(**args)["SecretString"])


def environment_of(secret_id):
    name = secret_id.split(":")[-1].rsplit("-", 1)[0]
    return name.split("/")[-2]


def master_arn():
    import os
    return os.environ["MASTER_SECRET_ARN"]


def new_password():
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(32))
