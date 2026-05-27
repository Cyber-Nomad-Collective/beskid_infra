# Staging — stg.beskid-lang.org, stg-auth, stg-bao, …

module "openbao_hostname" {
  source      = "../../modules/beskid_hostname"
  environment = "staging"
  service     = "bao"
  base_domain = var.base_domain
}

module "stack" {
  source = "../../modules/beskid_stack"

  environment        = "staging"
  project_uuid       = local.coolify_project_uuid
  server_uuid        = var.server_uuid
  manage_environment = var.manage_environment
  base_domain        = var.base_domain

  coolify_endpoint  = var.coolify_endpoint
  coolify_api_token = var.coolify_api_token

  deploy_openbao       = var.deploy_openbao
  openbao_enabled      = var.openbao_enabled
  seed_openbao_secrets = var.seed_openbao_secrets
  openbao_mount        = var.openbao_mount

  enable_services    = var.enable_services
  manage_coolify_env = var.manage_coolify_env
  instant_deploy     = var.instant_deploy
}
