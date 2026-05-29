# Production platform compose (Coolify)

Single Coolify **compose** service (`beskid-platform-production`) runs this file. GHCR images are built by the superrepo `container-images` workflow.

Domains are applied on deploy from [`config/domains.json`](../../config/domains.json) (`production` lane) as Coolify `urls` (`https://<host>:<port>` per compose service).

## Domains (production / `main`)

| Compose service | Coolify URL |
|-----------------|-------------|
| site | `https://beskid-lang.org:80` |
| auth | `https://auth.beskid-lang.org:8090` |
| tracker | `https://tracker.beskid-lang.org:3000` |
| nexus | `https://nexus.beskid-lang.org:8452` |
| pckg | `https://pckg.beskid-lang.org:8082` |

App-facing public URLs in env (no port suffix): `https://auth.beskid-lang.org`, `https://tracker.beskid-lang.org`, etc.

## Staging (`stg`) — reference

Staging uses the `stg-` hostname pattern (site apex: `stg.beskid-lang.org`):

| Compose service | Coolify URL |
|-----------------|-------------|
| site | `https://stg.beskid-lang.org:80` |
| auth | `https://stg-auth.beskid-lang.org:8090` |
| tracker | `https://stg-tracker.beskid-lang.org:3000` |
| nexus | `https://stg-nexus.beskid-lang.org:8452` |
| pckg | `https://stg-pckg.beskid-lang.org:8082` |

See [`compose/staging/README.md`](../staging/README.md) when staging compose is enabled.

## Compose profiles

Production enables **site**, **auth**, **tracker**, **nexus**, and **pckg** (with Postgres) via `compose_profiles: tracker,nexus,pckg` in [`config/coolify-production.json`](../../config/coolify-production.json). OpenBao must be seeded for `auth`, `tracker`, `nexus`, and `pckg` (`just seed-openbao-all`).

## Volumes

| Volume | Mount | Legacy Coolify app volume name |
|--------|-------|--------------------------------|
| auth-data | auth runtime | `auth-data` on `beskid-auth` |
| tracker-data | tracker runtime | `tracker-data` |
| nexus-data | GitNexus home | `nexus-data` |
| pckg_pg_data | Postgres data | separate per environment |
| pckg_packages, pckg_data | pckg storage | `beskid-pckg-packages`, `beskid-pckg-data` |

During cutover, attach existing Coolify persistent volumes to these names in the UI when possible.

## Operator cutover

1. Record compose service UUID in `config/coolify-production.json` after first create.
2. Migrate volumes from legacy per-app resources (see [docs/deploy-compose.md](../../docs/deploy-compose.md)).
3. Smoke-test auth hub OAuth and site.
4. Remove legacy `beskid-site`, `beskid-auth`, etc. applications to avoid duplicate routes.

## Local validation

```bash
cd beskid_infra/compose/production
cp .env.example .env
docker compose config
```
