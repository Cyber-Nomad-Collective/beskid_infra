# Bootstrap guide

Step-by-step instructions to go from empty `beskid_infra` to OpenTofu-managed Coolify apps.

## Prerequisites

- [ ] Coolify instance running and accessible
- [ ] Coolify API token with admin scope (Settings → API)
- [ ] OpenBao cluster running (or skip OpenBao for now — use GitHub Secrets)
- [ ] OpenTofu CLI v1.8+ installed locally
- [ ] Push access to `Cyber-Nomad-Collective/beskid_infra`

## Step 0: Clone and prepare

```bash
git clone https://github.com/Cyber-Nomad-Collective/beskid_infra.git
cd beskid_infra
```

## Step 1: Get Coolify resource UUIDs

In the Coolify UI or API, note these UUIDs:

```bash
# From the Coolify dashboard → Projects → Beskid → Settings
PROJECT_UUID="tosg8kc80g8go00sgcswsccg"

# From Servers → localhost → Settings
SERVER_UUID="ec0cs0cw0ocsok488gc0k80k"

# Existing app UUID (beskid site)
SITE_APP_UUID="rsso488sscg80kookoo00sk4"

# GitHub App UUID (Settings → GitHub Apps → cyber-nomad-cooliify)
GITHUB_APP_UUID="w4sckcs4cw8w4sgkgs0ko8oc"
```

## Step 2: Generate Coolify API token

1. Coolify UI → Settings → API tokens
2. Create token with scope: **admin** (needed for read + write + deploy)
3. Save it: `tcp-...`

## Step 3: Set up OpenBao (skip if not ready)

If OpenBao is running:

```bash
export BAO_ADDR="https://bao.your-domain.com:8200"
export BAO_TOKEN="hvs.root-or-admin-token"

# Enable KV v2 if not already enabled
bao secrets enable -path=secret kv-v2 || echo "already enabled"

# Populate production secrets
bao kv put secret/beskid/production/site \
  IMAGE_TAG="main"

bao kv put secret/beskid/production/auth \
  AUTH_HUB_PUBLIC_URL="https://auth.beskid-lang.org" \
  SESSION_SECRET="$(openssl rand -base64 32)" \
  IMAGE_TAG="main"

# Verify
bao kv get secret/beskid/production/auth
```

If OpenBao is NOT ready: skip the `openbao` provider in terraform.
Secrets stay in Coolify UI until OpenBao is live.
Set `IMAGE_TAG=main` manually in the Coolify UI for now.

## Step 4: Configure local environment

```bash
cd environments/production

# Create terraform.tfvars from the example
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars — add your Coolify URL and API token:
#   coolify_url       = "https://coolify.your-domain.com"
#   coolify_api_token = "tcp-..."

# Or use env vars instead:
export COOLIFY_URL="https://coolify.your-domain.com"
export COOLIFY_API_TOKEN="tcp-..."
```

## Step 5: Install Coolify provider

```bash
# The provider is from GitHub — clone and build it
cd /tmp
git clone https://github.com/SierraJC/coolify-terraform-provider.git
cd coolify-terraform-provider
go build -o ~/.terraform.d/plugins/github.com/SierraJC/coolify/0.0.1/linux_amd64/terraform-provider-coolify

# Back in beskid_infra
cd /path/to/beskid_infra/environments/production
tofu init
```

## Step 6: Import existing resources

Import the Coolify project, server, environment, and existing `beskid site` app:

```bash
cd environments/production

# Import project
tofu import coolify_project.beskid tosg8kc80g8go00sgcswsccg

# Import server
tofu import coolify_server.beskid ec0cs0cw0ocsok488gc0k80k

# Import production environment
tofu import coolify_environment.production e4g8w0c0gk0gcsc0wo4c8gcg

# Import existing site app
tofu import 'module.beskid_site.coolify_application.app' rsso488sscg80kookoo00sk4
```

## Step 7: Plan and apply

```bash
# Plan — review what will change
tofu plan

# If plan looks correct (should show no changes for imported resources,
# and creation of beskid-auth app):
tofu apply
```

Expected output:
- `coolify_project.beskid` — no changes (imported)
- `coolify_server.beskid` — no changes (imported)
- `module.beskid_site.coolify_application.app` — no changes (imported)
- `module.beskid_auth.coolify_application.app` — **will be created**

## Step 8: Set up GitHub Actions CI

Add these secrets to the `beskid_infra` repo:

| Secret | Value |
|--------|-------|
| `COOLIFY_URL` | Your Coolify instance URL |
| `COOLIFY_API_TOKEN` | The admin API token from Step 2 |

Push to `main` to trigger the `tofu-plan-apply.yml` workflow.

## Step 9: Configure Coolify server for GHCR pull

On the Coolify server:

```bash
# GHCR pull credential — PAT with read:packages scope for Cyber-Nomad-Collective
echo "$GHCR_PAT" | docker login ghcr.io -u <github-username> --password-stdin
```

## Step 10: Redeploy

```bash
# Trigger redeploy via OpenTofu or Coolify UI
tofu apply
# or in Coolify UI: beskid site → Deploy
```

### Verify

```bash
curl -sI https://beskid-lang.org/ | head -5
curl -s https://auth.beskid-lang.org/api/v1/health
```

## Rollback

```bash
cd environments/production
tofu destroy -target=module.beskid_auth  # if auth fails
# The existing beskid site app is imported, not destroyed
```

## After bootstrap

- [ ] Move Terraform state to remote backend (S3 / GCS)
- [ ] Create `staging` branch and environment
- [ ] Add OpenBao integration (if not done in Step 3)
- [ ] Add remaining services (tracker, nexus, pckg)
