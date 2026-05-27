# Staging — stg.beskid-lang.org, stg-auth, stg-pckg, …

module "stack" {
  source = "../../modules/beskid_stack"

  environment        = "staging"
  project_uuid       = var.project_uuid
  server_uuid        = var.server_uuid
  manage_environment = var.manage_environment

  openbao_enabled   = var.openbao_enabled
  openbao_mount     = var.openbao_mount

  enable_services    = var.enable_services
  manage_coolify_env = var.manage_coolify_env
  instant_deploy     = var.instant_deploy
}
