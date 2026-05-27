# Deploy matrix

Which service runs where, and how it gets deployed.

| Service | GHCR image | Production | Staging | Compose |
|---------|-----------|------------|---------|---------|
| **beskid-site** | `ghcr.io/cyber-nomad-collective/beskid-site:main` | `beskid-lang.org` | auto-domain | `site/docker-compose.yml` |
| **beskid-auth** | `ghcr.io/cyber-nomad-collective/beskid-auth:main` | `auth.beskid-lang.org` | auto-domain | `site/auth/docker-compose.yml` |
| **beskid-tracker** | (future) `ghcr.io/.../beskid-tracker:main` | `tracker.beskid-lang.org` | — | `beskid_tracker/docker-compose.coolify.yml` |
| **beskid-nexus** | (future) `ghcr.io/.../beskid-nexus:main` | `nexus.beskid-lang.org` | — | `beskid_nexus/docker-compose.coolify.yml` |
| **beskid-pckg** | (future) `ghcr.io/.../beskid-pckg:main` | `pckg.beskid-lang.org` | — | `pckg/docker-compose.coolify.yml` |

## Coolify map

| App | UUID | Managed by | Import command |
|-----|------|-----------|----------------|
| `beskid-site` | `rsso488sscg80kookoo00sk4` | OpenTofu | `tofu import module.beskid_site.coolify_application.app rsso488sscg80kookoo00sk4` |
| `beskid-auth` | (new) | OpenTofu | Created by `tofu apply` |

## GHCR images

| Image | Tags | Built by |
|-------|------|----------|
| `beskid-site` | `main`, `staging`, `sha-*` | `.github/workflows/container-images.yml` in `beskid` |
| `beskid-auth` | `main`, `staging`, `sha-*` | `.github/workflows/container-images.yml` in `beskid` |

## DNS

| Domain | Points to |
|--------|-----------|
| `beskid-lang.org` | Coolify server IP |
| `auth.beskid-lang.org` | Coolify server IP |
| `*.beskid-lang.org` | Coolify server IP (wildcard) |

## Volume map

| Service | Volume | Path in container |
|---------|--------|-------------------|
| auth | `auth-data` | `/app/site/auth/data/runtime` |
| pckg (future) | `pckg-pg-data` | Postgres data |
| tracker (future) | `tracker-data` | SQLite / app data |
| nexus (future) | `nexus-data` | `GITNEXUS_HOME` |
