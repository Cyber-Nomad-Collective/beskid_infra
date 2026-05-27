#!/usr/bin/env bash
# Initialize and unseal OpenBao (1-of-1 Shamir) when deploying via Coolify.
# Idempotent: safe to re-run from CI after the openbao service is healthy.
#
# Usage:
#   OPENBAO_ADDR=https://bao.beskid-lang.org ./scripts/openbao-init-unseal.sh
#
# Outputs (stdout): export lines for OPENBAO_UNSEAL_KEY and OPENBAO_ROOT_TOKEN when newly initialized.
set -euo pipefail

: "${OPENBAO_ADDR:?Set OPENBAO_ADDR (https:// host, no trailing slash)}"

OPENBAO_ADDR="${OPENBAO_ADDR%/}"

health() {
  curl -fsS "${OPENBAO_ADDR}/v1/sys/health" 2>/dev/null || echo '{}'
}

wait_healthy() {
  local i
  for i in $(seq 1 60); do
    if curl -fsS "${OPENBAO_ADDR}/v1/sys/health?standbyok=true" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done
  echo "OpenBao not reachable at ${OPENBAO_ADDR}" >&2
  return 1
}

wait_healthy

initialized="$(health | jq -r '.initialized // false')"
sealed="$(health | jq -r '.sealed // true')"

if [[ "${initialized}" != "true" ]]; then
  echo "Initializing OpenBao (1 share, threshold 1)…" >&2
  init_json="$(curl -fsS -X POST "${OPENBAO_ADDR}/v1/sys/init" \
    -d '{"secret_shares":1,"secret_threshold":1}')"
  unseal_key="$(echo "${init_json}" | jq -r '.keys_b64[0]')"
  root_token="$(echo "${init_json}" | jq -r '.root_token')"
  curl -fsS -X POST "${OPENBAO_ADDR}/v1/sys/unseal" \
    -d "$(jq -n --arg k "${unseal_key}" '{key: $k}')"
  echo "export OPENBAO_UNSEAL_KEY='${unseal_key}'"
  echo "export OPENBAO_ROOT_TOKEN='${root_token}'"
  echo "OpenBao initialized. Store OPENBAO_ROOT_TOKEN as GitHub secret OPENBAO_TOKEN." >&2
  exit 0
fi

if [[ "${sealed}" == "true" ]]; then
  : "${OPENBAO_UNSEAL_KEY:?Set OPENBAO_UNSEAL_KEY to unseal an existing instance}"
  curl -fsS -X POST "${OPENBAO_ADDR}/v1/sys/unseal" \
    -d "$(jq -n --arg k "${OPENBAO_UNSEAL_KEY}" '{key: $k}')"
  echo "OpenBao unsealed." >&2
else
  echo "OpenBao already initialized and unsealed." >&2
fi
