# beskid_infra

Declarative lane configuration for manifest-driven Beskid deployments on
Coolify. Platform images are built once by the superrepo and promoted by exact
OCI digest; this repository does not contain an alternate deploy engine.

## Local validation

```bash
just config-init
just compose-config
just delivery-contract
```

`compose-config` injects a validation-only placeholder because the checked-in
Compose file deliberately refuses direct mutable-tag deployment.

## Layout

```
compose/production/          # shared platform Compose template
config/coolify-staging.json  # staging OpenBao/static env contract
config/coolify-production.json
config/domains.json
monitoring/                  # Alloy, Prometheus, Loki, Grafana config
scripts/                     # host bootstrap and OpenBao seed utilities only
```

## Delivery ownership

| Layer | Authority |
|---|---|
| Standard | `openspec/specs` |
| Quality/build/manifest | `.github/workflows/platform-delivery.yml` |
| Staging | successful main delivery manifest |
| Production | `.github/workflows/promote-production.yml` + protected environment approval |
| Runtime secrets | OpenBao `secret/beskid/{lane}/{service}` |
| Runtime state | lane-specific Coolify Compose service and volumes |

Operator guide: [docs/deploy-compose.md](docs/deploy-compose.md). Secret layout:
[docs/openbao-layout.md](docs/openbao-layout.md). Service matrix:
[docs/deploy-matrix.md](docs/deploy-matrix.md).
