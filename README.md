# beskid_infra

OpenTofu for the Beskid platform: Coolify apps (GHCR image-only), automatic Let's Encrypt domains, OpenBao secrets.

## Structure

```
modules/
  beskid_hostname/           # stg.beskid-lang.org, stg-pckg, …
  openbao_kv/                # KV v2 → env map
  coolify_ghcr_application/  # arcusis application + envs_bulk
  coolify_pckg_stack/         # PostgreSQL + pckg app
  beskid_stack/              # all services per lane
environments/
  production/   # git branch main
  staging/      # git branch stg
docs/
  architecture.md
  deploy-matrix.md
  openbao-layout.md
  greenfield.md
  coolify-import.md   # legacy Beskid_MANUAL only
```

## Toolchain

From the **superrepo root** (or `just deps-check` in this directory):

```bash
../scripts/install-deps.sh --check --group infra
```

Manifest: [`../repo-deps.json`](../repo-deps.json) · [`../scripts/README.md`](../scripts/README.md).

## Quick start

See [docs/greenfield.md](docs/greenfield.md) for the default path (OpenTofu creates the Coolify project).

```bash
just config-init
# edit .env + config/*.tfvars
git checkout main && just plan    # production — creates coolify_project.beskid
git checkout stg && just plan     # staging — needs project_uuid from prod output
```

Manual OpenTofu: [docs/bootstrap.md](docs/bootstrap.md). Local UUIDs: [config/coolify.snapshot.json](config/coolify.snapshot.json).

Bootstrap: [docs/bootstrap.md](docs/bootstrap.md) · Architecture: [docs/architecture.md](docs/architecture.md)

## Providers

| Provider | Purpose |
|----------|---------|
| [arcusis/coolify](https://registry.terraform.io/providers/arcusis/coolify/latest/docs) | Applications, PostgreSQL, env bulk |
| [hashicorp/vault](https://registry.terraform.io/providers/hashicorp/vault/latest/docs) | OpenBao KV reads |

## CI (Dagger)

Release and publish pipelines live in [`dagger/`](dagger/) (TypeScript Dagger module). From the superrepo root:

```bash
cd beskid_infra/dagger && npm install && dagger functions
dagger -m beskid_infra/dagger call compiler-rust-gate --source=../..
```

Optional Just recipes: `just dagger-functions`, `just dagger-gate`. See [dagger/README.md](dagger/README.md).

## Related

- [beskid](https://github.com/Cyber-Nomad-Collective/beskid) — GHCR builds, compose sources
- [Coolify Let's Encrypt troubleshooting](https://coolify.io/docs/troubleshoot/dns-and-domains/lets-encrypt-not-working)
