# Greenfield Coolify deploy

OpenTofu **creates** the Coolify project (`coolify_project.beskid`). The legacy **Beskid_MANUAL** project is not imported or merged.

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

Do **not** set `COOLIFY_PROJECT_UUID` — production creates the project; staging resolves it by name in CI.

## What OpenTofu creates (per lane)

On `main` → **production**, on `stg` → **staging**:

1. **`coolify_project.beskid`** (production only)
2. Coolify **environment** — production uses Coolify's default `production` env (created with the project); staging creates `staging` via `manage_environment = true`
3. **OpenBao** Compose service
4. **site**, **auth**, **tracker**, **nexus**, and **pckg** GHCR apps (toggle via `enable_services`)

## Pipeline

Push to `main` or `stg` → **Beskid platform**:

1. GHCR build (site, auth, tracker, nexus, pckg)
2. Staging: resolve `Beskid` project UUID via Coolify API
3. `tofu plan` + `tofu apply`
4. `openbao-init-unseal.sh` — store root token as `OPENBAO_TOKEN`, re-apply for KV seeding

## Local

```bash
cd beskid_infra && just config-init
export TF_VAR_coolify_api_token="..."
git checkout main && just plan && just apply
# Note coolify_project_uuid output; use for staging tfvars or let CI resolve
```

## Troubleshooting

| Error | Fix |
|-------|-----|
| `no attribute named "uuid"` on `coolify_project` | Use `.id` — arcusis provider UUID is the Terraform `id` attribute |
| `Environment with this name already exists` (409) | Coolify creates a default `production` environment with each new project — set `manage_environment = false` on production |
| `Server has multiple destinations` (400) | Set `destination_uuid` (localhost coolify network: `zss4wkockgw8gok888gscc84`) — see Coolify → Destinations |
| `templatefile` / colon in interpolation | Only `${openbao_version}` / `${openbao_fqdn}` in compose — no shell `${VAR:-default}` anywhere in the file (including comments); pass defaults in Terraform |
| Literal `$` in compose for Coolify | Escape as `$${` in YAML processed by `templatefile()` |
