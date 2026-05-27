# Production — beskid-lang.org and service subdomains (Let's Encrypt via Coolify/Traefik).

module "stack" {
  source = "../../modules/beskid_stack"

  environment              = "production"
  project_uuid             = var.project_uuid
  server_uuid              = var.server_uuid
  manage_environment       = var.manage_environment
  coolify_environment_name = var.coolify_environment_name

  openbao_enabled   = var.openbao_enabled
  openbao_mount     = var.openbao_mount

  enable_services    = var.enable_services
  manage_coolify_env = var.manage_coolify_env
  instant_deploy     = var.instant_deploy
}

# Import existing site app before first apply:
#   tofu import 'module.stack.module.apps["site"].coolify_application.this' rsso488sscg80kookoo00sk4
