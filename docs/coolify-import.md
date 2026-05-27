# Coolify import and rollout

Import existing Coolify resources into OpenTofu ([arcusis/coolify](https://registry.terraform.io/providers/arcusis/coolify/latest/docs)) using the `beskid_stack` module.

## Import commands

```bash
cd environments/production
tofu init

# Environment (if managed by TF)
tofu import 'module.stack.coolify_environment.managed[0]' 'tosg8kc80g8go00sgcswsccg/production'

# Applications
tofu import 'module.stack.module.apps["site"].coolify_application.this' rsso488sscg80kookoo00sk4
tofu import 'module.stack.module.apps["auth"].coolify_application.this' <auth-uuid>
tofu import 'module.stack.module.apps["nexus"].coolify_application.this' rc7pssssk5i3vqjrt1anx4y3
tofu import 'module.stack.module.apps["tracker"].coolify_application.this' s8voih0gwkrftklgsmxqglo4

# Legacy Pckg compose app — taint/recreate via module.stack.module.pckg[0] after cutover
```

Set `manage_environment = false` in production when the `production` environment already exists.

## Rollout order

1. **staging** — `enable_services = { auth = true }`, image `staging`
2. **staging** — site, then tracker, nexus, pckg
3. **production** — import site, enable auth, migrate pckg from old compose app

## Application shape

- **Type:** `dockerimage`
- **SSL:** `domains` + `is_force_https_enabled`
- **Env:** `coolify_envs_bulk` from OpenBao (replaces UI vars on apply)

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| No SSL | DNS → server IP; open :80/:443; disable Cloudflare proxy or use DNS-01 |
| 401 pull | GHCR registry in Coolify |
| Env wiped unexpectedly | All vars for app must be in TF / OpenBao when `manage_coolify_env = true` |
| pckg DB connection | Set `ConnectionStrings__Default` in OpenBao or fix `PCKG_DB_HOST` override |
