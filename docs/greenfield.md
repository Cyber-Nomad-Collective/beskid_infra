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

Do **not** set `COOLIFY_PROJECT_UUID` — production creates the project; staging resolves it by name in CI.

## What OpenTofu creates (per lane)

On `main` → **production**, on `stg` → **staging**:

1. **`coolify_project.beskid`** (production only)
2. Coolify **environment** (`production` / `staging`)
3. **OpenBao** Compose service
4. **site** + **auth** GHCR apps (extend via `enable_services`)

## Pipeline

Push to `main` or `stg` → **Beskid platform (site + auth)**:

1. GHCR build
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

Legacy import (old project only): [coolify-import.md](coolify-import.md).
