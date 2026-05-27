provider "coolify" {
  endpoint = var.coolify_endpoint
  token    = var.coolify_api_token
}

provider "vault" {
  address          = coalesce(var.openbao_address, module.openbao_hostname.url)
  token            = var.openbao_token
  skip_child_token = true
}
