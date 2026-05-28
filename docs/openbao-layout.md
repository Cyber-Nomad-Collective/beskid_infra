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

Use **`scripts/seed-openbao-from-gh.sh`** (preferred): pulls GitHub **variables** via `gh`, merges **secrets** from `config/openbao-secrets.env` (GitHub CLI cannot read secret values).

```bash
cd beskid_infra
cp config/openbao-secrets.env.example config/openbao-secrets.env
# Edit: OPENBAO_TOKEN, COOLIFY_API_TOKEN (from GitHub Actions secrets UI)

export BAO_ADDR="https://secrets.bdziam.dev"   # must include https://
export OPENBAO_TOKEN="s...."

chmod +x scripts/seed-openbao-from-gh.sh
./scripts/seed-openbao-from-gh.sh --check
./scripts/seed-openbao-from-gh.sh
```

`bao login -address=secrets.bdziam.dev` fails with `unsupported protocol scheme ""` — always use `https://` or `bao login` after `export BAO_ADDR=https://secrets.bdziam.dev`.

Manual put (equivalent to what the seed script writes for tofu):

```bash
export BAO_ADDR="https://secrets.bdziam.dev"
export BAO_TOKEN="..."

bao kv put secret/beskid/tofu/production \
  coolify_endpoint="https://coolify.bdziam.dev" \
  coolify_api_token="tcp-..." \
  coolify_server_uuid="ec0cs0cw0ocsok488gc0k80k" \
  coolify_destination_uuid="zss4wkockgw8gok888gscc84"
```

## OpenTofu

Provider: `hashicorp/vault` with `address = var.openbao_address`. Module `openbao_kv` reads `secret/beskid/<lane>/<service>`.

Disable reads during bootstrap: `openbao_enabled = false` and set env only in Coolify UI temporarily.

## Rotation

```bash
vault kv patch secret/beskid/production/auth SESSION_SECRET="$(openssl rand -base64 32)"
cd environments/production && tofu apply
```
