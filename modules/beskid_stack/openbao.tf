# OpenBao on Coolify — deployed before apps; KV seeded when openbao_token is set.

module "hostname_openbao" {
  source      = "../beskid_hostname"
  environment = var.environment
  service     = "bao"
  base_domain = var.base_domain
}

module "openbao" {
  count  = var.deploy_openbao ? 1 : 0
  source = "../coolify_openbao"

  project_uuid     = var.project_uuid
  server_uuid      = var.server_uuid
  environment_name = local.environment_name
  app_name         = "beskid-openbao${local.cfg.name_suffix}"
  domains          = module.hostname_openbao.domains
  instant_deploy   = var.instant_deploy
  auto_deploy      = var.auto_deploy
}

resource "random_password" "auth_session" {
  count   = var.seed_openbao_secrets ? 1 : 0
  length  = 48
  special = false
}

resource "random_password" "hub_secret" {
  count   = var.seed_openbao_secrets ? 1 : 0
  length  = 48
  special = false
}

module "openbao_bootstrap" {
  count = var.deploy_openbao && var.seed_openbao_secrets ? 1 : 0
  source = "../openbao_bootstrap"

  openbao_lane      = local.cfg.openbao_lane
  coolify_endpoint  = var.coolify_endpoint
  coolify_api_token = var.coolify_api_token
  project_uuid      = var.project_uuid
  server_uuid       = var.server_uuid
  image_tag         = coalesce(var.image_tag_override, local.cfg.image_tag)

  service_secrets = {
    site = {
      IMAGE_TAG = coalesce(var.image_tag_override, local.cfg.image_tag)
    }
    auth = {
      IMAGE_TAG           = coalesce(var.image_tag_override, local.cfg.image_tag)
      AUTH_HUB_PUBLIC_URL = module.hostname_auth.url
      SESSION_SECRET      = random_password.auth_session[0].result
      AUTH_HUB_SECRET     = random_password.hub_secret[0].result
    }
  }

  depends_on = [module.openbao]
}
