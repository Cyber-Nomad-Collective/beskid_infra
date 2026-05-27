output "host" {
  description = "Hostname without scheme (Coolify domains field)."
  value       = local.host
}

output "url" {
  description = "Public HTTPS URL for OpenBao AUTH_HUB_PUBLIC_URL and docs."
  value       = "https://${local.host}"
}

output "domains" {
  description = "Alias for host — passed to coolify_application.domains."
  value       = local.host
}
