output "service_id" {
  value = coolify_service.this.id
}

output "service_name" {
  value = coolify_service.this.name
}

output "host" {
  description = "Public hostname (no scheme)."
  value       = var.domains
}

output "url" {
  description = "OpenBao API base URL for the vault provider and CLI."
  value       = "https://${var.domains}"
}
