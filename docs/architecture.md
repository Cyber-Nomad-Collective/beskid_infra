# Infrastructure architecture

OpenTofu manages the Beskid platform on Coolify with runtime secrets in OpenBao. SSL certificates are issued automatically by Coolify’s proxy (Traefik + Let’s Encrypt HTTP-01) when `domains` is set on each application.

## Module layers

```
environments/{production,staging}
    └── modules/beskid_stack          # one lane, all services
            ├── modules/beskid_hostname     # DNS hostname rules
            ├── modules/coolify_ghcr_application  # site, auth, tracker, nexus
            └── modules/coolify_pckg_stack        # PostgreSQL + pckg app
                    └── modules/openbao_kv        # KV read + env merge
```

## Providers

| Provider | Source | Role |
|----------|--------|------|
| `arcusis/coolify` | Terraform Registry | Apps, env bulk, DB, volumes |
| `hashicorp/vault` | Terraform Registry | OpenBao KV v2 (API-compatible) |

Configure Coolify with `COOLIFY_ENDPOINT` + `COOLIFY_TOKEN`, or `TF_VAR_coolify_endpoint` / `TF_VAR_coolify_api_token`.

## Hostname convention

| Service | production (`main`) | staging (`stg`) |
|---------|---------------------|-----------------|
| site | `beskid-lang.org` | `stg.beskid-lang.org` |
| auth | `auth.beskid-lang.org` | `stg-auth.beskid-lang.org` |
| tracker | `tracker.beskid-lang.org` | `stg-tracker.beskid-lang.org` |
| nexus | `nexus.beskid-lang.org` | `stg-nexus.beskid-lang.org` |
| pckg | `pckg.beskid-lang.org` | `stg-pckg.beskid-lang.org` |

DNS: **A** record each hostname (or operational wildcard) → Coolify server IP. Ports **80** and **443** must be reachable for Let’s Encrypt.

## OpenBao paths

```
secret/beskid/{production,staging}/{site,auth,tracker,nexus,pckg}
secret/beskid/tofu/{production,staging}   # branch main / stg → lane name
secret/beskid/ci/build                        # NODE_AUTH_TOKEN, OVSX_TOKEN
```

See [openbao-layout.md](openbao-layout.md).

## Service rollout

Enable services per environment via `enable_services` in `terraform.tfvars`:

```hcl
enable_services = {
  site    = true
  auth    = true
  tracker = false
  nexus   = false
  pckg    = false
}
```

GHCR images: `ghcr.io/cyber-nomad-collective/beskid-{site,auth,tracker,nexus,pckg}:{main|staging}`.

## Let's Encrypt

- Set on `coolify_application`: `domains = "<host>"`, `is_force_https_enabled = true`.
- Coolify Traefik requests certificates after DNS resolves.
- Wildcard `*.beskid-lang.org` requires DNS-01 on the server — see [Coolify DNS challenge](https://coolify.io/docs/knowledge-base/proxy/traefik/dns-challenge).

## Import existing apps

```bash
cd environments/production
tofu import 'module.stack.module.apps["site"].coolify_application.this' <site-uuid>
tofu import 'module.stack.module.apps["auth"].coolify_application.this' <auth-uuid>
```

Full checklist: [coolify-import.md](coolify-import.md).
