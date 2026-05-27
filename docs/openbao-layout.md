# OpenBao secret layout

All runtime secrets for the Beskid platform live in OpenBao KV v2 at `secret/beskid/`.
OpenTofu reads these at `tofu apply` time to populate Coolify environment variables.
No secret values are committed to this repository.

## Path hierarchy

```
secret/
  beskid/
    production/
      site/          # beskid-lang.org
      auth/          # auth.beskid-lang.org
      tracker/       # tracker.beskid-lang.org (future)
      nexus/         # nexus.beskid-lang.org (future)
      pckg/          # pckg.beskid-lang.org (future)
    staging/
      site/
      auth/
      tracker/
      nexus/
      pckg/
    ci/
      build/         # NODE_AUTH_TOKEN for GHCR push
      open-vsx/      # OVSX_TOKEN
```

## Per-service secrets

### site (beskid-lang.org)

| Key | Required | Notes |
|-----|----------|-------|
| `PUBLIC_GISCUS_REPO` | no | GitHub Discussions integration |
| `PUBLIC_GISCUS_REPO_ID` | no | |
| `PUBLIC_GISCUS_CATEGORY` | no | |
| `PUBLIC_GISCUS_CATEGORY_ID` | no | |

### auth (auth.beskid-lang.org)

| Key | Required | Notes |
|-----|----------|-------|
| `AUTH_HUB_PUBLIC_URL` | yes | `https://auth.beskid-lang.org` |
| `SESSION_SECRET` | yes | 32+ random chars |
| `GITHUB_CLIENT_ID` | yes* | GitHub OAuth app |
| `GITHUB_CLIENT_SECRET` | yes* | |
| `GITHUB_OAUTH_CALLBACK_URL` | yes* | `https://auth.beskid-lang.org/callback` |
| `AUTH_SETUP_TOKEN` | recommended | First-run onboarding |
| `AUTH_DATA_DIR` | no | Default: `data/runtime` |
| `PORT` | no | Default: `8090` |
| `IMAGE_TAG` | yes | `main` or `staging` |

*OAuth credentials can alternatively be saved via `/onboarding` into SQLite (encrypted with `SESSION_SECRET`).

### tracker (tracker.beskid-lang.org) — future

| Key | Required | Notes |
|-----|----------|-------|
| `AUTH_HUB_PUBLIC_URL` | yes | Hub URL for OAuth handoff |
| `AUTH_HUB_SERVICE_TOKEN` | yes | From hub pairing |

### nexus (nexus.beskid-lang.org) — future

| Key | Required | Notes |
|-----|----------|-------|
| `GITNEXUS_HOME` | yes | Persistent volume path |
| `AUTH_HUB_PUBLIC_URL` | yes | |
| `AUTH_HUB_SERVICE_TOKEN` | yes | |

### pckg (pckg.beskid-lang.org) — future

| Key | Required | Notes |
|-----|----------|-------|
| `ConnectionStrings__Default` | yes | Postgres connection string |
| `AUTH_HUB_PUBLIC_URL` | yes | |
| `AUTH_HUB_SERVICE_TOKEN` | yes | |
| `Pckg__Database__AutoMigrateOnStartup` | yes | `true` in production |

### ci/build

| Key | Required | Notes |
|-----|----------|-------|
| `NODE_AUTH_TOKEN` | yes | GitHub PAT with `read:packages` for `@cyber-nomad-collective` |
| `OVSX_TOKEN` | no | Open VSX publish token |

## Bootstrap with bao CLI

```bash
# Enable KV v2 at secret/ (should already exist)
bao secrets enable -path=secret kv-v2

# Production secrets
bao kv put secret/beskid/production/auth \
  AUTH_HUB_PUBLIC_URL="https://auth.beskid-lang.org" \
  SESSION_SECRET="$(openssl rand -base64 32)" \
  IMAGE_TAG="main"

bao kv put secret/beskid/production/site \
  IMAGE_TAG="main"

# Staging secrets — isolated from production
bao kv put secret/beskid/staging/auth \
  AUTH_HUB_PUBLIC_URL="https://auth-staging.example.com" \
  SESSION_SECRET="$(openssl rand -base64 32)" \
  IMAGE_TAG="staging"

bao kv put secret/beskid/staging/site \
  IMAGE_TAG="staging"

# CI secrets
bao kv put secret/beskid/ci/build \
  NODE_AUTH_TOKEN="ghp_..."

# Verify
bao kv get secret/beskid/production/auth
```

## OpenTofu integration

In `main.tf`, secrets are read at apply time:

```hcl
data "openbao_kv_secret_v2" "auth_secrets" {
  path = "secret/beskid/production/auth"
}

# Pass to Coolify env vars
env_vars = data.openbao_kv_secret_v2.auth_secrets.data
```

## Secret rotation

```bash
# Rotate a single key
bao kv patch secret/beskid/production/auth SESSION_SECRET="$(openssl rand -base64 32)"

# Rotate all secrets for a service
bao kv put secret/beskid/production/auth \
  AUTH_HUB_PUBLIC_URL="https://auth.beskid-lang.org" \
  SESSION_SECRET="$(openssl rand -base64 32)" \
  GITHUB_CLIENT_ID="..." \
  GITHUB_CLIENT_SECRET="..." \
  IMAGE_TAG="main"

# Redeploy to pick up new secrets
tofu apply
```
