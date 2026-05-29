# Staging compose (phase 2)

Staging (`stg` branch) is not deployed yet. Hostnames and Coolify URLs are defined in [`config/domains.json`](../../config/domains.json) (`staging` lane).

## Domains (staging / `stg`)

| Compose service | Coolify URL |
|-----------------|-------------|
| site | `https://stg.beskid-lang.org:80` |
| auth | `https://stg-auth.beskid-lang.org:8090` |
| tracker | `https://stg-tracker.beskid-lang.org:3000` |
| nexus | `https://stg-nexus.beskid-lang.org:8452` |
| pckg | `https://stg-pckg.beskid-lang.org:8082` |

Site uses `stg.` on the apex; other services use the `stg-` prefix before the service name (same as [deploy-matrix.md](../../docs/deploy-matrix.md)).

## When ready

- Add `compose/staging/docker-compose.yml` (image tag `staging`).
- Add `config/coolify-staging.json` mirroring production.
- Wire `.github/workflows/coolify-compose-deploy.yml` for the `stg` branch.
- Separate Postgres volume and GitHub OAuth app (see superrepo `docs/staging-environment.md`).
