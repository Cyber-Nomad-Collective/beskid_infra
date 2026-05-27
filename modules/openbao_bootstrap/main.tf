# Seed KV paths after OpenBao is initialized and unsealed (requires vault provider).

resource "vault_mount" "secret" {
  path        = var.mount
  type        = "kv"
  options     = { version = "2" }
  description = "Beskid platform secrets"
}

resource "vault_kv_secret_v2" "tofu_lane" {
  mount = vault_mount.secret.path
  name  = "beskid/tofu/${var.openbao_lane}"

  data_json = jsonencode({
    coolify_endpoint      = var.coolify_endpoint
    coolify_api_token     = var.coolify_api_token
    coolify_project_uuid  = var.project_uuid
    coolify_server_uuid   = var.server_uuid
  })
}

resource "vault_kv_secret_v2" "services" {
  for_each = var.service_secrets

  mount = vault_mount.secret.path
  name  = "beskid/${var.openbao_lane}/${each.key}"

  data_json = jsonencode(each.value)
}
