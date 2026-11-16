#!/usr/bin/env bash
# Open AKHQ for one environment. The UI is not on the public internet.
#
#   export AWS_PROFILE=nonprod-admin
#   ./scripts/akhq.sh dev
#
# Then open http://127.0.0.1:8080

set -euo pipefail

ENV_NAME="${1:-}"
LOCAL_PORT="${LOCAL_PORT:-8080}"
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

aws eks update-kubeconfig --name "${ENV_NAME}-shopsphere" --region "${AWS_REGION}" >/dev/null

echo "AKHQ for ${ENV_NAME}: http://127.0.0.1:${LOCAL_PORT}"
echo "Topics, consumer groups, and events are under the shopsphere connection."
echo "Leave this terminal open. Ctrl-C closes the port forward."

kubectl -n "shopsphere-${ENV_NAME}" port-forward "svc/akhq" "${LOCAL_PORT}:80"
