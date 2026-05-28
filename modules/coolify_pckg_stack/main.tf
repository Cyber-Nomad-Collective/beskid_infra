# pckg: managed PostgreSQL + GHCR app (replaces compose postgres sidecar).

module "hostname" {
  source      = "../beskid_hostname"
  environment = var.environment
  service     = "pckg"
  base_domain = var.base_domain
}

module "secrets" {
  source = "../openbao_kv"

  enabled     = var.openbao_enabled
  mount       = var.openbao_mount
  secret_path = var.openbao_secret_path
  static_env = merge(
    {
      IMAGE_TAG                            = var.image_tag
      AUTH_HUB_PUBLIC_URL                  = var.auth_hub_public_url
      Pckg__Database__AutoMigrateOnStartup = "true"
      HTTP_PORTS                           = "8082"
    },
    var.static_env,
  )
}

resource "coolify_database_postgresql" "this" {
  project_uuid       = var.project_uuid
  server_uuid        = var.server_uuid
  destination_uuid   = var.destination_uuid
  environment_name   = var.environment_name
  name              = var.database_name
  postgres_db       = var.postgres_db
  postgres_user     = var.postgres_user
  postgres_password = var.postgres_password
  instant_deploy    = var.instant_deploy
}

resource "coolify_application" "app" {
  type             = "dockerimage"
  project_uuid     = var.project_uuid
  server_uuid      = var.server_uuid
  destination_uuid = var.destination_uuid
  environment_name = var.environment_name
  name             = var.app_name

  docker_registry_image_name = var.ghcr_image
  ports_exposes              = "8082"
  domains                    = "https://${module.hostname.domains}"

  description            = "Beskid package registry (${var.environment})"
  is_force_https_enabled = true
  is_auto_deploy_enabled = var.auto_deploy
  instant_deploy         = var.instant_deploy
  force_domain_override  = true

  depends_on = [coolify_database_postgresql.this]
}

resource "coolify_envs_bulk" "app" {
  count = var.manage_env ? 1 : 0

  resource_type = "application"
  resource_uuid = coolify_application.app.id
  variables = merge(
    module.secrets.env,
    {
      # Coolify internal DB hostname — override in OpenBao if your instance differs.
      PCKG_DB_HOST = coalesce(var.pckg_db_host_override, coolify_database_postgresql.this.name)
      PCKG_DB_PORT = "5432"
    },
  )
}

resource "coolify_application_storage" "packages" {
  application_uuid = coolify_application.app.id
  type             = "persistent"
  name             = "${var.app_name}-packages"
  mount_path       = "/app/packages"
}

resource "coolify_application_storage" "data" {
  application_uuid = coolify_application.app.id
  type             = "persistent"
  name             = "${var.app_name}-data"
  mount_path       = "/app/data"
}
