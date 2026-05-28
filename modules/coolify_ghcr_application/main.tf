# GHCR image-only Coolify application (arcusis/coolify).

module "secrets" {
  source = "../openbao_kv"

  enabled     = var.openbao_enabled
  mount       = var.openbao_mount
  secret_path = var.openbao_secret_path
  static_env  = merge({ IMAGE_TAG = var.image_tag }, var.static_env)
}

locals {
  # Attach persistent storage before first deploy (instant_deploy races storage POST).
  defer_instant_deploy = length(var.storage_volumes) > 0
}

resource "coolify_application" "this" {
  type             = "dockerimage"
  project_uuid     = var.project_uuid
  server_uuid      = var.server_uuid
  destination_uuid = var.destination_uuid
  environment_name = var.environment_name
  name             = var.app_name

  docker_registry_image_name = var.ghcr_image
  ports_exposes              = tostring(var.expose_port)
  domains                    = "https://${var.domains}:${var.expose_port}"

  description            = var.description
  is_force_https_enabled = true
  is_auto_deploy_enabled = var.auto_deploy
  instant_deploy         = var.instant_deploy && !local.defer_instant_deploy
  force_domain_override  = true
}

resource "coolify_envs_bulk" "this" {
  count = var.manage_env ? 1 : 0

  resource_type = "application"
  resource_uuid = coolify_application.this.id
  variables     = module.secrets.env
}

resource "coolify_application_storage" "volume" {
  for_each = var.storage_volumes

  application_uuid = coolify_application.this.id
  type             = "persistent"
  name             = each.value.name
  mount_path       = each.value.mount_path
  is_readonly      = try(each.value.readonly, false)

  depends_on = [coolify_application.this]
}

resource "coolify_deploy" "after_storage" {
  count = var.instant_deploy && local.defer_instant_deploy ? 1 : 0

  resource_uuid = coolify_application.this.id

  depends_on = [
    coolify_application.this,
    coolify_envs_bulk.this,
    coolify_application_storage.volume,
  ]
}
