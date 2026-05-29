#!/usr/bin/env bash
# Merge OpenBao KV (per service) + static env → Coolify compose service env (bulk PATCH).
#
# Usage:
#   coolify-sync-env-from-openbao.sh [--lane production] [--check] [--config path]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/coolify-api.sh
source "${SCRIPT_DIR}/lib/coolify-api.sh"

LANE="production"
CHECK_ONLY=false
CONFIG="${ROOT}/config/coolify-production.json"

usage() {
  sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --lane)
    shift
    LANE="${1:?}"
    ;;
  --check)
    CHECK_ONLY=true
    ;;
  --config)
    shift
    CONFIG="${1:?}"
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
  esac
  shift
done

if [[ ! -f "${CONFIG}" ]]; then
  echo "Missing config: ${CONFIG}" >&2
  exit 1
fi

OPENBAO_MOUNT="${OPENBAO_MOUNT:-secret}"
BAO_ADDR="${BAO_ADDR:-${OPENBAO_ADDR:-${VAULT_ADDR:-https://secrets.bdziam.dev}}}"
OPENBAO_TOKEN="${OPENBAO_TOKEN:-${BAO_TOKEN:-${VAULT_TOKEN:-}}}"

normalize_addr() {
  local addr="$1"
  if [[ "${addr}" != http://* && "${addr}" != https://* ]]; then
    addr="https://${addr}"
  fi
  printf '%s' "${addr%/}"
}

BAO_ADDR="$(normalize_addr "${BAO_ADDR}")"
export BAO_ADDR VAULT_ADDR="${BAO_ADDR}"

service_uuid="$(jq -r '.service_uuid // empty' "${CONFIG}")"
service_name="$(jq -r '.service_name' "${CONFIG}")"
openbao_lane="$(jq -r '.openbao_lane // .lane' "${CONFIG}")"
openbao_services=()
while IFS= read -r _svc; do
  [[ -n "${_svc}" ]] && openbao_services+=("${_svc}")
done < <(jq -r '.openbao_services[]' "${CONFIG}")

merged_env="$(mktemp)"
trap 'rm -f "${merged_env}"' EXIT

jq '.static_env // {}' "${CONFIG}" >"${merged_env}"

if [[ -n "${OPENBAO_TOKEN}" ]]; then
  export BAO_TOKEN="${OPENBAO_TOKEN}"
  for svc in "${openbao_services[@]}"; do
    path="${OPENBAO_MOUNT}/beskid/${openbao_lane}/${svc}"
    if ! bao kv get -format=json "${path}" >/dev/null 2>&1; then
      if [[ "${CHECK_ONLY}" == "true" ]]; then
        echo "MISSING: ${path}" >&2
        exit 1
      fi
      echo "Skip missing OpenBao path: ${path}" >&2
      continue
    fi
    chunk="$(bao kv get -format=json "${path}" | jq '.data.data // .data')"
    jq -s '.[0] * .[1]' "${merged_env}" <(echo "${chunk}") >"${merged_env}.next"
    mv "${merged_env}.next" "${merged_env}"
  done
elif [[ "${CHECK_ONLY}" == "true" ]]; then
  echo "OPENBAO_TOKEN not set — skipping KV read (static env only)." >&2
else
  echo "OPENBAO_TOKEN not set — syncing static env only." >&2
fi

compose_profiles="$(jq -r '.compose_profiles // ""' "${CONFIG}")"
if [[ -n "${compose_profiles}" ]]; then
  jq --arg p "${compose_profiles}" '. + {COMPOSE_PROFILES: $p}' "${merged_env}" >"${merged_env}.next"
  mv "${merged_env}.next" "${merged_env}"
fi

if [[ "${CHECK_ONLY}" == "true" ]]; then
  echo "OpenBao + static env check OK for lane ${LANE} (${#openbao_services[@]} services)."
  jq 'keys | sort' "${merged_env}"
  exit 0
fi

if [[ -z "${service_uuid}" ]]; then
  service_uuid="$(coolify_uuid_by_name "/api/v1/services" "${service_name}")"
fi
if [[ -z "${service_uuid}" || "${service_uuid}" == "null" ]]; then
  echo "Coolify service '${service_name}' not found — run coolify-deploy-compose.sh first." >&2
  exit 1
fi

echo "PATCH env bulk → service ${service_uuid} ($(jq 'length' "${merged_env}") keys)"
coolify_envs_bulk_patch service "${service_uuid}" "${merged_env}"
echo "Synced environment variables to Coolify service ${service_name}."
