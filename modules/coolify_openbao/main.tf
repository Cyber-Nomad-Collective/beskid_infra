# OpenBao — Coolify Docker Compose service (platform dependency for all apps).
# Custom domain: coolify_service.urls (Coolify requires scheme + :8200 for expose port 8200).

locals {
  compose = templatefile("${path.module}/docker-compose.openbao.yml", {
    openbao_version = var.openbao_version
  })
  # Coolify Edit Domains / urls API: full URL with port (Traefik routes to container :8200).
  public_url = "https://${var.domains}:${var.expose_port}"
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

  urls = [
    {
      name = var.compose_service_name
      url  = local.public_url
    },
  ]
}
