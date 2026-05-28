# Staging — stg.beskid-lang.org, stg-auth, stg-bao, …

module "stack" {
  source = "../../modules/beskid_stack"

  environment        = "staging"
  project_uuid       = local.coolify_project_uuid
  server_uuid        = var.server_uuid
  destination_uuid   = var.destination_uuid
  manage_environment = var.manage_environment
  base_domain        = var.base_domain

  openbao_enabled = var.openbao_enabled
  openbao_mount   = var.openbao_mount

  enable_services    = var.enable_services
  manage_coolify_env = var.manage_coolify_env
  instant_deploy     = var.instant_deploy
}
