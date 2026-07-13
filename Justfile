# Beskid infra — manifest-driven Coolify delivery support.
#
#   just config-init
#   just delivery-contract

set dotenv-load := true
set shell := ["bash", "-euo", "pipefail", "-c"]

root := justfile_directory()
superrepo := root + "/.."
config_dir := root + "/config"
compose_prod := root + "/compose/production"

default:
    @just --list

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
    cd "{{compose_prod}}" && BESKID_RELEASE_TAG=validation docker compose --env-file .env config

delivery-contract:
    cd "{{superrepo}}" && bash scripts/ci/test/run-cicd-foundation-tests.sh

sync-env-prod:
    cd "{{superrepo}}" && scripts/ci/sync-runtime-env.sh production beskid_infra/config/coolify-production.json

sync-env-staging:
    cd "{{superrepo}}" && scripts/ci/sync-runtime-env.sh staging beskid_infra/config/coolify-staging.json

seed-openbao-all:
    "{{root}}/scripts/seed-openbao-from-gh.sh" --lane production

seed-openbao-check:
    "{{root}}/scripts/seed-openbao-from-gh.sh" --lane production --check
