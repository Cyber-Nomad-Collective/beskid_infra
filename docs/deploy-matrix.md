# Coolify deploy matrix

Canonical reference for the **beskid-platform-production** compose service: public URLs, container ports, OpenBao secret paths, and shared auth variables. Operator workflow: [deploy-compose.md](deploy-compose.md) · secret layout: [openbao-layout.md](openbao-layout.md).

## Stack overview

| Layer | Responsibility |
| --- | --- |
| **GitHub Actions** (`container-images.yml`) | Build and push `ghcr.io/cyber-nomad-collective/beskid-*` |
| **OpenBao** (`https://secrets.bdziam.dev`) | Runtime secrets per service path |
| **CI** (`coolify-compose-deploy.yml`) | Sync OpenBao → Coolify env; PATCH compose; redeploy |
| **Coolify** | TLS proxy, volumes, compose runtime |

Compose source: [`compose/production/docker-compose.yml`](../compose/production/docker-compose.yml). Production config: [`config/coolify-production.json`](../config/coolify-production.json).

## Production services

Coolify **Domains** use explicit ports (`https://<host>:<port>`). App-facing `*_PUBLIC_URL` env values omit the port suffix.

| Service | GHCR image | Container port | Coolify URL | Public env URL |
| --- | --- | --- | --- | --- |
| **site** | `beskid-site` | 80 | `https://beskid-lang.org:80` | `https://beskid-lang.org` |
| **auth** | `beskid-auth` | 8090 | `https://auth.beskid-lang.org:8090` | `AUTH_HUB_PUBLIC_URL=https://auth.beskid-lang.org` |
| **platform-spec** | `beskid-platform-spec` | 8460 | `https://spec.beskid-lang.org:8460` | `PLATFORM_SPEC_PUBLIC_URL=https://spec.beskid-lang.org` |
| **memgraph** | `memgraph/memgraph-mage` | 7687 | internal only | `MEMGRAPH_URI=bolt://memgraph:7687` |
| **tracker** | `beskid-tracker` | 3000 | `https://tracker.beskid-lang.org:3000` | `TRACKER_PUBLIC_URL=https://tracker.beskid-lang.org` |
| **nexus** | `beskid-nexus` | 8452 | `https://nexus.beskid-lang.org:8452` | (pairing `publicUrl`) |
| **pckg** | `beskid-pckg` | 8082 | `https://pckg.beskid-lang.org:8082` | `PCKG_PUBLIC_URL=https://pckg.beskid-lang.org` |
| **postgres** | `postgres:16` | 5432 | internal only | — |
| **Grafana** | (Coolify **Beskid Monitoring**) | 3000 | `https://monitor.beskid-lang.org:3000` | internal `/metrics` via Alloy Docker SD |

Domains are applied from [`config/domains.json`](../config/domains.json) on deploy. See also [compose/production/README.md](../compose/production/README.md) and [observability.md](observability.md).

## Staging (reference — phase 2)

Staging hostnames use the `stg-` prefix (site apex: `stg.beskid-lang.org`).

| Service | Coolify URL |
| --- | --- |
| site | `https://stg.beskid-lang.org:80` |
| auth | `https://stg-auth.beskid-lang.org:8090` |
| tracker | `https://stg-tracker.beskid-lang.org:3000` |
| nexus | `https://stg-nexus.beskid-lang.org:8452` |
| pckg | `https://stg-pckg.beskid-lang.org:8082` |

OpenBao lane: `secret/beskid/staging/{service}`.

## OpenBao paths

| Service | KV path | Synced by CI |
| --- | --- | --- |
| site | `secret/beskid/production/site` | optional (`IMAGE_TAG` may be static) |
| auth | `secret/beskid/production/auth` | yes |
| platform-spec | `secret/beskid/production/platform-spec` | yes |
| tracker | `secret/beskid/production/tracker` | yes |
| nexus | `secret/beskid/production/nexus` | yes |
| pckg | `secret/beskid/production/pckg` | yes |

`openbao_services` in `coolify-production.json`: `auth`, `platform-spec`, `tracker`, `nexus`, `pckg`.

## Shared auth secrets

