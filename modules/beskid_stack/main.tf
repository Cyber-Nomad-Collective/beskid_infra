# Full Beskid platform stack for one Coolify environment lane.

resource "coolify_environment" "managed" {
  count = var.manage_environment ? 1 : 0

  project_uuid = var.project_uuid
  name         = local.cfg.coolify_environment
}

locals {
  environment_name = var.manage_environment ? coolify_environment.managed[0].name : var.coolify_environment_name
}

module "hostname_auth" {
  source      = "../beskid_hostname"
  environment = var.environment
  service     = "auth"
  base_domain = var.base_domain
}

module "hostnames" {
  for_each = local.enabled_ghcr_services
  source   = "../beskid_hostname"

  environment = var.environment
  service     = each.key
  base_domain = var.base_domain
}

module "apps" {
  for_each = local.enabled_ghcr_services
  source   = "../coolify_ghcr_application"

  app_name         = "beskid-${each.key}${local.cfg.name_suffix}"
  description      = each.value.description
  project_uuid     = var.project_uuid
  server_uuid      = var.server_uuid
  destination_uuid = var.destination_uuid
  environment_name = local.environment_name
  ghcr_image       = each.value.ghcr_image
  image_tag        = coalesce(var.image_tag_override, local.cfg.image_tag)
  expose_port      = each.value.port

  domains = module.hostnames[each.key].domains

  openbao_enabled     = var.openbao_enabled
  openbao_mount       = var.openbao_mount
  openbao_secret_path = "beskid/${local.cfg.openbao_lane}/${each.value.openbao_service}"

  static_env = merge(
    contains(["auth", "tracker", "nexus"], each.key) ? { AUTH_HUB_PUBLIC_URL = module.hostname_auth.url } : {},
    each.key == "tracker" ? {
      TRACKER_PUBLIC_URL = module.hostnames[each.key].url
      TRACKER_DATA_DIR   = "/app/beskid_tracker/data/runtime"
    } : {},
    each.key == "nexus" ? { GITNEXUS_HOME = "/data/gitnexus" } : {},
    lookup(var.service_static_env, each.key, {}),
  )

  manage_env      = var.manage_coolify_env
  auto_deploy     = var.auto_deploy
  instant_deploy  = var.instant_deploy
  storage_volumes = each.value.storage_volumes
}

module "pckg" {
  count  = try(var.enable_services["pckg"], false) ? 1 : 0
  source = "../coolify_pckg_stack"

  environment         = var.environment
  base_domain         = var.base_domain
  app_name            = "beskid-pckg${local.cfg.name_suffix}"
  database_name       = "beskid-pckg-db${local.cfg.name_suffix}"
  project_uuid        = var.project_uuid
  server_uuid         = var.server_uuid
  destination_uuid    = var.destination_uuid
  environment_name    = local.environment_name
  image_tag           = coalesce(var.image_tag_override, local.cfg.image_tag)
  auth_hub_public_url = module.hostname_auth.url

  openbao_enabled     = var.openbao_enabled
  openbao_mount       = var.openbao_mount
  openbao_secret_path = "beskid/${local.cfg.openbao_lane}/pckg"
  postgres_password = coalesce(
    var.pckg_postgres_password,
    try(random_password.pckg_postgres[0].result, null),
  )

  manage_env     = var.manage_coolify_env
  auto_deploy    = var.auto_deploy
  instant_deploy = var.instant_deploy
}
