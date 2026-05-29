# beskid_infra

Coolify **Compose** deploy for the Beskid platform (GHCR images, OpenBao secrets, Let's Encrypt domains).

## Quick start

```bash
just config-init
# .env: COOLIFY_API_TOKEN, OPENBAO_TOKEN (see .env.example)
just compose-config
just deploy-prod
```

Operator guide: [docs/deploy-compose.md](docs/deploy-compose.md) · OpenBao: [docs/openbao-layout.md](docs/openbao-layout.md) · Hostnames: [docs/deploy-matrix.md](docs/deploy-matrix.md).

## Layout

```
compose/production/     # platform docker-compose.yml
config/                 # coolify-production.json, coolify.snapshot.json
scripts/                # coolify-deploy-compose.sh, sync-env, seed-openbao
```

## Deploy flow

| Step | Tool |
|------|------|
| Build images | superrepo `container-images.yml` |
| Secrets | OpenBao `https://secrets.bdziam.dev` |
| Sync + deploy | `just deploy-prod` or CI `coolify-compose-deploy.yml` |

CI: push to `main` → **Beskid platform** workflow.

Toolchain: `../scripts/install-deps.sh --group infra` · Dagger: `beskid_infra/dagger/`
