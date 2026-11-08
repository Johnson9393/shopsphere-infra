#!/usr/bin/env bash
# Open a local port to the non-prod Aurora writer so DBeaver can connect.
#
#   export AWS_PROFILE=nonprod-admin
#   export AWS_REGION=us-east-1
#   ./scripts/db-tunnel.sh dev
#
# Then in DBeaver: host localhost, port 15432, database dev_products
# (also dev_users, dev_orders, dev_payments). Username and password are printed
# once from Secrets Manager. qa and uat use their own database names.

set -euo pipefail

ENV_NAME="${1:-}"
LOCAL_PORT="${LOCAL_PORT:-15432}"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [[ -z "${ENV_NAME}" ]]; then
  echo "Usage: AWS_PROFILE=nonprod-admin $0 <dev|qa|uat>" >&2
  exit 1
fi

case "${ENV_NAME}" in
  dev | qa | uat) ;;
  *)
    echo "Environment must be dev, qa, or uat." >&2
    exit 1
    ;;
esac

if [[ -z "${AWS_PROFILE:-}" ]]; then
  echo "Export AWS_PROFILE for the non-prod account first." >&2
  exit 1
fi

connection=$(aws secretsmanager get-secret-value \
  --region "${AWS_REGION}" \
  --secret-id "shopsphere/nonprod/aurora-connection" \
  --query SecretString --output text)

host=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["host"])' <<<"${connection}")
username=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["username"])' <<<"${connection}")

rds_secret=$(aws secretsmanager list-secrets \
  --region "${AWS_REGION}" \
  --query "SecretList[?starts_with(Name, 'rds!cluster-')].Name | [0]" \
  --output text)

password=$(aws secretsmanager get-secret-value \
  --region "${AWS_REGION}" \
  --secret-id "${rds_secret}" \
  --query SecretString --output text | python3 -c 'import json,sys; print(json.load(sys.stdin)["password"])')

aws eks update-kubeconfig \
  --name "${ENV_NAME}-shopsphere" \
  --region "${AWS_REGION}" >/dev/null

namespace="${ENV_NAME}-shopsphere-db-tunnel"
kubectl create namespace "${namespace}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "${namespace}" delete pod db-tunnel --ignore-not-found --wait=false >/dev/null
kubectl -n "${namespace}" run db-tunnel \
  --image=alpine/socat \
  --restart=Never \
  --command -- socat "TCP-LISTEN:5432,fork,reuseaddr" "TCP:${host}:5432"
kubectl -n "${namespace}" wait --for=condition=Ready pod/db-tunnel --timeout=120s

echo
echo "DBeaver connection"
echo "  Host: localhost"
echo "  Port: ${LOCAL_PORT}"
echo "  Database: ${ENV_NAME}_products | ${ENV_NAME}_users | ${ENV_NAME}_orders | ${ENV_NAME}_payments"
echo "  Username: ${username}"
echo "  Password: ${password}"
echo
echo "Tunnel is running. Leave this terminal open. Ctrl-C closes it."

cleanup() {
  kubectl -n "${namespace}" delete pod db-tunnel --ignore-not-found --wait=false >/dev/null || true
}
trap cleanup EXIT

kubectl -n "${namespace}" port-forward pod/db-tunnel "${LOCAL_PORT}:5432"
