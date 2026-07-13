# beskid_infra scripts

These are bootstrap and OpenBao seed utilities. Deployment orchestration lives in
the superrepo `scripts/ci/` and GitHub reusable workflows.

| Script | Purpose |
|---|---|
| [`seed-openbao-from-gh.sh`](seed-openbao-from-gh.sh) | Seed/audit lane KV from approved operator inputs |
| [`configure-external-openbao.sh`](configure-external-openbao.sh) | Configure per-service OpenBao values |
| [`openbao-init-unseal.sh`](openbao-init-unseal.sh) | Explicit first-time OpenBao bootstrap |
| [`lib/deploy-lane.sh`](lib/deploy-lane.sh) | Canonical staging/production lane names |

Authoritative delivery scripts:

- `../../scripts/ci/sync-runtime-env.sh`
- `../../scripts/ci/deploy-release-manifest.sh`
- `../../scripts/ci/render-release-compose.sh`

Toolchain: `../../scripts/install-deps.sh --group infra`.
