# OpenBao — Coolify Docker Compose service (platform dependency for all apps).

locals {
  compose = templatefile("${path.module}/docker-compose.openbao.yml", {
    openbao_version = var.openbao_version
    openbao_fqdn    = var.domains
  })
}

resource "coolify_service" "this" {
  type             = "compose"
  project_uuid     = var.project_uuid
  server_uuid      = var.server_uuid
  destination_uuid = var.destination_uuid
  environment_name = var.environment_name
  name             = var.app_name
  description      = var.description

  docker_compose_raw = local.compose
  instant_deploy     = var.instant_deploy
}