The [auth hub](https://github.com/Cyber-Nomad-Collective/beskid/blob/main/site/auth/COOLIFY.md) is the **only** GitHub OAuth app. Platform spec: [beskid-lang.org/platform-spec/tooling/auth-hub/](https://beskid-lang.org/platform-spec/tooling/auth-hub/).

| Secret / variable | Where set | Shared across services? |
| --- | --- | --- |
| `AUTH_HUB_PUBLIC_URL` | auth static env + OpenBao on consumers | **yes** — same hub URL on auth, tracker, nexus, pckg |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | OpenBao `…/auth` only | **hub only** — consumers must not receive these |
| `SESSION_SECRET` | OpenBao per service | **no** — distinct value per auth / tracker / nexus (and pckg if session-backed) |
| Service token (pairing) | Consumer runtime config after pairing | **no** — per-app secret from hub pairing |
| `GITHUB_SYNC_TOKEN` | OpenBao tracker / pckg | optional — autopair and background sync |

**Deprecated:** `AUTH_HUB_SECRET` (legacy shared handoff). New deployments use per-app service tokens from pairing.

### Per-service OpenBao keys (summary)

| Service | Required keys |
| --- | --- |
| **auth** | `SESSION_SECRET`, `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, `AUTH_HUB_PUBLIC_URL`, `IMAGE_TAG` |
| **tracker** | `AUTH_HUB_PUBLIC_URL`, `SESSION_SECRET`, `TRACKER_PUBLIC_URL`; recommended: `GITHUB_SYNC_TOKEN`, `TRACKER_PAIRING_APPROVER_LOGIN` |
| **nexus** | `GITNEXUS_HOME`, `AUTH_HUB_PUBLIC_URL`, `SESSION_SECRET` |
| **pckg** | `POSTGRES_PASSWORD`, `AUTH_HUB_PUBLIC_URL`, `IMAGE_TAG`; recommended: `PCKG_PUBLIC_URL`, `GITHUB_SYNC_TOKEN` |

Full key tables: [openbao-layout.md](openbao-layout.md).

## Service operator docs

| Service | COOLIFY.md |
| --- | --- |
| site | [site/COOLIFY.md](https://github.com/Cyber-Nomad-Collective/beskid/blob/main/site/COOLIFY.md) |
| auth | [site/auth/COOLIFY.md](https://github.com/Cyber-Nomad-Collective/beskid/blob/main/site/auth/COOLIFY.md) |
| tracker | [beskid_tracker/COOLIFY.md](https://github.com/Cyber-Nomad-Collective/beskid_tracker/blob/main/COOLIFY.md) |
| nexus | [beskid_nexus/COOLIFY.md](https://github.com/Cyber-Nomad-Collective/beskid_nexus/blob/main/COOLIFY.md) |
| pckg | [pckg/COOLIFY.md](https://github.com/Cyber-Nomad-Collective/pckg/blob/main/COOLIFY.md) |

## Compose profiles and volumes

Production enables tracker, nexus, and pckg via `compose_profiles: tracker,nexus,pckg`.

| Volume | Mount |
| --- | --- |
| `auth-data` | Hub SQLite (`/app/site/auth/data/runtime`) |
| `tracker-data` | Tracker SQLite (`/app/beskid_tracker/data/runtime`) |
| `nexus-data` | `GITNEXUS_HOME` (`/data/gitnexus`) |
| `pckg_pg_data` | Postgres data |
| `pckg_packages`, `pckg_data` | Registry artifacts |

## Verification checklist (operator)

These steps require production access (OpenBao token, Coolify, GitHub repo admin). Do not mark production-only tracker tasks Done without evidence.

1. `just seed-openbao-check` — all required keys present for `auth`, `platform-spec`, `tracker`, `nexus`, `pckg`
2. `just sync-env-prod` — Coolify env matches OpenBao
3. Health: `curl` each service `/api/health` or documented health endpoint
4. Auth: OAuth sign-in on tracker, nexus, and pckg via hub return-path cookie
5. Tracker: GitHub webhook `POST /api/webhooks/github` with `GITHUB_WEBHOOK_SECRET`
6. Nexus: catalog analyze smoke on production graph
