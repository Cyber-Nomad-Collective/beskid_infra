#!/usr/bin/env bash
# Create or update production Coolify compose service and redeploy.
#
# Usage:
#   coolify-deploy-compose.sh [--lane production] [--config path] [--no-sync] [--no-deploy]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/coolify-api.sh
source "${SCRIPT_DIR}/lib/coolify-api.sh"
# shellcheck source=lib/domains.sh
source "${SCRIPT_DIR}/lib/domains.sh"

DOMAINS_FILE="${ROOT}/config/domains.json"

LANE="production"
CONFIG="${ROOT}/config/coolify-production.json"
COMPOSE_FILE="${ROOT}/compose/production/docker-compose.yml"
SYNC_ENV=true
TRIGGER_DEPLOY=true

while [[ $# -gt 0 ]]; do
  case "$1" in
  --lane)
    shift
    LANE="${1:?}"
    ;;
  --config)
    shift
    CONFIG="${1:?}"
    ;;
  --no-sync)
    SYNC_ENV=false
    ;;
  --no-deploy)
    TRIGGER_DEPLOY=false
    ;;
  -h | --help)
    sed -n '2,5p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
  shift
done

if [[ "${LANE}" != "production" ]]; then
  echo "Only production is supported in phase 1 (got: ${LANE})." >&2
  exit 1
fi

if [[ ! -f "${COMPOSE_FILE}" ]]; then
  echo "Missing compose file: ${COMPOSE_FILE}" >&2
  exit 1
fi

service_name="$(jq -r '.service_name' "${CONFIG}")"
service_uuid="${COOLIFY_SERVICE_UUID:-$(jq -r '.service_uuid // empty' "${CONFIG}")}"
environment_name="$(jq -r '.environment_name // "production"' "${CONFIG}")"
project_name="$(jq -r '.project_name // "Beskid"' "${CONFIG}")"

COOLIFY_PROJECT_NAME="${COOLIFY_PROJECT_NAME:-${project_name}}"
COOLIFY_SERVER_UUID="${COOLIFY_SERVER_UUID:-$(jq -r '.server_uuid // empty' "${CONFIG}")}"
COOLIFY_DESTINATION_UUID="${COOLIFY_DESTINATION_UUID:-$(jq -r '.destination_uuid // empty' "${CONFIG}")}"

if [[ -z "${COOLIFY_SERVER_UUID}" && -f "${ROOT}/config/coolify.snapshot.json" ]]; then
  COOLIFY_SERVER_UUID="$(jq -r '.server_localhost.uuid // empty' "${ROOT}/config/coolify.snapshot.json")"
fi
if [[ -z "${COOLIFY_DESTINATION_UUID}" && -f "${ROOT}/config/coolify.snapshot.json" ]]; then
  COOLIFY_DESTINATION_UUID="$(jq -r '.destination_coolify_network.uuid // empty' "${ROOT}/config/coolify.snapshot.json")"
fi

: "${COOLIFY_SERVER_UUID:?Set COOLIFY_SERVER_UUID or config/coolify.snapshot.json}"

project_uuid="$(coolify_resolve_project_uuid)"
compose_b64="$(coolify_compose_b64 "${COMPOSE_FILE}")"

if [[ ! -f "${DOMAINS_FILE}" ]]; then
  echo "Missing ${DOMAINS_FILE}" >&2
  exit 1
fi
coolify_urls="$(coolify_urls_from_domains "${DOMAINS_FILE}" "${LANE}")"
echo "Coolify domains (${LANE}): $(echo "${coolify_urls}" | jq -r '.[].url' | paste -sd', ' -)"

if [[ "${SYNC_ENV}" == "true" ]]; then
  "${SCRIPT_DIR}/coolify-sync-env-from-openbao.sh" --config "${CONFIG}" --lane "${LANE}" || {
    echo "Env sync failed (continuing if service exists)..." >&2
  }
fi

if [[ -z "${service_uuid}" ]]; then
  service_uuid="$(coolify_uuid_by_name "/api/v1/services" "${service_name}")"
fi

create_body="$(jq -n \
  --arg name "${service_name}" \
  --arg project "${project_uuid}" \
  --arg server "${COOLIFY_SERVER_UUID}" \
  --arg env "${environment_name}" \
  --arg dest "${COOLIFY_DESTINATION_UUID}" \
  --arg compose "${compose_b64}" \
  --argjson urls "${coolify_urls}" \
  '{
    name: $name,
    project_uuid: $project,
    server_uuid: $server,
    environment_name: $env,
    docker_compose_raw: $compose,
    urls: $urls,
    force_domain_override: true,
    instant_deploy: true
  }
  | if ($dest | length) > 0 then . + {destination_uuid: $dest} else . end')"

if [[ -z "${service_uuid}" || "${service_uuid}" == "null" ]]; then
  echo "Creating Coolify compose service: ${service_name}"
  response="$(coolify_post_json "/api/v1/services" "${create_body}")"
  service_uuid="$(echo "${response}" | jq -r '.uuid // .id')"
else
  echo "Updating Coolify compose service: ${service_uuid}"
  update_body="$(echo "${create_body}" | jq 'del(.instant_deploy)')"
  coolify_patch_json "/api/v1/services/${service_uuid}" "${update_body}" >/dev/null
fi

if [[ -z "${service_uuid}" || "${service_uuid}" == "null" ]]; then
  echo "Failed to resolve service UUID after create/update." >&2
  exit 1
fi

echo "Service UUID: ${service_uuid}"
if [[ -z "${GITHUB_ACTIONS:-}" ]]; then
  echo "Updating ${CONFIG} with service_uuid."
  tmp_config="$(mktemp)"
  jq --arg u "${service_uuid}" '.service_uuid = $u' "${CONFIG}" >"${tmp_config}"
  mv "${tmp_config}" "${CONFIG}"
else
  echo "Set GitHub variable COOLIFY_COMPOSE_SERVICE_UUID=${service_uuid} (or commit config/coolify-production.json)."
fi

if [[ "${SYNC_ENV}" == "true" ]]; then
  "${SCRIPT_DIR}/coolify-sync-env-from-openbao.sh" --config "${CONFIG}" --lane "${LANE}"
fi

if [[ "${TRIGGER_DEPLOY}" == "true" ]]; then
  echo "Triggering deploy..."
  coolify_service_deploy "${service_uuid}" true
fi

echo "Done: ${service_name} (${service_uuid})"
