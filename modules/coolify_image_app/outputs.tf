output "application_uuid" {
  description = "Coolify application UUID"
  value       = coolify_application.app.uuid
}

output "application_name" {
  description = "Coolify application name"
  value       = coolify_application.app.name
}

output "ghcr_image" {
  description = "GHCR image reference"
  value       = "${local.image_name}:${var.image_tag}"
}
