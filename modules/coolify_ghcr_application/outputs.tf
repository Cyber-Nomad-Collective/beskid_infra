output "application_id" {
  value = coolify_application.this.id
}

output "application_name" {
  value = coolify_application.this.name
}

output "image" {
  value = "${var.ghcr_image}:${var.image_tag}"
}

output "public_url" {
  value = "https://${var.domains}"
}
