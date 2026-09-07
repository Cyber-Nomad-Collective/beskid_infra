# OpenBao secret layout

Runtime secrets live in OpenBao KV v2 at **`https://secrets.bdziam.dev`**.
Platform delivery synchronizes them with the superrepo
`scripts/ci/sync-runtime-env.sh` before exact-digest deployment.

| Lane | KV prefix |
|------|-----------|
| production | `secret/beskid/production/{service}` |
| staging | `secret/beskid/staging/{service}` |

## Path hierarchy

```
secret/
  beskid/
    production/   site, auth, tracker, nexus, pckg
    staging/      site, auth, tracker, nexus, pckg
    ci/
      build/        NODE_AUTH_TOKEN, OVSX_TOKEN
```

## Per-service keys

### site

| Key | Required |
|-----|----------|
| `PUBLIC_GISCUS_*` | no |

Delivery reads **auth**, **tracker**, **nexus**, and **pckg**
from the lane config. Image identity never comes from OpenBao; the signed release
manifest supplies exact digests.

### auth

| Key | Required |
|-----|----------|
| `AUTH_HUB_PUBLIC_URL` | yes (also set in `coolify-production.json` static_env) |
| `SESSION_SECRET` | yes |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | yes* |

### tracker

| Key | Required |
|-----|----------|
| `AUTH_HUB_PUBLIC_URL` | yes |
| `SESSION_SECRET` | yes |
| `TRACKER_PUBLIC_URL` | yes |
| `GITHUB_SYNC_TOKEN` | recommended (autopair via GitHub API) |
| `TRACKER_PAIRING_APPROVER_LOGIN` | recommended (autopair without a sync token) |

### nexus

| Key | Required |
|-----|----------|
| `GITNEXUS_HOME` | yes (`/data/gitnexus`) |
| `AUTH_HUB_PUBLIC_URL` | yes |
| `SESSION_SECRET` | yes |
| `OPENROUTER_API_KEY` | no (enables server-side code-doc maintenance) |
| `NEXUS_DOC_MODEL` | no |

### pckg

| Key | Required |
|-----|----------|
| `POSTGRES_PASSWORD` | yes (generated or supplied by the seed script) |
| `POSTGRES_USER`, `POSTGRES_DB`, `PCKG_DB_HOST`, `PCKG_DB_PORT` | yes (seeded defaults or explicit overrides) |
| `PCKG_DATABASE_URL` | yes (derived by the seed script with percent-encoded credentials) |

## Bootstrap

```bash
cd beskid_infra
cp config/openbao-secrets.env.example config/openbao-secrets.env
export BAO_ADDR="https://secrets.bdziam.dev"
export OPENBAO_TOKEN="s...."

just seed-openbao-all
just seed-openbao-check
```

`bao login` requires `BAO_ADDR` with `https://`.

## Coolify sync

After OpenBao is populated:

```bash
just sync-env-prod    # explicit operator-only env synchronization
```

Which services are read is configured by `config/coolify-{lane}.json`.

## Rotation

```bash
bao kv patch secret/beskid/production/auth SESSION_SECRET="$(openssl rand -base64 32)"
just sync-env-prod
```

Redeploy the compose service if containers need a full restart.
