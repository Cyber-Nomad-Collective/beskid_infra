# Deploy matrix

| Service | GHCR image | production (`main`) | staging (`stg`) | Port |
|---------|-----------|---------------------|-----------------|------|
| **site** | `beskid-site` | `beskid-lang.org` | `stg.beskid-lang.org` | 80 |
| **auth** | `beskid-auth` | `auth.beskid-lang.org` | `stg-auth.beskid-lang.org` | 8090 |
| **tracker** | `beskid-tracker` | `tracker.beskid-lang.org` | `stg-tracker.beskid-lang.org` | 3000 |
| **nexus** | `beskid-nexus` | `nexus.beskid-lang.org` | `stg-nexus.beskid-lang.org` | 8452 |
| **pckg** | `beskid-pckg` | `pckg.beskid-lang.org` | `stg-pckg.beskid-lang.org` | 8082 |

Image tags: `main` on production, `staging` on staging.

## Git branch → OpenTofu

| Branch | Environment root | Coolify env | OpenBao `secret/beskid/tofu/` |
|--------|------------------|-------------|-------------------------------|
| `main` | `environments/production` | `production` | `production` |
| `stg` | `environments/staging` | `staging` | `staging` |

## Coolify (existing production UUIDs)

| App | UUID | Import |
|-----|------|--------|
| beskid site | `rsso488sscg80kookoo00sk4` | `module.stack.module.apps["site"]` |
| Pckg (legacy compose) | `fotldmgwdsxttpde914u8ktr` | migrate to `module.stack.module.pckg` |
| Nexus | `rc7pssssk5i3vqjrt1anx4y3` | `module.stack.module.apps["nexus"]` |
| Tracker | `s8voih0gwkrftklgsmxqglo4` | `module.stack.module.apps["tracker"]` |

Project `tosg8kc80g8go00sgcswsccg` · Server `ec0cs0cw0ocsok488gc0k80k`.

## GHCR

Built by `.github/workflows/container-images.yml` in the `beskid` superrepo (and per-service repos when split).

## DNS

Point each hostname (or `*.beskid-lang.org` + single-level subdomains) to the Coolify server IP. Let's Encrypt via Coolify proxy — ports 80/443 open.

## Volumes

| Service | Volume | Mount |
|---------|--------|-------|
| auth | `auth-data` | `/app/site/auth/data/runtime` |
| tracker | `tracker-data` | `/app/beskid_tracker/data/runtime` |
| nexus | `nexus-data` | `/data/gitnexus` |
| pckg | `*-packages`, `*-data` | `/app/packages`, `/app/data` |
| pckg DB | Coolify PostgreSQL resource | — |
