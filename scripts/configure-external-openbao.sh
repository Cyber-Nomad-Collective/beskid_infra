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

auth_session_secret="$(ensure_value "beskid/${OPENBAO_LANE}/auth" "SESSION_SECRET")"
auth_hub_secret="$(ensure_value "beskid/${OPENBAO_LANE}/auth" "AUTH_HUB_SECRET")"
tracker_session_secret="$(ensure_value "beskid/${OPENBAO_LANE}/tracker" "SESSION_SECRET")"
nexus_session_secret="$(ensure_value "beskid/${OPENBAO_LANE}/nexus" "SESSION_SECRET")"
platform_spec_session_secret="$(ensure_value "beskid/${OPENBAO_LANE}/platform-spec" "SESSION_SECRET")"
pckg_postgres_secret="$(ensure_value "beskid/${OPENBAO_LANE}/pckg" "POSTGRES_PASSWORD" "${PCKG_POSTGRES_PASSWORD}")"

auth_hub_public_url="$(read_secret_value "beskid/${OPENBAO_LANE}/tracker" "AUTH_HUB_PUBLIC_URL")"
if [[ -z "${auth_hub_public_url}" ]]; then
  case "${OPENBAO_LANE}" in
    production) auth_hub_public_url="https://auth.beskid-lang.org" ;;
    staging) auth_hub_public_url="https://stg-auth.beskid-lang.org" ;;
    *) auth_hub_public_url="https://auth.beskid-lang.org" ;;
  esac
fi

platform_spec_public_url="$(read_secret_value "beskid/${OPENBAO_LANE}/platform-spec" "PLATFORM_SPEC_PUBLIC_URL")"
if [[ -z "${platform_spec_public_url}" ]]; then
  case "${OPENBAO_LANE}" in
    production) platform_spec_public_url="https://spec.beskid-lang.org" ;;
    staging) platform_spec_public_url="https://stg-spec.beskid-lang.org" ;;
    *) platform_spec_public_url="https://spec.beskid-lang.org" ;;
  esac
fi

pairing_approver="$(read_secret_value "beskid/${OPENBAO_LANE}/tracker" "TRACKER_PAIRING_APPROVER_LOGIN")"
if [[ -z "${pairing_approver}" && -n "${PLATFORM_SPEC_PAIRING_APPROVER_LOGIN:-}" ]]; then
  pairing_approver="${PLATFORM_SPEC_PAIRING_APPROVER_LOGIN}"
fi

moderator_logins="$(read_secret_value "beskid/${OPENBAO_LANE}/platform-spec" "PLATFORM_SPEC_MODERATOR_LOGINS")"
if [[ -z "${moderator_logins}" && -n "${pairing_approver}" ]]; then
  moderator_logins="${pairing_approver}"
elif [[ -z "${moderator_logins}" && -n "${PLATFORM_SPEC_MODERATOR_LOGINS:-}" ]]; then
  moderator_logins="${PLATFORM_SPEC_MODERATOR_LOGINS}"
fi

github_sync_token="$(read_secret_value "beskid/${OPENBAO_LANE}/platform-spec" "GITHUB_SYNC_TOKEN")"
if [[ -z "${github_sync_token}" && -n "${GITHUB_SYNC_TOKEN:-}" ]]; then
  github_sync_token="${GITHUB_SYNC_TOKEN}"
fi

github_webhook_secret="$(ensure_value "beskid/${OPENBAO_LANE}/platform-spec" "GITHUB_WEBHOOK_SECRET")"

lane_public_url() {
  local key="$1"
  case "${OPENBAO_LANE}:${key}" in
    production:AUTH_HUB_PUBLIC_URL) printf 'https://auth.beskid-lang.org' ;;
    production:TRACKER_PUBLIC_URL) printf 'https://tracker.beskid-lang.org' ;;
    production:PCKG_PUBLIC_URL) printf 'https://pckg.beskid-lang.org' ;;
    staging:AUTH_HUB_PUBLIC_URL) printf 'https://stg-auth.beskid-lang.org' ;;
    staging:TRACKER_PUBLIC_URL) printf 'https://stg-tracker.beskid-lang.org' ;;
    staging:PCKG_PUBLIC_URL) printf 'https://stg-pckg.beskid-lang.org' ;;
    *) return 1 ;;
  esac
}

