# Read OpenBao KV v2 secrets (Vault provider is API-compatible with OpenBao).

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
