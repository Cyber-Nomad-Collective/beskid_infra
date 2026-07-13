# Manifest-driven Coolify deployment

The Beskid platform uses one Compose template and two isolated Coolify services:
`beskid-platform-staging` and `beskid-platform-production`. The template is
[`compose/production/docker-compose.yml`](../compose/production/docker-compose.yml).

## Build-once flow

1. `platform-delivery.yml` blocks on OpenSpec, conformance, integration, and
   supply-chain security gates.
2. Each service image is built once, tagged by full source SHA, supplied with an
   SBOM/provenance attestation, and signed keylessly.
3. `reusable-release-manifest.yml` records exact image digests and the source run.
4. The same manifest is rendered into exact `repository@sha256:…` references.
5. Main deploys to the protected `staging` environment automatically.
6. `promote-production.yml` accepts the successful main delivery run ID and
   promotes its existing artifact after production approval. It never rebuilds.

The deploy script polls Coolify to a terminal state, runs trace-correlated health
checks, and restores the previous Compose payload if deploy or smoke verification
fails.

## GitHub environments

Create `staging` and `production` environments with different values:

| Name | Type |
|---|---|
| `COOLIFY_ENDPOINT` | variable |
| `COOLIFY_SERVICE_UUID` | variable |
| `BESKID_SMOKE_URLS` | newline-separated variable |
| `OPENBAO_ADDR` | variable |
| `COOLIFY_API_TOKEN` | secret |
| `OPENBAO_TOKEN` | lane-scoped read-only secret |

Production requires reviewers. Neither environment secret is available to pull
requests. OpenBao policies must limit each token to its matching
`secret/beskid/{lane}/*` prefix.

## First-time setup

Create the two Coolify Compose services and their isolated volumes through the
Coolify operator UI/API, set their service UUIDs on the matching GitHub
environment, seed OpenBao, then validate locally:

```bash
cd beskid_infra
just config-init
just compose-config
just delivery-contract
just seed-openbao-all
```

The repository does not automatically create infrastructure or infer a production
service. Host bootstrap remains available through
`ansible/playbooks/prepare-coolify-host.yml`.

## Rollback and evidence

- The release manifest SHA and W3C `traceparent` are written to workflow logs and
  forwarded to OpenBao, Coolify, and smoke HTTP calls.
- Coolify trigger, polling, environment synchronization, and smoke failures are
  fatal.
- Rollback restores the Compose payload read immediately before the attempted
  deployment and polls the rollback deployment to completion.
- GitHub artifacts retain the signed-image records, manifest, checksum, and gate
  JUnit evidence.

Service ports, domains, volumes, and secret keys are documented in
[deploy-matrix.md](deploy-matrix.md) and [openbao-layout.md](openbao-layout.md).
