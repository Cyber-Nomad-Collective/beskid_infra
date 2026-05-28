# Greenfield Coolify deploy

OpenTofu **manages** the Coolify project (`coolify_project.beskid`). Before plan/apply, CI runs `scripts/ci/ensure-coolify-project-import.sh`: if a project named **Beskid** already exists, it is **imported** into state so apply does not POST a duplicate. The legacy **Beskid_MANUAL** project is not touched.

## MCP snapshot (2026-05-27)

| Resource | Value |
|----------|--------|
| Server `localhost` | `ec0cs0cw0ocsok488gc0k80k` |
| Legacy `Beskid_MANUAL` | `tosg8kc80g8go00sgcswsccg` (deprecated, untouched) |
| Target project | **`Beskid`** — created by Terraform on first production apply |

## GitHub (superrepo)

| Kind | Name | Value |
|------|------|--------|
| Secret | `COOLIFY_API_TOKEN` | Coolify API token |
| Secret | `OPENBAO_TOKEN` | After first OpenBao init |
| Secret | `OPENBAO_UNSEAL_KEY` | Optional |
| Variable | `COOLIFY_ENDPOINT` | `https://coolify.bdziam.dev` |
| Variable | `COOLIFY_SERVER_UUID` | `ec0cs0cw0ocsok488gc0k80k` |
| Variable | `COOLIFY_DESTINATION_UUID` | `zss4wkockgw8gok888gscc84` (localhost → **coolify** network) |

Do **not** set `COOLIFY_PROJECT_UUID` — production imports-or-creates by name; staging resolves UUID in CI.

## What OpenTofu creates (per lane)

On `main` → **production**, on `stg` → **staging**:

1. **`coolify_project.beskid`** (production only)
2. Coolify **environment** — production uses Coolify's default `production` env (created with the project); staging creates `staging` via `manage_environment = true`
3. **OpenBao** Compose service
4. **site**, **auth**, **tracker**, **nexus**, and **pckg** GHCR apps (toggle via `enable_services`)

## Pipeline

For infra-only debugging: **Actions → Beskid platform → Run workflow** with **Skip GHCR builds** (no container matrix). The vendored Coolify provider is cached in CI when `beskid_infra/vendor/` is unchanged.

Push to `main` or `stg` → **Beskid platform**:

1. GHCR build (site, auth, tracker, nexus, pckg)
2. Production: `tofu init` → import existing **Beskid** project if present → plan/apply
3. Staging: resolve `Beskid` project UUID via Coolify API → plan/apply
4. `openbao-init-unseal.sh` — store root token as `OPENBAO_TOKEN`, re-apply for KV seeding

## Local

```bash
cd beskid_infra && just config-init
export TF_VAR_coolify_api_token="..."
export COOLIFY_ENDPOINT="https://coolify.example"
export COOLIFY_API_TOKEN="..."
git checkout main
just init
../../scripts/ci/ensure-coolify-project-import.sh production
just plan && just apply
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `no attribute named "uuid"` on `coolify_project` | Use `.id` — arcusis provider UUID is the Terraform `id` attribute |
| `Environment with this name already exists` (409) | Coolify creates a default `production` environment with each new project — set `manage_environment = false` on production |
| `Server has multiple destinations` (400) | Set `destination_uuid` (localhost coolify network: `zss4wkockgw8gok888gscc84`) — see Coolify → Destinations |
| `docker_compose_raw` must be base64 (422) | Use vendored provider **1.1.18-beskid** (`scripts/ci/install-coolify-provider.sh`) |
| OpenBao domain / sslip.io instead of `bao.*` | Set `coolify_service.urls` (hostname + `:8200`); compose uses `SERVICE_FQDN_OPENBAO_8200` without a hostname value — see `modules/coolify_openbao` |
| `vault_kv_secret_v2` deprecated (warning) | Informational until OpenTofu ≥1.10 + ephemeral migration; does not block apply |
| Duplicate **Beskid** projects in Coolify | Delete extras in the UI; keep one UUID, run `ensure-coolify-project-import.sh` so state matches |
| `templatefile` / colon in interpolation | OpenBao compose only uses `${openbao_version}`; domain is set via `coolify_service.urls`, not `SERVICE_FQDN_*` hostname values |
| Literal `$` in compose for Coolify | Escape as `$${` in YAML processed by `templatefile()` |
| `doesn't match any of the checksums` for `arcusis/coolify` on Linux CI | Do **not** commit `arcusis/coolify` in `.terraform.lock.hcl` — mirror install only; run `scripts/ci/ensure-coolify-lock-open.sh` before `tofu init` (CI and `just plan` do this automatically) |
