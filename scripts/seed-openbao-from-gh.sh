#!/usr/bin/env bash
# Seed OpenBao KV from GitHub Actions variables (gh CLI) + local secret file.
#
# GitHub variables (COOLIFY_*, TF_BACKEND_*) are fetched automatically.
# GitHub secrets (COOLIFY_API_TOKEN, NODE_AUTH_TOKEN, …) must be in
# config/openbao-secrets.env — gh cannot read secret values.
#
# Usage:
#   export OPENBAO_TOKEN='s....'   # or set in config/openbao-secrets.env
#   ./scripts/seed-openbao-from-gh.sh              # lane from git branch
#   ./scripts/seed-openbao-from-gh.sh --lane production
#   ./scripts/seed-openbao-from-gh.sh --check        # audit only
#   ./scripts/seed-openbao-from-gh.sh --all-lanes
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/deploy-lane.sh
source "${SCRIPT_DIR}/lib/deploy-lane.sh"

REPO="${GH_REPO:-Cyber-Nomad-Collective/beskid}"
OPENBAO_MOUNT="${OPENBAO_MOUNT:-secret}"
SECRETS_FILE="${OPENBAO_SECRETS_FILE:-${ROOT}/config/openbao-secrets.env}"
CHECK_ONLY=false
APPLY=false
ALL_LANES=false
LANE=""

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  echo
  echo "Options:"
  echo "  --check       List required keys; exit 1 if any missing"
  echo "  --apply       Write missing keys (default when neither --check nor --apply)"
  echo "  --lane NAME   production | staging (default: git branch)"
  echo "  --all-lanes   Seed production and staging"
  echo "  --help"
}

normalize_addr() {
  local addr="$1"
  addr="${addr#"${addr%%[![:space:]]*}"}"
  addr="${addr%"${addr##*[![:space:]]}"}"
  if [[ -z "${addr}" ]]; then
    return 1
  fi
  if [[ "${addr}" != http://* && "${addr}" != https://* ]]; then
    addr="https://${addr}"
  fi
  printf '%s' "${addr%/}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --check) CHECK_ONLY=true ;;
  --apply) APPLY=true ;;
  --lane)
    shift
    LANE="${1:?--lane requires production or staging}"
    ;;
  --all-lanes) ALL_LANES=true ;;
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

if [[ "${CHECK_ONLY}" == "false" && "${APPLY}" == "false" ]]; then
  APPLY=true
fi

if [[ -f "${SECRETS_FILE}" ]]; then
  # shellcheck disable=SC1090
  set -a && source "${SECRETS_FILE}" && set +a
fi

OPENBAO_ADDR="$(normalize_addr "${OPENBAO_ADDR:-${VAULT_ADDR:-https://secrets.bdziam.dev}}")" || {
  echo "Set OPENBAO_ADDR or VAULT_ADDR (include https://, e.g. https://secrets.bdziam.dev)" >&2
  exit 1
}
export BAO_ADDR="${OPENBAO_ADDR}"
export VAULT_ADDR="${OPENBAO_ADDR}"
export BAO_TOKEN="${OPENBAO_TOKEN:-${VAULT_TOKEN:-}}"
export VAULT_TOKEN="${BAO_TOKEN}"

if [[ -z "${BAO_TOKEN}" ]]; then
  echo "Set OPENBAO_TOKEN or VAULT_TOKEN (or ${SECRETS_FILE})." >&2
  exit 1
fi

if ! command -v bao >/dev/null 2>&1; then
  echo "bao CLI not found. Install via: ../../scripts/install-deps.sh --group infra" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found." >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found." >&2
  exit 1
fi

if ! bao status >/dev/null 2>&1; then
  echo "Cannot reach OpenBao at ${OPENBAO_ADDR}. Use:" >&2
  echo "  export BAO_ADDR='${OPENBAO_ADDR}'" >&2
  echo "  bao login   # paste token when prompted" >&2
  exit 1
fi

gh_var() {
  gh variable get "$1" -R "${REPO}" 2>/dev/null || true
}

gh_secret_hint() {
  local name="$1"
  if gh secret list -R "${REPO}" --json name -q ".[] | select(.name==\"${name}\") | .name" 2>/dev/null | grep -qx "${name}"; then
    echo "yes"
  else
    echo "no"
  fi
}

kv_get() {
  local path="$1"
  local key="$2"
  local raw
  raw="$(bao kv get -format=json "${OPENBAO_MOUNT}/${path}" 2>/dev/null)" || return 0
  jq -r --arg k "${key}" '.data.data[$k] // empty' <<<"${raw}"
}

kv_has_path() {
  bao kv get -format=json "${OPENBAO_MOUNT}/$1" >/dev/null 2>&1
}

missing=0
report_key() {
  local path="$1"
  local key="$2"
  local required="${3:-yes}"
  local val
  val="$(kv_get "${path}" "${key}")"
  if [[ -n "${val}" ]]; then
    printf '  OK   %s/%s\n' "${path}" "${key}"
  else
    if [[ "${required}" == "yes" ]]; then
      printf '  MISS %s/%s (required)\n' "${path}" "${key}"
      missing=$((missing + 1))
    else
      printf '  ---- %s/%s (optional)\n' "${path}" "${key}"
    fi
  fi
}

audit_lane() {
  local lane="$1"
  echo "=== secret/beskid/${lane} (services) ==="
  report_key "beskid/${lane}/site" "IMAGE_TAG"
  report_key "beskid/${lane}/auth" "SESSION_SECRET"
  report_key "beskid/${lane}/auth" "AUTH_HUB_SECRET" "no"
  report_key "beskid/${lane}/auth" "GITHUB_CLIENT_ID" "no"
  report_key "beskid/${lane}/auth" "GITHUB_CLIENT_SECRET" "no"
  report_key "beskid/${lane}/tracker" "SESSION_SECRET" "no"
  report_key "beskid/${lane}/nexus" "SESSION_SECRET" "no"
  report_key "beskid/${lane}/pckg" "POSTGRES_PASSWORD" "no"

  echo "=== secret/beskid/ci/build ==="
  report_key "beskid/ci/build" "NODE_AUTH_TOKEN" "no"
  report_key "beskid/ci/build" "OVSX_TOKEN" "no"
}

seed_lane_services() {
  local lane="$1"
  export OPENBAO_LANE="${lane}"
  export IMAGE_TAG_DEFAULT=""
  case "${lane}" in
  production) export IMAGE_TAG_DEFAULT="main" ;;
  staging) export IMAGE_TAG_DEFAULT="staging" ;;
  esac
  "${SCRIPT_DIR}/configure-external-openbao.sh"
}

