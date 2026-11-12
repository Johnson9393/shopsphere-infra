"""Rotate the Redis, queue, and JWT secrets for one environment."""

import json
import secrets
import string
import urllib.request

import boto3

sm = boto3.client("secretsmanager")
elasticache = boto3.client("elasticache")


def handler(event, context):
    step = event["Step"]
    secret_id = event["SecretId"]
    token = event["ClientRequestToken"]
    metadata = sm.describe_secret(SecretId=secret_id)
    versions = metadata["VersionIdsToStages"]
    if token not in versions or "AWSCURRENT" in versions[token]:
        return
    if "AWSPENDING" not in versions[token]:
        raise ValueError("Secret version is not pending")

    if step == "createSecret":
        create_secret(secret_id, token)
    elif step == "setSecret":
        set_secret(secret_id, token)
    elif step == "testSecret":
        return
    elif step == "finishSecret":
        finish_secret(secret_id, token)
    else:
        raise ValueError("Unknown rotation step")


def create_secret(secret_id, token):
    current = json.loads(sm.get_secret_value(SecretId=secret_id, VersionStage="AWSCURRENT")["SecretString"])
    try:
        sm.get_secret_value(SecretId=secret_id, VersionId=token, VersionStage="AWSPENDING")
        return
    except sm.exceptions.ResourceNotFoundException:
        pass
    pending = dict(current)
    if "password" in pending:
        pending["password"] = new_password()
    if "jwt" in pending:
        pending["jwt"] = new_password()
    sm.put_secret_value(
        SecretId=secret_id,
        ClientRequestToken=token,
        SecretString=json.dumps(pending),
        VersionStages=["AWSPENDING"],
    )


def set_secret(secret_id, token):
    pending = json.loads(sm.get_secret_value(SecretId=secret_id, VersionId=token, VersionStage="AWSPENDING")["SecretString"])
    current = json.loads(sm.get_secret_value(SecretId=secret_id, VersionStage="AWSCURRENT")["SecretString"])
    name = secret_id.split(":")[-1]
    env = name.rsplit("-", 1)[0].split("/")[-2]
    if "elasticache" in name:
        elasticache.modify_replication_group(
            ReplicationGroupId=pending["replication_group_id"],
            AuthToken=pending["password"],
            AuthTokenUpdateStrategy="ROTATE",
        )
        copy_password(f"shopsphere/{env}/cart-service", pending["password"])
    elif "amazonmq" in name:
        change_queue_password(pending["host"], current["username"], current["password"], pending["password"])
        copy_password(f"shopsphere/{env}/notification-service", pending["password"])


def change_queue_password(host, username, current_password, new_password):
    request = urllib.request.Request(
        f"https://{host}/api/users/{username}",
        data=json.dumps({"password": new_password, "tags": "administrator"}).encode(),
        method="PUT",
        headers={"Content-Type": "application/json"},
    )
    password_mgr = urllib.request.HTTPPasswordMgrWithDefaultRealm()
    password_mgr.add_password(None, f"https://{host}", username, current_password)
    opener = urllib.request.build_opener(urllib.request.HTTPBasicAuthHandler(password_mgr))
    opener.open(request, timeout=20).read()


def copy_password(secret_name, password):
    try:
        current = json.loads(sm.get_secret_value(SecretId=secret_name, VersionStage="AWSCURRENT")["SecretString"])
    except sm.exceptions.ResourceNotFoundException:
        return
    current["password"] = password
    sm.put_secret_value(SecretId=secret_name, SecretString=json.dumps(current))


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


def new_password():
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(32))
