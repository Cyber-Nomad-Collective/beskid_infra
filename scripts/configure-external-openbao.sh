#!/usr/bin/env bash
set -euo pipefail

: "${OPENBAO_TOKEN:?Set OPENBAO_TOKEN for external OpenBao}"
_openbao_addr_raw="${OPENBAO_ADDR:-${VAULT_ADDR:-https://secrets.bdziam.dev}}"
if [[ "${_openbao_addr_raw}" != http://* && "${_openbao_addr_raw}" != https://* ]]; then
  _openbao_addr_raw="https://${_openbao_addr_raw}"
fi
OPENBAO_ADDR="${_openbao_addr_raw%/}"
unset _openbao_addr_raw
OPENBAO_MOUNT="${OPENBAO_MOUNT:-secret}"
OPENBAO_LANE="${OPENBAO_LANE:-production}"
PCKG_POSTGRES_PASSWORD="${PCKG_POSTGRES_PASSWORD:-}"
PCKG_POSTGRES_USER="${PCKG_POSTGRES_USER:-}"
PCKG_POSTGRES_DB="${PCKG_POSTGRES_DB:-}"
PCKG_DB_HOST="${PCKG_DB_HOST:-}"
PCKG_DB_PORT="${PCKG_DB_PORT:-}"

export BAO_ADDR="${OPENBAO_ADDR}"
export BAO_TOKEN="${OPENBAO_TOKEN}"

if ! command -v bao >/dev/null 2>&1; then
  echo "bao CLI not found in PATH" >&2
  exit 1
fi

if ! bao status >/dev/null 2>&1; then
  echo "Cannot reach OpenBao at ${OPENBAO_ADDR} with provided token." >&2
  exit 1
fi

if ! bao secrets list -format=json | jq -e --arg m "${OPENBAO_MOUNT}/" 'has($m)' >/dev/null 2>&1; then
  bao secrets enable -path="${OPENBAO_MOUNT}" -version=2 kv
fi

read_secret_value() {
  local path="$1"
  local key="$2"
  local raw
  raw="$(bao kv get -format=json "${OPENBAO_MOUNT}/${path}" 2>/dev/null)" || return 0
  jq -r --arg k "${key}" '.data.data[$k] // empty' <<<"${raw}"
}

random_alnum() {
  python3 - <<'PY'
import secrets
import string
alphabet = string.ascii_letters + string.digits
print(''.join(secrets.choice(alphabet) for _ in range(48)))
PY
}

ensure_value() {
  local path="$1"
  local key="$2"
  local provided="${3:-}"
  local value=""
  if [[ -n "${provided}" ]]; then
    value="${provided}"
  else
    value="$(read_secret_value "${path}" "${key}")"
    if [[ -z "${value}" ]]; then
      value="$(random_alnum)"
    fi
  fi
  printf '%s' "${value}"
}

read_or_default() {
  local path="$1"
  local key="$2"
  local default_value="$3"
  local provided="${4:-}"
  local value="${provided:-$(read_secret_value "${path}" "${key}")}"
  printf '%s' "${value:-${default_value}}"
}

uri_encode() {
  jq -rn --arg value "$1" '$value | @uri'
}

auth_session_secret="$(ensure_value "beskid/${OPENBAO_LANE}/auth" "SESSION_SECRET")"
auth_hub_secret="$(ensure_value "beskid/${OPENBAO_LANE}/auth" "AUTH_HUB_SECRET")"
tracker_session_secret="$(ensure_value "beskid/${OPENBAO_LANE}/tracker" "SESSION_SECRET")"
nexus_session_secret="$(ensure_value "beskid/${OPENBAO_LANE}/nexus" "SESSION_SECRET")"
pckg_path="beskid/${OPENBAO_LANE}/pckg"
pckg_postgres_secret="$(ensure_value "${pckg_path}" "POSTGRES_PASSWORD" "${PCKG_POSTGRES_PASSWORD}")"
pckg_postgres_user="$(read_or_default "${pckg_path}" "POSTGRES_USER" "postgres" "${PCKG_POSTGRES_USER}")"
pckg_postgres_db="$(read_or_default "${pckg_path}" "POSTGRES_DB" "pckgdb" "${PCKG_POSTGRES_DB}")"
pckg_db_host="$(read_or_default "${pckg_path}" "PCKG_DB_HOST" "postgres" "${PCKG_DB_HOST}")"
pckg_db_port="$(read_or_default "${pckg_path}" "PCKG_DB_PORT" "5432" "${PCKG_DB_PORT}")"
if [[ -z "${pckg_postgres_user}" || -z "${pckg_postgres_db}" || ! "${pckg_db_host}" =~ ^[A-Za-z0-9.-]+$ || ! "${pckg_db_port}" =~ ^[1-9][0-9]*$ || "${pckg_db_port}" -gt 65535 ]]; then
  echo "pckg PostgreSQL user, database, host, or port is invalid" >&2
  exit 1
fi
pckg_database_url="postgres://$(uri_encode "${pckg_postgres_user}"):$(uri_encode "${pckg_postgres_secret}")@${pckg_db_host}:${pckg_db_port}/$(uri_encode "${pckg_postgres_db}")"

auth_hub_public_url="$(read_secret_value "beskid/${OPENBAO_LANE}/tracker" "AUTH_HUB_PUBLIC_URL")"
if [[ -z "${auth_hub_public_url}" ]]; then
  case "${OPENBAO_LANE}" in
    production) auth_hub_public_url="https://auth.beskid-lang.org" ;;
    staging) auth_hub_public_url="https://stg-auth.beskid-lang.org" ;;
    *) auth_hub_public_url="https://auth.beskid-lang.org" ;;
  esac
