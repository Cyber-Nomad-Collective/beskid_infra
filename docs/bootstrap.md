# Bootstrap guide

From empty `beskid_infra` to OpenTofu-managed Coolify apps with OpenBao and Let's Encrypt.

## Prerequisites

- Coolify running (Traefik/Caddy proxy, ports 80/443)
- API token: Settings → API tokens
- OpenTofu ≥ 1.6 (runs in GitHub Actions — not on the Coolify host)
- GHCR images for enabled services (`main` / `staging`)

**Greenfield:** OpenTofu creates `coolify_project.beskid` — do not create the project manually. Legacy **Beskid_MANUAL** stays untouched. See [greenfield.md](greenfield.md).

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

## 4. Staging lane

After production apply, note `tofu output coolify_project_uuid` or let CI resolve by name.

```bash
git checkout stg
cd environments/staging && tofu init && tofu apply
```

Legacy import (Beskid_MANUAL only): [coolify-import.md](coolify-import.md).

## 5. GitHub Actions

**Repository variables** (Actions → Variables):

| Variable | Value |
|----------|-------|
| `COOLIFY_ENDPOINT` | `https://coolify.bdziam.dev` |
| `COOLIFY_SERVER_UUID` | `ec0cs0cw0ocsok488gc0k80k` |

Do **not** set `COOLIFY_PROJECT_UUID` — production creates the project; staging resolves it in CI.

**Repository secrets:**

| Secret | Value |
|--------|-------|
| `COOLIFY_API_TOKEN` | Coolify API token |
| `OPENBAO_TOKEN` | OpenBao root token (after `openbao-init-unseal.sh`) |
| `OPENBAO_UNSEAL_KEY` | Optional; required to unseal after restarts |

Workflows: [`beskid-platform.yml`](../../.github/workflows/beskid-platform.yml) (GHCR + plan), [`container-images.yml`](../../.github/workflows/container-images.yml), [`tofu-plan-apply.yml`](../../.github/workflows/tofu-plan-apply.yml), [`release.yml`](../../.github/workflows/release.yml).

GitHub environments: `staging`, `production` (approval on production apply).

## 6. GHCR on Coolify server

Settings → Docker Registries → `ghcr.io` with PAT `read:packages`.

## Verify

```bash
curl -sI "https://beskid-lang.org/" | head -3
curl -s "https://auth.beskid-lang.org/api/v1/health"
```
