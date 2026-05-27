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

  project_uuid       = var.project_uuid
  server_uuid        = var.server_uuid
  destination_uuid   = var.destination_uuid
  environment_name   = local.environment_name
  app_name         = "beskid-openbao${local.cfg.name_suffix}"
  domains          = module.hostname_openbao.domains
  instant_deploy   = var.instant_deploy
  auto_deploy      = var.auto_deploy
}

locals {
  lane_image_tag = coalesce(var.image_tag_override, local.cfg.image_tag)
}

resource "random_password" "auth_session" {
  count   = var.seed_openbao_secrets && try(var.enable_services["auth"], false) ? 1 : 0
  length  = 48
  special = false
}

resource "random_password" "hub_secret" {
  count   = var.seed_openbao_secrets && try(var.enable_services["auth"], false) ? 1 : 0
  length  = 48
  special = false
}

resource "random_password" "tracker_session" {
  count   = var.seed_openbao_secrets && try(var.enable_services["tracker"], false) ? 1 : 0
  length  = 48
  special = false
}

resource "random_password" "nexus_session" {
  count   = var.seed_openbao_secrets && try(var.enable_services["nexus"], false) ? 1 : 0
  length  = 48
  special = false
}

resource "random_password" "pckg_postgres" {
  count   = try(var.enable_services["pckg"], false) ? 1 : 0
  length  = 32
  special = true
}

locals {
  openbao_service_secrets = var.seed_openbao_secrets ? merge(
    try(var.enable_services["site"], false) ? {
      site = {
        IMAGE_TAG = local.lane_image_tag
      }
    } : {},
    try(var.enable_services["auth"], false) ? {
      auth = {
        IMAGE_TAG           = local.lane_image_tag
        AUTH_HUB_PUBLIC_URL = module.hostname_auth.url
        SESSION_SECRET      = random_password.auth_session[0].result
        AUTH_HUB_SECRET     = random_password.hub_secret[0].result
      }
    } : {},
    try(var.enable_services["tracker"], false) ? {
      tracker = {
        IMAGE_TAG           = local.lane_image_tag
        AUTH_HUB_PUBLIC_URL = module.hostname_auth.url
        TRACKER_PUBLIC_URL  = module.hostnames["tracker"].url
        SESSION_SECRET      = random_password.tracker_session[0].result
        TRACKER_DATA_DIR    = "/app/beskid_tracker/data/runtime"
      }
    } : {},
    try(var.enable_services["nexus"], false) ? {
      nexus = {
        IMAGE_TAG           = local.lane_image_tag
        AUTH_HUB_PUBLIC_URL = module.hostname_auth.url
        SESSION_SECRET      = random_password.nexus_session[0].result
        GITNEXUS_HOME       = "/data/gitnexus"
      }
    } : {},
    try(var.enable_services["pckg"], false) ? {
      pckg = {
        IMAGE_TAG           = local.lane_image_tag
        AUTH_HUB_PUBLIC_URL = module.hostname_auth.url
        POSTGRES_PASSWORD   = random_password.pckg_postgres[0].result
      }
    } : {},
  ) : {}
}

module "openbao_bootstrap" {
  count  = var.deploy_openbao && var.seed_openbao_secrets ? 1 : 0
  source = "../openbao_bootstrap"

  openbao_lane      = local.cfg.openbao_lane
  coolify_endpoint  = var.coolify_endpoint
  coolify_api_token = var.coolify_api_token
  project_uuid      = var.project_uuid
  server_uuid       = var.server_uuid
  image_tag         = local.lane_image_tag

  service_secrets = local.openbao_service_secrets

  depends_on = [module.openbao]
}
