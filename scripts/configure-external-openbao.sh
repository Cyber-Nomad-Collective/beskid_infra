#!/usr/bin/env bash
set -euo pipefail

: "${OPENBAO_TOKEN:?Set OPENBAO_TOKEN for external OpenBao}"
OPENBAO_ADDR="${OPENBAO_ADDR:-https://secrets.bdziam.dev}"
OPENBAO_MOUNT="${OPENBAO_MOUNT:-secret}"
OPENBAO_LANE="${OPENBAO_LANE:-production}"
IMAGE_TAG_DEFAULT="${IMAGE_TAG_DEFAULT:-}"
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
  bao kv get -format=json "${OPENBAO_MOUNT}/${path}" 2>/dev/null | jq -r --arg k "${key}" '.data.data[$k] // empty'
}

random_alnum() {
  python3 - <<'PY'
import secrets
import string
alphabet = string.ascii_letters + string.digits
print(''.join(secrets.choice(alphabet) for _ in range(48)))
PY
}

lane_image_tag() {
  if [[ -n "${IMAGE_TAG_DEFAULT}" ]]; then
    printf '%s' "${IMAGE_TAG_DEFAULT}"
    return
  fi
  case "${OPENBAO_LANE}" in
    production) printf 'main' ;;
    staging) printf 'staging' ;;
    *) printf 'latest' ;;
  esac
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
pckg_postgres_secret="$(ensure_value "beskid/${OPENBAO_LANE}/pckg" "POSTGRES_PASSWORD" "${PCKG_POSTGRES_PASSWORD}")"
site_image_tag="$(ensure_value "beskid/${OPENBAO_LANE}/site" "IMAGE_TAG" "$(lane_image_tag)")"

bao kv put "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/site" \
  IMAGE_TAG="${site_image_tag}"

bao kv put "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/auth" \
  SESSION_SECRET="${auth_session_secret}" \
  AUTH_HUB_SECRET="${auth_hub_secret}"

bao kv put "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/tracker" \
  SESSION_SECRET="${tracker_session_secret}"

bao kv put "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/nexus" \
  SESSION_SECRET="${nexus_session_secret}"

bao kv put "${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/pckg" \
  POSTGRES_PASSWORD="${pckg_postgres_secret}"

echo "Configured OpenBao KV paths under ${OPENBAO_MOUNT}/beskid/${OPENBAO_LANE}/"
