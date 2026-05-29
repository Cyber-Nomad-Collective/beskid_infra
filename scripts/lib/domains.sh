#!/usr/bin/env bash
# Build Coolify compose urls and public URL env from config/domains.json.
set -euo pipefail

domains_config_path() {
  local root="${1:?}"
  printf '%s/config/domains.json' "${root}"
}

# Coolify urls: [{ "name": "<compose_service>", "url": "https://host:port" }, ...]
coolify_urls_from_domains() {
  local domains_file="$1"
  local lane="$2"
  jq -c --arg lane "${lane}" '
    .[$lane].services
    | to_entries
    | map({
        name: .key,
        url: ("https://" + .value.host + ":" + (.value.port | tostring))
      })
  ' "${domains_file}"
}

# Public app URLs (no port) for OpenBao static env merge.
public_urls_from_domains() {
  local domains_file="$1"
  local lane="$2"
  jq -c --arg lane "${lane}" '.[$lane].public_urls // {}' "${domains_file}"
}
