# OpenBao secret layout

Runtime secrets live in OpenBao KV v2. **OpenBao itself** is deployed by `modules/coolify_openbao` (Coolify Compose) before site/auth. OpenTofu reads KV at apply time and pushes to Coolify via `coolify_envs_bulk`.

| Lane | OpenBao URL |
|------|-------------|
| production | `https://bao.beskid-lang.org` |
| staging | `https://stg-bao.beskid-lang.org` |

## Path hierarchy

```
secret/
  beskid/
    production/   site, auth, tracker, nexus, pckg
    staging/      site, auth, tracker, nexus, pckg
    tofu/
      production/   git branch main
      staging/      git branch stg
    ci/
      build/        NODE_AUTH_TOKEN, OVSX_TOKEN
```

## Per-service keys

### site

| Key | Required |
|-----|----------|
| `IMAGE_TAG` | yes (`main` / `staging`) |
| `PUBLIC_GISCUS_*` | no |

### auth

| Key | Required |
|-----|----------|
| `AUTH_HUB_PUBLIC_URL` | yes (TF sets from hostname; patch if overriding) |
| `SESSION_SECRET` | yes |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | yes* |
| `IMAGE_TAG` | yes |

### tracker

| Key | Required |
|-----|----------|
| `AUTH_HUB_PUBLIC_URL` | yes |
| `SESSION_SECRET` | yes |
| `TRACKER_PUBLIC_URL` | yes (TF sets from hostname) |
| `GITHUB_SYNC_TOKEN` | recommended |

### nexus

| Key | Required |
|-----|----------|
| `GITNEXUS_HOME` | yes (`/data/gitnexus`) |
| `AUTH_HUB_PUBLIC_URL` | yes |
| `SESSION_SECRET` | yes |

### pckg

| Key | Required |
|-----|----------|
| `ConnectionStrings__Default` | yes (or components via `PCKG_DB_*` + TF) |
| `POSTGRES_PASSWORD` | yes (or TF-managed DB password) |
| `AUTH_HUB_PUBLIC_URL` | yes |
| `IMAGE_TAG` | yes |

### tofu/{environment} (CI / local)

| Key | Required |
|-----|----------|
| `coolify_endpoint` | yes (base URL, no `/api/v1`) |
| `coolify_api_token` | yes |
| `coolify_project_uuid` | optional |
| `coolify_server_uuid` | optional |

## Bootstrap

```bash
export VAULT_ADDR="https://bao.example.com:8200"
export VAULT_TOKEN="..."

vault secrets enable -path=secret kv-v2 2>/dev/null || true

vault kv put secret/beskid/production/auth \
  SESSION_SECRET="$(openssl rand -base64 32)" \
  IMAGE_TAG="main"

vault kv put secret/beskid/staging/auth \
  SESSION_SECRET="$(openssl rand -base64 32)" \
  IMAGE_TAG="staging"

vault kv put secret/beskid/tofu/production \
  coolify_endpoint="https://coolify.bdziam.dev" \
  coolify_api_token="tcp-..." \
  coolify_project_uuid="tosg8kc80g8go00sgcswsccg" \
  coolify_server_uuid="ec0cs0cw0ocsok488gc0k80k"
```

## OpenTofu

Provider: `hashicorp/vault` with `address = var.openbao_address`. Module `openbao_kv` reads `secret/beskid/<lane>/<service>`.

Disable reads during bootstrap: `openbao_enabled = false` and set env only in Coolify UI temporarily.

## Rotation

```bash
vault kv patch secret/beskid/production/auth SESSION_SECRET="$(openssl rand -base64 32)"
cd environments/production && tofu apply
```
