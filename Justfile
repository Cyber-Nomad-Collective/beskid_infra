# Beskid infra — Coolify Compose deploy (production first).
#
#   just config-init
#   just deploy-prod

set dotenv-load := true
set shell := ["bash", "-euo", "pipefail", "-c"]

root := justfile_directory()
superrepo := root + "/.."
config_dir := root + "/config"
compose_prod := root + "/compose/production"

default:
    @just --list

# --- Dagger CI (beskid_infra/dagger) ---

dagger-dir := root + "/dagger"

dagger-install:
    npm ci
    cd "{{dagger-dir}}"

dagger-functions: dagger-install
    cd "{{dagger-dir}}" && dagger functions

dagger-gate:
    cd "{{dagger-dir}}" && dagger call compiler-rust-gate --source="{{superrepo}}"

dagger-open-vsx platform bin_name rust_target="":
    cd "{{dagger-dir}}" && dagger call open-vsx-publish \
      --source="{{superrepo}}" \
      --platform="{{platform}}" \
      --bin-name="{{bin_name}}" \
      --rust-target="{{rust_target}}"

# --- toolchain (superrepo) ---

deps-check:
    {{superrepo}}/scripts/install-deps.sh --check --group infra

deps-install:
    {{superrepo}}/scripts/install-deps.sh --install -y --group infra

deps-beskid:
    {{superrepo}}/scripts/install-deps.sh --install --group beskid

# --- setup ---

config-init:
    @test -f "{{root}}/.env" || cp "{{root}}/.env.example" "{{root}}/.env"
    @test -f "{{compose_prod}}/.env" || cp "{{compose_prod}}/.env.example" "{{compose_prod}}/.env"
    @echo "Created .env and compose/production/.env"

check:
    command -v jq >/dev/null || { echo "Install jq (just deps-install)" >&2; exit 1; }
    command -v curl >/dev/null || { echo "Install curl" >&2; exit 1; }
    test -f "{{config_dir}}/coolify-production.json"

compose-config:
    cd "{{compose_prod}}" && docker compose --env-file .env config

sync-env-prod:
    "{{root}}/scripts/coolify-sync-env-from-openbao.sh" --lane production

deploy-prod:
    "{{root}}/scripts/coolify-deploy-compose.sh" --lane production

deploy-prod-no-sync:
    "{{root}}/scripts/coolify-deploy-compose.sh" --lane production --no-sync

seed-openbao-all:
    "{{root}}/scripts/seed-openbao-from-gh.sh" --lane production

seed-openbao-check:
    "{{root}}/scripts/seed-openbao-from-gh.sh" --lane production --check

openbao-check-prod:
    "{{root}}/scripts/coolify-sync-env-from-openbao.sh" --lane production --check
