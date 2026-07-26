# Production platform compose (Coolify)

The `beskid-platform-production` Coolify service runs a digest-rendered form of
this template. GHCR images are built once by `platform-delivery.yml`.

Domains are applied on deploy from [`config/domains.json`](../../config/domains.json) (`production` lane) as Coolify `urls` (`https://<host>:<port>` per compose service).

## Domains (production / `main`)

| Compose service | Coolify URL |
|-----------------|-------------|
| site | `https://beskid-lang.org:80` |
| auth | `https://auth.beskid-lang.org:8090` |
| learn | profile-gated; configure a domain before public exposure |
| tracker | `https://tracker.beskid-lang.org:3000` |
| nexus | `https://nexus.beskid-lang.org:8452` |
| pckg | `https://pckg.beskid-lang.org:8082` |

App-facing public URLs in env (no port suffix): `https://auth.beskid-lang.org`, `https://tracker.beskid-lang.org`, etc.

## Staging

Staging uses the `stg-` hostname pattern (site apex: `stg.beskid-lang.org`):

| Compose service | Coolify URL |
|-----------------|-------------|
| site | `https://stg.beskid-lang.org:80` |
| auth | `https://stg-auth.beskid-lang.org:8090` |
| learn | profile-gated; configure a domain before public exposure |
| tracker | `https://stg-tracker.beskid-lang.org:3000` |
| nexus | `https://stg-nexus.beskid-lang.org:8452` |
| pckg | `https://stg-pckg.beskid-lang.org:8082` |

See [`compose/staging/README.md`](../staging/README.md). Staging is a separate
Coolify service consuming the same immutable manifest format.

## Compose profiles

Production enables **site**, **auth**, **tracker**, **nexus**, and **pckg** (with Postgres) via `compose_profiles: tracker,nexus,pckg` in [`config/coolify-production.json`](../../config/coolify-production.json). The canonical `learn` image is represented by the `learn` profile so every release manifest maps it to one service; an operator must explicitly add its public domain and enable that profile before public exposure. OpenBao is not required for learn's current documented configuration.

## Volumes

| Volume | Mount | Legacy Coolify app volume name |
|--------|-------|--------------------------------|
| auth-data | auth runtime | `auth-data` on `beskid-auth` |
| tracker-data | tracker runtime | `tracker-data` |
| nexus-data | GitNexus home | `nexus-data` |
| pckg_pg_data | Postgres data | separate per environment |
| pckg_packages, pckg_data | pckg artifacts + uploads (`/app/packages`, `/app/data`) | `beskid-pckg-packages`, `beskid-pckg-data` |

During cutover, attach existing Coolify persistent volumes to these names in the UI when possible.

## Local validation

```bash
cd beskid_infra/compose/production
cp .env.example .env
BESKID_RELEASE_TAG=validation docker compose config
```