seed_ci_build() {
  local path="beskid/ci/build"
  local -a args=()
  [[ -n "${NODE_AUTH_TOKEN:-}" ]] && args+=("NODE_AUTH_TOKEN=${NODE_AUTH_TOKEN}")
  [[ -n "${OVSX_TOKEN:-}" ]] && args+=("OVSX_TOKEN=${OVSX_TOKEN}")

  if [[ ${#args[@]} -eq 0 ]]; then
    echo "Skip ${OPENBAO_MOUNT}/${path} (set NODE_AUTH_TOKEN / OVSX_TOKEN in ${SECRETS_FILE})"
    return 0
  fi

  if kv_has_path "${path}"; then
    bao kv patch "${OPENBAO_MOUNT}/${path}" "${args[@]}"
    echo "Patched ${OPENBAO_MOUNT}/${path}"
  else
    bao kv put "${OPENBAO_MOUNT}/${path}" "${args[@]}"
    echo "Wrote ${OPENBAO_MOUNT}/${path}"
  fi
}

patch_auth_github() {
  local lane="$1"
  local path="beskid/${lane}/auth"
  local -a args=()
  [[ -n "${GITHUB_CLIENT_ID:-}" ]] && args+=("GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}")
  [[ -n "${GITHUB_CLIENT_SECRET:-}" ]] && args+=("GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}")

  if [[ ${#args[@]} -eq 0 ]]; then
    return 0
  fi

  if kv_has_path "${path}"; then
    bao kv patch "${OPENBAO_MOUNT}/${path}" "${args[@]}"
  else
    bao kv put "${OPENBAO_MOUNT}/${path}" "${args[@]}"
  fi
  echo "Updated ${OPENBAO_MOUNT}/${path} (GitHub OAuth keys)"
}

apply_lane() {
  local lane="$1"
  echo "--- Seeding lane: ${lane} ---"
  seed_lane_services "${lane}"
  patch_auth_github "${lane}"
}

lanes=()
if [[ "${ALL_LANES}" == "true" ]]; then
  lanes=(production staging)
elif [[ -n "${LANE}" ]]; then
  lanes=("${LANE}")
else
  lanes=("$(beskid_deploy_lane_production)")
fi

echo "OpenBao: ${OPENBAO_ADDR}  mount: ${OPENBAO_MOUNT}  repo: ${REPO}"
echo "GitHub variables (sample):"
echo "  COOLIFY_ENDPOINT=$(gh_var COOLIFY_ENDPOINT)"
echo "  COOLIFY_SERVER_UUID=$(gh_var COOLIFY_SERVER_UUID)"
echo

if [[ "${CHECK_ONLY}" == "true" ]]; then
  for lane in "${lanes[@]}"; do
    audit_lane "${lane}"
  done
  echo "=== secret/beskid/ci/build ==="
  report_key "beskid/ci/build" "NODE_AUTH_TOKEN" "no"
  report_key "beskid/ci/build" "OVSX_TOKEN" "no"
  if [[ "${missing}" -gt 0 ]]; then
    echo
    echo "${missing} required key(s) missing. Run without --check to seed, after filling ${SECRETS_FILE}."
    exit 1
  fi
  echo "All required keys present."
  exit 0
fi

if ! bao secrets list -format=json | jq -e --arg m "${OPENBAO_MOUNT}/" 'has($m)' >/dev/null 2>&1; then
  bao secrets enable -path="${OPENBAO_MOUNT}" -version=2 kv
fi

seed_ci_build

for lane in "${lanes[@]}"; do
  apply_lane "${lane}"
done

echo
echo "Done. Verify:"
echo "  BAO_ADDR='${OPENBAO_ADDR}' ./scripts/seed-openbao-from-gh.sh --check --lane ${lanes[0]}"
echo "  just sync-env-prod   # OpenBao → Coolify compose env (after deploy)"
