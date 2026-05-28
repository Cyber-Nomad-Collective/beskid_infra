#!/usr/bin/env bash
# Export OpenBao KV for OpenTofu / GitHub Actions.
#
# OpenBao lane is derived from git branch unless BESKID_TOFU_ENV is preset (CI override):
#   main → production   (secret/beskid/tofu/production)
#   stg  → staging      (secret/beskid/tofu/staging)
#
# Usage (from beskid_infra or with VAULT_* in .env):
#   source scripts/export-openbao-for-tofu.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/git-tofu-env.sh
source "${SCRIPT_DIR}/lib/git-tofu-env.sh"

_vault_addr_raw="${VAULT_ADDR:?Set VAULT_ADDR (OpenBao API URL, include https://)}"
if [[ "${_vault_addr_raw}" != http://* && "${_vault_addr_raw}" != https://* ]]; then
  _vault_addr_raw="https://${_vault_addr_raw}"
fi
export VAULT_ADDR="${_vault_addr_raw%/}"
unset _vault_addr_raw
: "${OPENBAO_KV_MOUNT:=secret}"

if [[ -z "${BESKID_TOFU_ENV:-}" ]]; then
  BESKID_TOFU_ENV="$(beskid_tofu_env_from_git)" || exit 1
  export BESKID_TOFU_ENV
fi

if [[ -z "${VAULT_TOKEN:-}" && -n "${VAULT_ROLE_ID:-}" && -n "${VAULT_SECRET_ID:-}" ]]; then
  VAULT_TOKEN="$(vault write -field=token "auth/approle/login" \
    role_id="${VAULT_ROLE_ID}" secret_id="${VAULT_SECRET_ID}")"
  export VAULT_TOKEN
fi

: "${VAULT_TOKEN:?Set VAULT_TOKEN or AppRole credentials}"

_json="$(vault kv get -format=json "${OPENBAO_KV_MOUNT}/beskid/tofu/${BESKID_TOFU_ENV}" | jq -r '.data.data')"

export TF_VAR_coolify_endpoint="$(echo "$_json" | jq -r '.coolify_endpoint // .coolify_api_url // empty' | sed -E 's|/api/v1/?$||')"
export TF_VAR_coolify_api_token="$(echo "$_json" | jq -r '.coolify_api_token // empty')"
export TF_VAR_openbao_address="${VAULT_ADDR}"
export TF_VAR_openbao_token="${VAULT_TOKEN}"

_uuid_project="$(echo "$_json" | jq -r '.coolify_project_uuid // empty')"
_uuid_server="$(echo "$_json" | jq -r '.coolify_server_uuid // empty')"
[[ -n "$_uuid_project" ]] && export TF_VAR_project_uuid="$_uuid_project"
[[ -n "$_uuid_server" ]] && export TF_VAR_server_uuid="$_uuid_server"

_branch="$(beskid_git_branch 2>/dev/null || echo '?')"
echo "Exported TF_VAR_* for OpenTofu (branch=${_branch} → ${BESKID_TOFU_ENV})"
