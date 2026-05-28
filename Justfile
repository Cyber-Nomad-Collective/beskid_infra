# Beskid infra — OpenTofu deploy (branch → environment: main=production, stg=staging).
#
#   just config-init
#   git checkout main && just plan

set dotenv-load := true
set shell := ["bash", "-euo", "pipefail", "-c"]

root := justfile_directory()
superrepo := root + "/.."
config_dir := root + "/config"
lib_dir := root + "/scripts/lib"

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

check-tfvars env:
    @test -f "{{config_dir}}/{{env}}.tfvars" || (echo "Missing config/{{env}}.tfvars — run: just config-init" >&2; exit 1)

check:
    #!/usr/bin/env bash
    source "{{lib_dir}}/git-tofu-env.sh"
    lane="$(beskid_tofu_env_from_git)" || exit 1
    just check-tfvars "${lane}"
    command -v tofu >/dev/null || { echo "Install OpenTofu (just deps-install)" >&2; exit 1; }

config-init:
    @for e in production staging; do \
      test -f "{{config_dir}}/$${e}.tfvars" || cp "{{config_dir}}/$${e}.tfvars.example" "{{config_dir}}/$${e}.tfvars"; \
    done
    @test -f "{{root}}/.env" || cp "{{root}}/.env.example" "{{root}}/.env"
    @echo "Created config/{production,staging}.tfvars and .env"

mcp-snapshot-hint:
    @echo "Update config/coolify.snapshot.json via Coolify MCP (see config/README.md)"

export-openbao:
    #!/usr/bin/env bash
    source "{{root}}/scripts/export-openbao-for-tofu.sh"

_lane:
    #!/usr/bin/env bash
    source "{{lib_dir}}/git-tofu-env.sh"
    beskid_tofu_env_from_git

_tf-init:
    #!/usr/bin/env bash
    set -euo pipefail
    "{{superrepo}}/scripts/ci/install-coolify-provider.sh"
    "{{superrepo}}/scripts/ci/ensure-coolify-lock-open.sh" \
      "{{root}}/environments/production/.terraform.lock.hcl" \
      "{{root}}/environments/staging/.terraform.lock.hcl"
    export TF_CLI_CONFIG_FILE="{{root}}/terraform.tofurc.generated"
    source "{{lib_dir}}/git-tofu-env.sh"
    lane="$(beskid_tofu_env_from_git)"
    cd "{{root}}/environments/${lane}"
    tofu init -input=false

_tf-plan:
    #!/usr/bin/env bash
    set -euo pipefail
    export TF_CLI_CONFIG_FILE="{{root}}/terraform.tofurc.generated"
    source "{{lib_dir}}/git-tofu-env.sh"
    lane="$(beskid_tofu_env_from_git)"
    if [[ -n "${VAULT_ADDR:-}" ]]; then
      source "{{root}}/scripts/export-openbao-for-tofu.sh"
    elif [[ -n "${COOLIFY_API_TOKEN:-}" ]]; then
      export TF_VAR_coolify_api_token="${COOLIFY_API_TOKEN}"
      export TF_VAR_openbao_address="${VAULT_ADDR:-}"
    fi
    cd "{{root}}/environments/${lane}"
    tofu plan -input=false -var-file="{{config_dir}}/${lane}.tfvars" -out=tfplan

_tf-apply:
    #!/usr/bin/env bash
    source "{{lib_dir}}/git-tofu-env.sh"
    lane="$(beskid_tofu_env_from_git)"
    if [[ -n "${VAULT_ADDR:-}" ]]; then
      source "{{root}}/scripts/export-openbao-for-tofu.sh"
    elif [[ -n "${COOLIFY_API_TOKEN:-}" ]]; then
      export TF_VAR_coolify_api_token="${COOLIFY_API_TOKEN}"
      export TF_VAR_openbao_address="${VAULT_ADDR:-}"
    fi
    cd "{{root}}/environments/${lane}"
    tofu apply -input=false -auto-approve tfplan

# Branch-selected (main → production, stg → staging)

init: check
    just _tf-init

plan: check
    just _tf-plan

apply: check
    just _tf-apply

deploy: check
    just plan
    @echo ">>> apply in 5s (Ctrl+C to abort)"
    @sleep 5
    just apply

# Explicit lanes (current branch must match)

init-prod:
    #!/usr/bin/env bash
    set -euo pipefail
    test -f "{{config_dir}}/production.tfvars"
    source "{{lib_dir}}/git-tofu-env.sh"
    beskid_assert_tofu_env production
    just _tf-init

plan-prod:
    #!/usr/bin/env bash
    set -euo pipefail
    test -f "{{config_dir}}/production.tfvars"
    source "{{lib_dir}}/git-tofu-env.sh"
    beskid_assert_tofu_env production
    just _tf-plan

apply-prod:
    #!/usr/bin/env bash
    set -euo pipefail
    test -f "{{config_dir}}/production.tfvars"
    source "{{lib_dir}}/git-tofu-env.sh"
    beskid_assert_tofu_env production
    just _tf-apply

deploy-prod:
    just plan-prod
    @sleep 5
    just apply-prod

init-staging:
    #!/usr/bin/env bash
    set -euo pipefail
    test -f "{{config_dir}}/staging.tfvars"
    source "{{lib_dir}}/git-tofu-env.sh"
    beskid_assert_tofu_env staging
    just _tf-init

plan-staging:
    #!/usr/bin/env bash
    set -euo pipefail
    test -f "{{config_dir}}/staging.tfvars"
    source "{{lib_dir}}/git-tofu-env.sh"
    beskid_assert_tofu_env staging
    just _tf-plan

apply-staging:
    #!/usr/bin/env bash
    set -euo pipefail
    test -f "{{config_dir}}/staging.tfvars"
    source "{{lib_dir}}/git-tofu-env.sh"
    beskid_assert_tofu_env staging
    just _tf-apply

deploy-staging:
    just plan-staging
    @sleep 5
    just apply-staging

output:
    #!/usr/bin/env bash
    source "{{lib_dir}}/git-tofu-env.sh"
    lane="$(beskid_tofu_env_from_git)"
    cd "{{root}}/environments/${lane}" && tofu output
