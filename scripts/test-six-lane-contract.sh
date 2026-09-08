#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
infra_dir="$(cd "${script_dir}/.." && pwd)"
compose_file="${infra_dir}/compose/production/docker-compose.yml"
compose_env="${infra_dir}/compose/production/.env.example"

expected_lanes='["auth","learn","nexus","pckg","site","tracker"]'
expected_services='["auth","learn","memgraph","nexus","pckg","postgres","site","tracker"]'
expected_secret_services='["auth","nexus","pckg","tracker"]'
expected_profiles='["nexus","pckg","tracker"]'
expected_production_volumes='{
  "auth-data":"s4ir1ovgqtubarqeql3gf3pz_auth-data",
  "memgraph-data":"s4ir1ovgqtubarqeql3gf3pz_memgraph-data",
  "nexus-data":"beskid-platform_nexus-data",
  "pckg_packages":"beskid-pckg_pckg-artifacts",
  "pckg_pg_data":"s4ir1ovgqtubarqeql3gf3pz_pckg-pg-data",
  "tracker-data":"beskid-sites_tracker-data"
}'

assert_json_equal() {
  local description="$1"
  local expected="$2"
  local actual="$3"

  if ! jq -e -n --argjson expected "${expected}" --argjson actual "${actual}" \
    '$expected == $actual' >/dev/null; then
    printf 'FAIL: %s\nexpected: %s\nactual:   %s\n' \
      "${description}" "${expected}" "${actual}" >&2
    return 1
  fi
}

for lane in production staging; do
  domains="$(
    jq -c --arg lane "${lane}" \
      '.[$lane].services | keys | sort' "${infra_dir}/config/domains.json"
  )"
  assert_json_equal "${lane} domain lanes" "${expected_lanes}" "${domains}"

  config="${infra_dir}/config/coolify-${lane}.json"
  secret_services="$(jq -c '.openbao_services | sort' "${config}")"
  assert_json_equal "${lane} OpenBao services" "${expected_secret_services}" "${secret_services}"

  profiles="$(jq -Rc 'split(",") | sort' <<<"$(jq -r '.compose_profiles' "${config}")")"
  assert_json_equal "${lane} Compose profiles" "${expected_profiles}" "${profiles}"
done

production_volumes="$(jq -cS '.external_volumes // {}' "${infra_dir}/config/coolify-production.json")"
assert_json_equal "production external volumes" "$(jq -cS . <<<"${expected_production_volumes}")" "${production_volumes}"
staging_volumes="$(jq -cS '.external_volumes // {}' "${infra_dir}/config/coolify-staging.json")"
assert_json_equal "staging external volumes" '{}' "${staging_volumes}"

rendered_services="$(
  BESKID_RELEASE_TAG=contract docker compose \
    --env-file "${compose_env}" \
    --file "${compose_file}" \
    config --services |
    jq -Rsc 'split("\n") | map(select(length > 0)) | sort'
)"
assert_json_equal "rendered Compose services" "${expected_services}" "${rendered_services}"

rendered_lanes="$(
  BESKID_RELEASE_TAG=contract docker compose \
    --env-file "${compose_env}" \
    --file "${compose_file}" \
    config --images |
    sed -n 's#^ghcr.io/cyber-nomad-collective/beskid-\([^:@]*\).*#\1#p' |
    jq -Rsc 'split("\n") | map(select(length > 0)) | sort'
)"
assert_json_equal "rendered application lanes" "${expected_lanes}" "${rendered_lanes}"

# Keep the production pckg lane on the Rust registry contract. This catches
# accidental reintroduction of the retired ASP.NET/session configuration and
# of commented deployment examples that cannot be validated as topology.
grep -Fq 'PCKG_DATABASE_URL: ${PCKG_DATABASE_URL:?set PCKG_DATABASE_URL}' "${compose_file}"
grep -Fq 'PCKG_RELEASE_PUBLISHER_KEY_SHA256: ${PCKG_RELEASE_PUBLISHER_KEY_SHA256:?set PCKG_RELEASE_PUBLISHER_KEY_SHA256}' "${compose_file}"
grep -Fq 'PCKG_BIND_ADDRESS: "0.0.0.0:8082"' "${compose_file}"
if grep -Eq 'ASPNETCORE_|ConnectionStrings__|Storage__UploadsRootPath|SHELL_AUTH_MODE|Example: a shell-template|authelia' "${compose_file}"; then
  echo "FAIL: obsolete pckg or example deployment configuration remains in production Compose" >&2
  exit 1
fi

retired_slug="platform""-spec"
retired_env="PLATFORM""_SPEC"
if grep -R -l -E \
  --exclude='test-six-lane-contract.sh' \
  "${retired_slug}|${retired_env}" \
  "${infra_dir}/compose/production/docker-compose.yml" \
  "${infra_dir}/compose/production/README.md" \
  "${infra_dir}/compose/staging/README.md" \
  "${infra_dir}/config/domains.json" \
  "${infra_dir}/config/coolify-production.json" \
  "${infra_dir}/config/coolify-staging.json" \
  "${infra_dir}/config/openbao-secrets.env.example" \
  "${infra_dir}/docs" \
  "${infra_dir}/monitoring" \
  "${infra_dir}/scripts"; then
  echo "FAIL: retired lane remains in the active infrastructure surface" >&2
  exit 1
fi

echo "six-lane infrastructure contract: PASS"
