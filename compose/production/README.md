# Production platform compose (Coolify)

Single Coolify **compose** service (`beskid-platform-production`) runs this file. GHCR images are built by the superrepo `container-images` workflow.

## Domains (Coolify UI)

Pin each compose service to its production FQDN in the Coolify service **Domains** tab:

| Compose service | FQDN |
|-----------------|------|
| site | `beskid-lang.org` |
| auth | `auth.beskid-lang.org` |
| tracker | `tracker.beskid-lang.org` |
| nexus | `nexus.beskid-lang.org` |
| pckg | `pckg.beskid-lang.org` |

Coolify may auto-assign `SERVICE_FQDN_*` hostnames during first deploy; replace them with the table above before cutover.

## Optional services

Default production enables **site** and **auth** only. To enable tracker, nexus, or pckg:

1. Set `compose_profiles` in [`config/coolify-production.json`](../../config/coolify-production.json) (e.g. `tracker,nexus,pckg`).
2. Add matching OpenBao paths under `secret/beskid/production/{tracker,nexus,pckg}`.
3. Run `just sync-env-prod` then `just deploy-prod`.

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
2. Migrate volumes and domains from legacy per-app resources (see [docs/deploy-compose.md](../../docs/deploy-compose.md)).
3. Smoke-test auth hub OAuth and site.
4. Remove legacy `beskid-site`, `beskid-auth`, etc. applications to avoid duplicate routes.

## Local validation

```bash
cd beskid_infra/compose/production
cp .env.example .env
docker compose config
```
