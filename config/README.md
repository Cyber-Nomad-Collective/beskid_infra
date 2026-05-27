# Local configuration

## Files

| File | In git | Purpose |
|------|--------|---------|
| `coolify.snapshot.json` | yes | UUIDs / inventory from Coolify MCP (no secrets) |
| `production.tfvars.example` | yes | Template → `production.tfvars` |
| `staging.tfvars.example` | yes | Template → `staging.tfvars` |
| `*.tfvars` | no | Operator overrides per lane |
| `../.env` | no | `COOLIFY_API_TOKEN`, `VAULT_*` |

## Quick start

```bash
just config-init
# Edit .env and config/{production,staging}.tfvars
git checkout main && just plan
git checkout stg && just plan
```

## MCP snapshot (2026-05-27)

| Resource | UUID / value |
|----------|----------------|
| Coolify | `https://coolify.bdziam.dev` · v4.0.0-beta.473 |
| Project Beskid | `tosg8kc80g8go00sgcswsccg` |
| Server localhost | `ec0cs0cw0ocsok488gc0k80k` · proxy **Caddy** |
| Env production | `e4g8w0c0gk0gcsc0wo4c8gcg` |
| App site | `rsso488sscg80kookoo00sk4` |
| App nexus | `rc7pssssk5i3vqjrt1anx4y3` |
| App tracker | `s8voih0gwkrftklgsmxqglo4` |
| App pckg | `fotldmgwdsxttpde914u8ktr` |

Full JSON: `coolify.snapshot.json`. Refresh: `just mcp-snapshot-hint`.

## Secrets

Either `.env`:

```bash
COOLIFY_API_TOKEN=tcp-...
VAULT_ADDR=https://...
VAULT_TOKEN=...
```

OpenBao path `secret/beskid/tofu/{production,staging}` — lane from git branch (`main` / `stg`). Use `just export-openbao` or `source scripts/export-openbao-for-tofu.sh`.

## DNS (server public IP)

`191.96.53.21` — A records for `beskid-lang.org`, `stg.beskid-lang.org`, `stg-auth.beskid-lang.org`, etc.
