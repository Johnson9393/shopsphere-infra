#!/usr/bin/env bash
# Open a local port to one environment's Aurora writer so DBeaver can connect.
#
#   export AWS_PROFILE=nonprod-admin
#   ./scripts/db-tunnel.sh dev
#
#   export AWS_PROFILE=prod-admin
#   ./scripts/db-tunnel.sh prod
#
# The script reads shopsphere/<env>/aurora. That secret holds the proxy host,
# the environment username, and that environment's password.
# DBeaver uses localhost, the printed port, and one database name.

set -euo pipefail

ENV_NAME="${1:-}"
LOCAL_PORT="${LOCAL_PORT:-15432}"
AWS_REGION="${AWS_REGION:-us-east-1}"

if [[ -z "${ENV_NAME}" ]]; then
  echo "Usage: AWS_PROFILE=<profile> $0 <dev|qa|uat|preprod|prod>" >&2
  exit 1
fi

case "${ENV_NAME}" in
  dev | qa | uat | preprod | prod) ;;
  *)
    echo "Environment must be dev, qa, uat, preprod, or prod." >&2
    exit 1
    ;;
esac

if [[ -z "${AWS_PROFILE:-}" ]]; then
  echo "Export AWS_PROFILE for the account that owns ${ENV_NAME} first." >&2
  exit 1
fi

secret_id="shopsphere/${ENV_NAME}/aurora"
cluster="${ENV_NAME}-shopsphere"

connection=$(aws secretsmanager get-secret-value \
  --region "${AWS_REGION}" \
  --secret-id "${secret_id}" \
  --query SecretString --output text)

host=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["host"])' <<<"${connection}")
username=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["username"])' <<<"${connection}")
password=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["password"])' <<<"${connection}")

aws eks update-kubeconfig \
  --name "${cluster}" \
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
echo "DBeaver connection for ${ENV_NAME}"
echo "  Host: localhost"
echo "  Port: ${LOCAL_PORT}"
echo "  Username: ${username}"
echo "  Password: ${password}"
echo "  Database: ${ENV_NAME}_products"
echo "            ${ENV_NAME}_users"
echo "            ${ENV_NAME}_orders"
echo "            ${ENV_NAME}_payments"
echo
echo "The host above is the RDS Proxy in the cluster. This terminal forwards it to localhost."
echo "Leave this terminal open. Ctrl-C closes the tunnel."

cleanup() {
  kubectl -n "${namespace}" delete pod db-tunnel --ignore-not-found --wait=false >/dev/null || true
}
trap cleanup EXIT

kubectl -n "${namespace}" port-forward pod/db-tunnel "${LOCAL_PORT}:5432"
