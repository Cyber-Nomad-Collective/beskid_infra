# beskid_infra scripts

| Script | Purpose |
|--------|---------|
| [`coolify-deploy-compose.sh`](coolify-deploy-compose.sh) | Create/update production Coolify compose service + redeploy |
| [`coolify-sync-env-from-openbao.sh`](coolify-sync-env-from-openbao.sh) | OpenBao KV → Coolify service env (bulk PATCH) |
| [`seed-openbao-from-gh.sh`](seed-openbao-from-gh.sh) | Seed/audit KV from `gh variable` + `config/openbao-secrets.env` |
| [`configure-external-openbao.sh`](configure-external-openbao.sh) | Service secrets (called by seed script) |
| [`lib/coolify-api.sh`](lib/coolify-api.sh) | Shared Coolify REST helpers |
| [`lib/deploy-lane.sh`](lib/deploy-lane.sh) | Production/staging lane names |

Coolify project UUID resolution: superrepo [`../../scripts/ci/resolve-coolify-project-uuid.sh`](../../scripts/ci/resolve-coolify-project-uuid.sh).

Toolchain: [`../../scripts/install-deps.sh`](../../scripts/install-deps.sh) `--group infra`.
