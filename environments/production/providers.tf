provider "coolify" {
  endpoint = var.coolify_endpoint
  token    = var.coolify_api_token
}

provider "vault" {
  address = var.openbao_address
  token   = var.openbao_token
  # OpenBao is Vault API-compatible; skip_child_token avoids lease issues in CI.
  skip_child_token = true
}
