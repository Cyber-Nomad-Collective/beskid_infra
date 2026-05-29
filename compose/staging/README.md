# Staging compose (phase 2)

Staging (`stg` branch) is not migrated yet. When ready:

- Add `compose/staging/docker-compose.yml` (image tag `staging`, hostnames `stg.*` / `stg-auth.*`).
- Wire `.github/workflows/coolify-compose-deploy.yml` for the `stg` branch.
- Use a **separate** Coolify compose service, Postgres volume, and GitHub OAuth app (see superrepo `docs/staging-environment.md`).
