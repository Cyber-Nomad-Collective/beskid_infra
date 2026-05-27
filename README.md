# beskid_infra

OpenTofu infrastructure for the Beskid platform — manages Coolify apps, DNS, and secrets via OpenBao.

## Structure

```
├── modules/
│   └── coolify_image_app/   # Reusable module: GHCR-pulled Coolify app
├── environments/
│   ├── production/          # main branch, beskid-lang.org
│   └── staging/             # staging branch, isolated
├── docs/
│   ├── bootstrap.md         # Step-by-step setup guide
│   ├── deploy-matrix.md     # Service → GHCR → Coolify map
│   └── openbao-layout.md    # Secret paths and rotation
└── .github/workflows/
    └── tofu-plan-apply.yml  # CI: plan on PR, apply on push to main
```

## Quick start

```bash
cd environments/production
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your Coolify URL and API token
tofu init
tofu plan
tofu apply
```

Full bootstrap: [docs/bootstrap.md](docs/bootstrap.md)

## Providers

| Provider | Purpose |
|----------|---------|
| `SierraJC/coolify` | Manage Coolify apps, servers, environments |
| `OpenBao/openbao` | Read runtime secrets at apply time |

## Related

- [Beskid superrepo](https://github.com/Cyber-Nomad-Collective/beskid) — application source and GHCR builds
- [Coolify MCP](https://github.com/masonator/coolify-mcp) — API bridge for this repo
