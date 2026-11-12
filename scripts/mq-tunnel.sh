#!/usr/bin/env bash
# Open the Amazon MQ RabbitMQ console for one environment.
#
#   export AWS_PROFILE=nonprod-admin
#   ./scripts/mq-tunnel.sh dev
#
#   export AWS_PROFILE=prod-admin
#   ./scripts/mq-tunnel.sh prod
#
# Then open https://127.0.0.1:15671 and accept the certificate warning.
# The certificate name is the broker hostname, not localhost.
# Sign in with the username and password printed below.

set -euo pipefail

ENV_NAME="${1:-}"
LOCAL_PORT="${LOCAL_PORT:-15671}"
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

secret_id="shopsphere/${ENV_NAME}/amazonmq"
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

namespace="${ENV_NAME}-shopsphere-mq-tunnel"
kubectl create namespace "${namespace}" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
kubectl -n "${namespace}" delete pod mq-tunnel --ignore-not-found --wait=false >/dev/null
kubectl -n "${namespace}" run mq-tunnel \
  --image=alpine/socat \
  --restart=Never \
  --command -- socat "TCP-LISTEN:443,fork,reuseaddr" "TCP:${host}:443"
kubectl -n "${namespace}" wait --for=condition=Ready pod/mq-tunnel --timeout=120s

echo
echo "RabbitMQ console for ${ENV_NAME}"
echo "  URL: https://127.0.0.1:${LOCAL_PORT}"
echo "  Username: ${username}"
echo "  Password: ${password}"
echo
echo "Queues are on the Queues tab. Leave this terminal open. Ctrl-C closes the tunnel."

cleanup() {
  kubectl -n "${namespace}" delete pod mq-tunnel --ignore-not-found --wait=false >/dev/null || true
}
trap cleanup EXIT

kubectl -n "${namespace}" port-forward pod/mq-tunnel "${LOCAL_PORT}:443"
