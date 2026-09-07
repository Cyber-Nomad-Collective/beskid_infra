# Production platform compose (Coolify)

The `beskid-platform-production` Coolify service runs a digest-rendered form of
this template. GHCR images are built once by `platform-delivery.yml`.

Domains are applied on deploy from [`config/domains.json`](../../config/domains.json) (`production` lane) as Coolify target `urls` (`https://<host>:<container-port>` per compose service). Public health and API requests use each service's separate standard-HTTPS `public_url`.

## Domains (production / `main`)

| Compose service | Coolify URL |
|-----------------|-------------|
| site | `https://beskid-lang.org:80` |
| auth | `https://auth.beskid-lang.org:8090` |
| learn | required service; domain is applied by the configured Coolify lane |
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
| learn | required service; domain is applied by the configured Coolify lane |
| tracker | `https://stg-tracker.beskid-lang.org:3000` |
| nexus | `https://stg-nexus.beskid-lang.org:8452` |
| pckg | `https://stg-pckg.beskid-lang.org:8082` |

See [`compose/staging/README.md`](../staging/README.md). Staging is a separate
Coolify service consuming the same immutable manifest format.

## Compose profiles

Production starts **site**, **auth**, and **learn** by default; it enables
**tracker**, **nexus**, and **pckg** (with Postgres) via
`compose_profiles: tracker,nexus,pckg` in
[`config/coolify-production.json`](../../config/coolify-production.json). These
six application lanes are the complete release topology. Learn is required
because its configured lane smoke URL must be healthy after every deployment.
OpenBao is not required for learn's current documented configuration.

## Volumes

| Volume | Mount | Legacy Coolify app volume name |
|--------|-------|--------------------------------|
| auth-data | auth runtime | `auth-data` on `beskid-auth` |
| tracker-data | tracker runtime | `tracker-data` |
| nexus-data | GitNexus home | `nexus-data` |
| pckg_pg_data | Postgres data | separate per environment |
| pckg_packages | pckg artifacts (`/app/packages`) | `beskid-pckg-packages` |

During cutover, attach existing Coolify persistent volumes to these names in the UI when possible.

## pckg authentication

The Rust pckg service is deployed without `SHELL_AUTH_MODE`. It does not
create or validate browser sessions itself, and the production Compose file
must not trust client-supplied `Remote-*` headers. Until Coolify has a verified
forward-auth boundary that strips those headers, validates the request with
Authelia, and preserves bearer authorization for package publishing, session
management and authenticated registry mutations remain disabled. Public
catalogue, download, and readiness endpoints may be served normally.

`PCKG_DATABASE_URL` is a required canonical OpenBao/Coolify secret. The
OpenBao seed script derives it from its single PostgreSQL configuration source
and percent-encodes user, password, and database components; Compose never
constructs a URL from password fragments. The local `.env.example` uses a
non-secret dummy URL only for `docker compose config` validation.

`PCKG_RELEASE_PUBLISHER_KEY_SHA256` is also required. GitHub hashes the
release-only bearer key before environment synchronization, so Coolify and the
registry receive only the digest used to reconcile the deterministic release
publisher row.

## Local validation

```bash
cd beskid_infra/compose/production
BESKID_RELEASE_TAG=validation docker compose --env-file .env.example config
```
