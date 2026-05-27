# Bootstrap guide

From empty `beskid_infra` to OpenTofu-managed Coolify apps with OpenBao and Let's Encrypt.

## Prerequisites

- Coolify running (Traefik proxy, ports 80/443)
- API token: Settings → API tokens
- **New** Coolify project named `Beskid` (rename the legacy project to `old` to avoid UUID conflicts)
- OpenTofu ≥ 1.6 (runs in GitHub Actions — not required on the Coolify host)
- GHCR images for enabled services (`main` / `staging`)

OpenBao is **deployed by OpenTofu** (`modules/coolify_openbao`) as a Coolify Compose service before site/auth. No separate OpenBao install on the host.

## 1. OpenBao (Terraform-managed)

Public URLs:

| Lane | Hostname |
|------|----------|
| production | `https://bao.beskid-lang.org` |
| staging | `https://stg-bao.beskid-lang.org` |

After the first `tofu apply` creates the Coolify service:

```bash
export OPENBAO_ADDR="https://bao.beskid-lang.org"
./scripts/openbao-init-unseal.sh   # prints OPENBAO_ROOT_TOKEN once
```

Store `OPENBAO_ROOT_TOKEN` as GitHub secret **`OPENBAO_TOKEN`** (and optional **`OPENBAO_UNSEAL_KEY`**). Re-run apply with `seed_openbao_secrets = true` to populate KV.

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

**Repository variables** (Actions → Variables):

| Variable | Value |
|----------|-------|
| `COOLIFY_ENDPOINT` | `https://coolify.bdziam.dev` |
| `COOLIFY_PROJECT_UUID` | **New** Beskid project UUID (not the renamed `old` project) |
| `COOLIFY_SERVER_UUID` | Target server UUID |

**Repository secrets:**

| Secret | Value |
|--------|-------|
| `COOLIFY_API_TOKEN` | Coolify API token |
| `OPENBAO_TOKEN` | OpenBao root token (after `openbao-init-unseal.sh`) |
| `OPENBAO_UNSEAL_KEY` | Optional; required to unseal after restarts |

Workflows: [`beskid-platform.yml`](../../.github/workflows/beskid-platform.yml) (GHCR + plan), [`container-images.yml`](../../.github/workflows/container-images.yml), [`tofu-plan-apply.yml`](../../.github/workflows/tofu-plan-apply.yml), [`release.yml`](../../.github/workflows/release.yml).

GitHub environments: `staging`, `production` (approval on production apply).

## 7. GHCR on Coolify server

Settings → Docker Registries → `ghcr.io` with PAT `read:packages`.

## Verify

```bash
curl -sI "https://beskid-lang.org/" | head -3
curl -s "https://auth.beskid-lang.org/api/v1/health"
```
