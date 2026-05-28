# beskid_infra scripts

OpenBofu / OpenBao helpers for this submodule only.

| Script | Purpose |
|--------|---------|
| [`seed-openbao-from-gh.sh`](seed-openbao-from-gh.sh) | Audit/seed KV from `gh variable` + `config/openbao-secrets.env` |
| [`configure-external-openbao.sh`](configure-external-openbao.sh) | Service SESSION_SECRET / IMAGE_TAG paths (called by seed script) |
| [`export-openbao-for-tofu.sh`](export-openbao-for-tofu.sh) | Export `TF_VAR_*` from OpenBao; lane from git branch (`main`→`production`, `stg`→`staging`) |
| [`lib/git-tofu-env.sh`](lib/git-tofu-env.sh) | Branch → lane mapping |
| [`export-openbao-for-drone.sh`](export-openbao-for-drone.sh) | Drone CI secrets from OpenBao |

**Toolchain** (git, jq, tofu, bao, rust, …): use the superrepo [`../../scripts/install-deps.sh`](../../scripts/install-deps.sh) and [`../../repo-deps.json`](../../repo-deps.json).

```bash
# From superrepo root:
./scripts/install-deps.sh --check --group infra
```

Or from here: `../scripts/install-deps.sh` (if `beskid_infra` is checked out inside the superrepo).