tracker_public_url="$(read_secret_value "beskid/${OPENBAO_LANE}/tracker" "TRACKER_PUBLIC_URL")"
if [[ -z "${tracker_public_url}" ]]; then
  tracker_public_url="$(lane_public_url TRACKER_PUBLIC_URL || true)"
fi
pckg_public_url="$(read_secret_value "beskid/${OPENBAO_LANE}/pckg" "PCKG_PUBLIC_URL")"
if [[ -z "${pckg_public_url}" ]]; then
  pckg_public_url="$(lane_public_url PCKG_PUBLIC_URL || true)"
fi

tracker_sync_token="$(read_secret_value "beskid/${OPENBAO_LANE}/tracker" "GITHUB_SYNC_TOKEN")"
if [[ -z "${tracker_sync_token}" && -n "${GITHUB_SYNC_TOKEN:-}" ]]; then
  tracker_sync_token="${GITHUB_SYNC_TOKEN}"
fi
if [[ -z "${github_sync_token}" && -n "${tracker_sync_token}" ]]; then
  github_sync_token="${tracker_sync_token}"
fi

kv_has_path() {
  bao kv get -format=json "${OPENBAO_MOUNT}/$1" >/dev/null 2>&1
}

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

platform_spec_args=(
  "SESSION_SECRET=${platform_spec_session_secret}"
  "AUTH_HUB_PUBLIC_URL=${auth_hub_public_url}"
  "PLATFORM_SPEC_PUBLIC_URL=${platform_spec_public_url}"
  "MEMGRAPH_URI=bolt://memgraph:7687"
  "GITHUB_REPO_OWNER=Cyber-Nomad-Collective"
  "GITHUB_REPO_NAME=beskid_normative_spec"
  "GITHUB_OAUTH_REPO_OWNER=Cyber-Nomad-Collective"
  "GITHUB_OAUTH_REPO_NAME=beskid"
  "GITHUB_WEBHOOK_SECRET=${github_webhook_secret}"
  "SPEC_GIT_REPO_URL=https://github.com/Cyber-Nomad-Collective/beskid_normative_spec.git"
  "SPEC_GIT_REF=main"
  "SPEC_SYNC_MODE=json"
)
[[ -n "${pairing_approver}" ]] && platform_spec_args+=("PLATFORM_SPEC_PAIRING_APPROVER_LOGIN=${pairing_approver}")
[[ -n "${moderator_logins}" ]] && platform_spec_args+=("PLATFORM_SPEC_MODERATOR_LOGINS=${moderator_logins}")
[[ -n "${github_sync_token}" ]] && platform_spec_args+=("GITHUB_SYNC_TOKEN=${github_sync_token}")

bao kv patch "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/platform-spec" \
  "${platform_spec_args[@]}"

pckg_args=("POSTGRES_PASSWORD=${pckg_postgres_secret}")
[[ -n "${pckg_public_url}" ]] && pckg_args+=("PCKG_PUBLIC_URL=${pckg_public_url}")
[[ -n "${auth_hub_public_url}" ]] && pckg_args+=("AUTH_HUB_PUBLIC_URL=${auth_hub_public_url}")
[[ -n "${pairing_approver}" ]] && pckg_args+=("PCKG_PAIRING_APPROVER_LOGIN=${pairing_approver}")
[[ -n "${tracker_sync_token}" ]] && pckg_args+=("GITHUB_SYNC_TOKEN=${tracker_sync_token}")

bao kv patch "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/pckg" \
  "${pckg_args[@]}"

echo "Configured OpenBao KV paths under ${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/"
