#!/usr/bin/env bash
# Shared Coolify REST helpers (no Terraform provider).
set -euo pipefail

coolify_api_base() {
  : "${COOLIFY_ENDPOINT:?Set COOLIFY_ENDPOINT}"
  : "${COOLIFY_API_TOKEN:?Set COOLIFY_API_TOKEN}"
  printf '%s' "${COOLIFY_ENDPOINT%/}"
}

coolify_curl() {
  local method="$1"
  shift
  local base
  base="$(coolify_api_base)"
  curl -fsS -X "${method}" \
    -H "Authorization: Bearer ${COOLIFY_API_TOKEN}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    "${base}$@"
}

coolify_get() {
  local path="$1"
  coolify_curl GET "${path}"
}

coolify_patch_json() {
  local path="$1"
  local body="$2"
  coolify_curl PATCH "${path}" -d "${body}"
}

coolify_post_json() {
  local path="$1"
  local body="$2"
  coolify_curl POST "${path}" -d "${body}"
}

coolify_uuid_by_name() {
  local collection_path="$1"
  local name="$2"
  coolify_get "${collection_path}" \
    | jq -r --arg n "${name}" '.[] | select(.name == $n) | (.uuid // .id)' \
    | head -n1
}

coolify_resolve_project_uuid() {
  local project_name="${COOLIFY_PROJECT_NAME:-Beskid}"
  local uuid
  uuid="$(coolify_uuid_by_name "/api/v1/projects" "${project_name}")"
  if [[ -n "${uuid}" && "${uuid}" != "null" ]]; then
    printf '%s' "${uuid}"
    return 0
  fi
  if [[ -n "${COOLIFY_PROJECT_UUID:-}" ]]; then
    printf '%s' "${COOLIFY_PROJECT_UUID}"
    return 0
  fi
  echo "Coolify project '${project_name}' not found" >&2
  return 1
}

coolify_compose_b64() {
  local compose_file="$1"
  base64 <"${compose_file}" | tr -d '\n'
}

coolify_service_deploy() {
  local service_uuid="$1"
  local force="${2:-false}"
  local query=""
  if [[ "${force}" == "true" ]]; then
    query="&force=true"
  fi
  coolify_curl GET "/api/v1/deploy?uuid=${service_uuid}${query}" >/dev/null || true
}

coolify_envs_bulk_patch() {
  local resource_type="$1"
  local resource_uuid="$2"
  local json_env_file="$3"
  local items
  items="$(jq -c '[to_entries[] | {key: .key, value: (.value|tostring)}]' "${json_env_file}")"
  coolify_patch_json "/api/v1/${resource_type}s/${resource_uuid}/envs/bulk" \
    "{\"data\": ${items}}"
}
