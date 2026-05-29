#!/usr/bin/env bash
# Deploy lane helpers (production-first; staging is phase 2).

beskid_deploy_lane_production() {
  echo production
}

beskid_openbao_lane_for_deploy() {
  local lane="${1:-production}"
  case "${lane}" in
  production) echo production ;;
  staging) echo staging ;;
  *)
    echo "Unknown deploy lane: ${lane}" >&2
    return 1
    ;;
  esac
}
