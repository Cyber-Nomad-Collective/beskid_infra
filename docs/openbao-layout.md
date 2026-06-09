# OpenBao secret layout

Runtime secrets live in OpenBao KV v2 at **`https://secrets.bdziam.dev`**. CI and local deploy sync them into the Coolify compose service via [`scripts/coolify-sync-env-from-openbao.sh`](../scripts/coolify-sync-env-from-openbao.sh).

| Lane | KV prefix |
|------|-----------|
| production | `secret/beskid/production/{service}` |
| staging | `secret/beskid/staging/{service}` |

## Path hierarchy

```
secret/
  beskid/
    production/   site, auth, platform-spec, tracker, nexus, pckg
    staging/      site, auth, platform-spec, tracker, nexus, pckg
    ci/
      build/        NODE_AUTH_TOKEN, OVSX_TOKEN
```

## Per-service keys

### site

| Key | Required |
|-----|----------|
| `IMAGE_TAG` | yes (`main` / `staging`) — also set in `coolify-production.json` `static_env` |
| `PUBLIC_GISCUS_*` | no |

Compose deploy reads **auth**, **platform-spec**, **tracker**, **nexus**, and **pckg** from OpenBao (`openbao_services` in `coolify-production.json`). `site` KV is optional if `IMAGE_TAG` is in `static_env`. Run `just seed-openbao-all` before the first full-stack deploy.

### auth

| Key | Required |
|-----|----------|
| `AUTH_HUB_PUBLIC_URL` | yes (also set in `coolify-production.json` static_env) |
| `SESSION_SECRET` | yes |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | yes* |
| `IMAGE_TAG` | yes |

### platform-spec

| Key | Required |
|-----|----------|
| `AUTH_HUB_PUBLIC_URL` | yes |
| `SESSION_SECRET` | yes |
| `PLATFORM_SPEC_PUBLIC_URL` | yes (`https://spec.beskid-lang.org`) |
| `MEMGRAPH_URI` | yes (`bolt://memgraph:7687` in compose) |
| `GITHUB_SYNC_TOKEN` | yes (git clone sync + PR workflow) |
| `GITHUB_WEBHOOK_SECRET` | recommended (PR merge webhook) |
| `SPEC_GIT_REPO_URL` | recommended (`https://github.com/Cyber-Nomad-Collective/beskid`) |
| `SPEC_GIT_REF` | optional (default `main`) |
| `SPEC_SYNC_MODE` | optional (`json` or `mdx-legacy`) |
| `PLATFORM_SPEC_MODERATOR_LOGINS` | recommended (comma-separated GitHub logins) |
| `PLATFORM_SPEC_PAIRING_APPROVER_LOGIN` | recommended |

### tracker

| Key | Required |
|-----|----------|
| `AUTH_HUB_PUBLIC_URL` | yes |
| `SESSION_SECRET` | yes |
| `TRACKER_PUBLIC_URL` | yes |
| `GITHUB_SYNC_TOKEN` | recommended (autopair via GitHub API) |
| `TRACKER_PAIRING_APPROVER_LOGIN` | recommended (autopair without sync token; same pattern as pckg `PCKG_PAIRING_APPROVER_LOGIN`) |

### nexus

| Key | Required |
|-----|----------|
| `GITNEXUS_HOME` | yes (`/data/gitnexus`) |
| `AUTH_HUB_PUBLIC_URL` | yes |
| `SESSION_SECRET` | yes |
| `OPENROUTER_API_KEY` | no (enables server-side code-doc maintenance) |
| `NEXUS_DOC_MODEL` | no |
| `NEXUS_SPEC_ROOT` | no (path to platform-spec MDX for spec link index) |

### pckg

| Key | Required |
|-----|----------|
| `POSTGRES_PASSWORD` | yes |
| `POSTGRES_DB`, `POSTGRES_USER` | recommended |
| `AUTH_HUB_PUBLIC_URL` | yes |
| `PCKG_PUBLIC_URL` | recommended |
| `GITHUB_SYNC_TOKEN` | recommended |
| `IMAGE_TAG` | yes |

## Bootstrap

```bash
cd beskid_infra
cp config/openbao-secrets.env.example config/openbao-secrets.env
export BAO_ADDR="https://secrets.bdziam.dev"
export OPENBAO_TOKEN="s...."

just seed-openbao-all
just seed-openbao-check
```

`bao login` requires `BAO_ADDR` with `https://`.

## Coolify sync

After OpenBao is populated:

```bash
just sync-env-prod    # PATCH /api/v1/services/{uuid}/envs/bulk
just deploy-prod      # optional: update compose + redeploy
```

Which services are read is configured in `config/coolify-production.json` → `openbao_services`.

## Rotation

```bash
bao kv patch secret/beskid/production/auth SESSION_SECRET="$(openssl rand -base64 32)"
just sync-env-prod
```

Redeploy the compose service if containers need a full restart.
