# Deploy matrix

| Service | GHCR image | production (`main`) | staging (`stg`, phase 2) | Port |
|---------|-----------|---------------------|--------------------------|------|
| **site** | `beskid-site` | `beskid-lang.org` | `stg.beskid-lang.org` | 80 |
| **auth** | `beskid-auth` | `auth.beskid-lang.org` | `stg-auth.beskid-lang.org` | 8090 |
| **tracker** | `beskid-tracker` | `tracker.beskid-lang.org` | `stg-tracker.beskid-lang.org` | 3000 |
| **nexus** | `beskid-nexus` | `nexus.beskid-lang.org` | `stg-nexus.beskid-lang.org` | 8452 |
| **pckg** | `beskid-pckg` | `pckg.beskid-lang.org` | `stg-pckg.beskid-lang.org` | 8082 |

Image tags: `main` on production, `staging` on staging.

## Git branch → deploy

| Branch | Compose root | Coolify env | OpenBao `secret/beskid/` |
|--------|--------------|-------------|--------------------------|
| `main` | `compose/production/` | `production` | `production/{service}` |
| `stg` | (phase 2) `compose/staging/` | `staging` | `staging/{service}` |

## Coolify (production compose service)

| Resource | Notes |
|----------|--------|
| Compose service | `beskid-platform-production` — UUID in `config/coolify-production.json` |
| Project | **Beskid** — UUID in `config/coolify.snapshot.json` |
| Server | `localhost` — `ec0cs0cw0ocsok488gc0k80k` |
| Destination | coolify network — `zss4wkockgw8gok888gscc84` |

Legacy per-app UUIDs (decommission after cutover): see `config/coolify.snapshot.json` → `legacy_applications`.

## GHCR

Built by `.github/workflows/container-images.yml` in the `beskid` superrepo.

## DNS

Point each hostname to the Coolify server IP. Let's Encrypt via Coolify proxy — ports 80/443 open.

## Volumes

| Service | Volume | Mount |
|---------|--------|-------|
| auth | `auth-data` | `/app/site/auth/data/runtime` |
| tracker | `tracker-data` | `/app/beskid_tracker/data/runtime` |
| nexus | `nexus-data` | `/data/gitnexus` |
| pckg | `pckg_packages`, `pckg_data` | `/app/packages`, `/app/data` |
| pckg DB | `pckg_pg_data` | Postgres data (in-compose) |

## CI

Push to `main` → **Beskid platform** → GHCR build → `coolify-compose-deploy.yml` (OpenBao sync + compose deploy).

See [deploy-compose.md](deploy-compose.md) and [observability.md](observability.md).
