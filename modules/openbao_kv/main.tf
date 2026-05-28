# Read OpenBao KV v2 secrets (Vault provider is API-compatible with OpenBao).
# Vault provider 5.1+ deprecates this data source in favor of ephemeral resources;
# values are merged into Coolify env maps (not write-only), so we pin vault < 5.1.

data "vault_kv_secret_v2" "this" {
  count = var.enabled ? 1 : 0
  mount = var.mount
  name  = var.secret_path
}

locals {
  merged_env = merge(
    var.static_env,
    var.enabled ? data.vault_kv_secret_v2.this[0].data : {},
  )
}
