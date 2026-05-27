# Local configuration

## Files

| File | In git | Purpose |
|------|--------|---------|
| `coolify.snapshot.json` | yes | MCP inventory (no secrets) |
| `production.tfvars.example` | yes | Greenfield production template |
| `staging.tfvars.example` | yes | Staging template |
| `*.tfvars` | no | Operator overrides |
| `../.env` | no | Local tokens |

## Greenfield

OpenTofu creates **`coolify_project.beskid`** on production apply. See [docs/greenfield.md](../docs/greenfield.md).

```bash
just config-init
# .env: COOLIFY_API_TOKEN=...
git checkout main && just plan && just apply
tofu output coolify_project_uuid   # use for staging or let CI resolve
```

## MCP snapshot (2026-05-27)

| Resource | UUID / value |
|----------|----------------|
| Coolify | `https://coolify.bdziam.dev` |
| Server localhost | `ec0cs0cw0ocsok488gc0k80k` |
| **Project Beskid** | Created by OpenTofu |
| Legacy Beskid_MANUAL | `tosg8kc80g8go00sgcswsccg` (not managed) |

Refresh: `just mcp-snapshot-hint`.

## DNS

`191.96.53.21` — A records for `beskid-lang.org`, `bao.beskid-lang.org`, `auth.beskid-lang.org`, staging variants.