fi

pairing_approver="$(read_secret_value "beskid/${OPENBAO_LANE}/tracker" "TRACKER_PAIRING_APPROVER_LOGIN")"

lane_public_url() {
  local key="$1"
  case "${OPENBAO_LANE}:${key}" in
    production:AUTH_HUB_PUBLIC_URL) printf 'https://auth.beskid-lang.org' ;;
    production:TRACKER_PUBLIC_URL) printf 'https://tracker.beskid-lang.org' ;;
    staging:AUTH_HUB_PUBLIC_URL) printf 'https://stg-auth.beskid-lang.org' ;;
    staging:TRACKER_PUBLIC_URL) printf 'https://stg-tracker.beskid-lang.org' ;;
    *) return 1 ;;
  esac
}

tracker_public_url="$(read_secret_value "beskid/${OPENBAO_LANE}/tracker" "TRACKER_PUBLIC_URL")"
if [[ -z "${tracker_public_url}" ]]; then
  tracker_public_url="$(lane_public_url TRACKER_PUBLIC_URL || true)"
fi
tracker_sync_token="$(read_secret_value "beskid/${OPENBAO_LANE}/tracker" "GITHUB_SYNC_TOKEN")"
if [[ -z "${tracker_sync_token}" && -n "${GITHUB_SYNC_TOKEN:-}" ]]; then
  tracker_sync_token="${GITHUB_SYNC_TOKEN}"
fi
bao kv patch "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/nexus" \
  SESSION_SECRET="${nexus_session_secret}" \
  AUTH_HUB_PUBLIC_URL="${auth_hub_public_url}" \
  GITNEXUS_HOME="/data/gitnexus"

if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
  bao kv patch "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/nexus" \
    OPENROUTER_API_KEY="${OPENROUTER_API_KEY}"
  echo "Patched OPENROUTER_API_KEY on ${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/nexus"
fi

bao kv patch "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/auth" \
  SESSION_SECRET="${auth_session_secret}" \
  AUTH_HUB_SECRET="${auth_hub_secret}"

tracker_args=(
  "SESSION_SECRET=${tracker_session_secret}"
  "AUTH_HUB_PUBLIC_URL=${auth_hub_public_url}"
)
[[ -n "${tracker_public_url}" ]] && tracker_args+=("TRACKER_PUBLIC_URL=${tracker_public_url}")
[[ -n "${pairing_approver}" ]] && tracker_args+=("TRACKER_PAIRING_APPROVER_LOGIN=${pairing_approver}")
[[ -n "${tracker_sync_token}" ]] && tracker_args+=("GITHUB_SYNC_TOKEN=${tracker_sync_token}")

bao kv patch "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/tracker" \
  "${tracker_args[@]}"

pckg_args=(
  "POSTGRES_PASSWORD=${pckg_postgres_secret}"
  "POSTGRES_USER=${pckg_postgres_user}"
  "POSTGRES_DB=${pckg_postgres_db}"
  "PCKG_DB_HOST=${pckg_db_host}"
  "PCKG_DB_PORT=${pckg_db_port}"
  "PCKG_DATABASE_URL=${pckg_database_url}"
)

bao kv patch "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/pckg" \
  "${pckg_args[@]}"

echo "Configured OpenBao KV paths under ${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/"
