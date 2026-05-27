# Bootstrap guide

From empty `beskid_infra` to OpenTofu-managed Coolify apps with OpenBao and Let's Encrypt.

## Prerequisites

- Coolify running (Traefik proxy, ports 80/443)
- API token: Settings → API tokens
- OpenBao KV v2 at `secret/`
- OpenTofu ≥ 1.6
- GHCR images for enabled services (`main` / `staging`)

## 1. OpenBao

```bash
export VAULT_ADDR="https://bao.example.com:8200"
export VAULT_TOKEN="..."

vault kv put secret/beskid/tofu/production \
  coolify_endpoint="https://coolify.bdziam.dev" \
  coolify_api_token="tcp-..." \
  coolify_project_uuid="tosg8kc80g8go00sgcswsccg" \
  coolify_server_uuid="ec0cs0cw0ocsok488gc0k80k"

vault kv put secret/beskid/production/auth \
  SESSION_SECRET="$(openssl rand -base64 32)" \
  IMAGE_TAG="main"
```

See [openbao-layout.md](openbao-layout.md).

## 2. DNS

Create **A** records for each hostname you enable (see [deploy-matrix.md](deploy-matrix.md)), e.g. `beskid-lang.org`, `auth.beskid-lang.org`, `stg-auth.beskid-lang.org`.

## 3. Local apply

```bash
git checkout main
source scripts/export-openbao-for-tofu.sh   # branch → production

cd environments/production
cp ../config/production.tfvars.example ../config/production.tfvars
tofu init && tofu plan
```

## 4. Import existing apps

```bash
tofu import 'module.stack.module.apps["site"].coolify_application.this' rsso488sscg80kookoo00sk4
```

More: [coolify-import.md](coolify-import.md).

## 5. Staging environment

Create `staging` in Coolify UI (or `manage_environment = true` in `environments/staging`).

```bash
git checkout stg
source scripts/export-openbao-for-tofu.sh
cd environments/staging && tofu init && tofu apply
```

## 6. GitHub Actions

Repository secrets:

| Secret | Value |
|--------|-------|
| `COOLIFY_ENDPOINT` | `https://coolify.bdziam.dev` |
| `COOLIFY_API_TOKEN` | API token |
| `OPENBAO_ADDR` | OpenBao URL |
| `OPENBAO_TOKEN` | CI token |
| `COOLIFY_PROJECT_UUID` | Project UUID |
| `COOLIFY_SERVER_UUID` | Server UUID |

Environments: `staging`, `production` (approval on production).

## 7. GHCR on Coolify server

Settings → Docker Registries → `ghcr.io` with PAT `read:packages`.

## Verify

```bash
curl -sI "https://beskid-lang.org/" | head -3
curl -s "https://auth.beskid-lang.org/api/v1/health"
```
