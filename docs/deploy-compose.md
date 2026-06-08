# Coolify Compose deploy (production)

The Beskid platform runs as **one Coolify compose service** per environment. Source of truth: [`compose/production/docker-compose.yml`](../compose/production/docker-compose.yml).

| Layer | Responsibility |
|-------|----------------|
| **GitHub Actions** (`container-images.yml`) | Build and push `ghcr.io/cyber-nomad-collective/beskid-*` |
| **OpenBao** (`https://secrets.bdziam.dev`) | Runtime secrets per service path |
| **CI** (`coolify-compose-deploy.yml`) | Sync OpenBao → Coolify env; PATCH compose; redeploy |
| **Coolify** | TLS proxy, volumes, compose runtime |

OpenTofu and the vendored Coolify Terraform provider are **removed**.

Service URL and secret matrix: [deploy-matrix.md](deploy-matrix.md).

## Prerequisites

- Coolify project **Beskid**, environment **production**
- GitHub variables: `COOLIFY_ENDPOINT`, `COOLIFY_SERVER_UUID`, `COOLIFY_DESTINATION_UUID`
- GitHub secrets: `COOLIFY_API_TOKEN`, `OPENBAO_TOKEN`
- OpenBao paths seeded: `just seed-openbao-all` (see [openbao-layout.md](openbao-layout.md))

## First-time production setup

```bash
cd beskid_infra
cp .env.example .env
# Set COOLIFY_API_TOKEN, OPENBAO_TOKEN (or use config/openbao-secrets.env)

just config-init
just compose-config          # validate YAML locally
just deploy-prod             # create/update compose service + sync env + deploy
```

After first create, commit `service_uuid` in [`config/coolify-production.json`](../config/coolify-production.json).

## Domains and volumes

Production and staging Coolify URLs (`https://host:port`) live in [`config/domains.json`](../config/domains.json). `coolify-deploy-compose.sh` sends them as the Coolify `urls` array on create/update.

See [compose/production/README.md](../compose/production/README.md) for the full table and volume adoption from legacy per-app resources.

## Compose profiles

Production runs the full stack via `compose_profiles: "tracker,nexus,pckg"` in [`config/coolify-production.json`](../config/coolify-production.json). OpenBao paths must exist for every entry in `openbao_services` (`auth`, `tracker`, `nexus`, `pckg`). Seed with `just seed-openbao-all`, then CI syncs env and redeploys.

## Local commands

| Command | Purpose |
|---------|---------|
| `just compose-config` | `docker compose config` validation |
| `just sync-env-prod` | OpenBao → Coolify env only |
| `just deploy-prod` | Full compose create/update + deploy |
| `just openbao-check-prod` | Audit OpenBao keys (no Coolify writes) |

## Staging (phase 2)

Not automated on `stg` yet. See [compose/staging/README.md](../compose/staging/README.md).

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `docker_compose_raw` 422 | Compose file must be valid YAML; API expects base64 body (handled by `coolify-deploy-compose.sh`) |
| PATCH service 422 (`project_uuid` not allowed) | Update sends only `docker_compose_raw`, `urls`, `force_domain_override` — not create-only fields |
| `Server has multiple destinations` | Set `COOLIFY_DESTINATION_UUID` (see `config/coolify.snapshot.json`) |
| Service not found | Run `just deploy-prod` once; set `service_uuid` in config |
| Auth OAuth redirect mismatch | `AUTH_HUB_PUBLIC_URL` must match Coolify domain on **auth** service |
| Duplicate routes | Remove legacy `beskid-site`, `beskid-auth`, … **applications** after cutover |
| Degraded / `No such container: tracker-…` | Set `compose_profiles` to `tracker,nexus,pckg` and sync OpenBao for all `openbao_services`, then redeploy. |
