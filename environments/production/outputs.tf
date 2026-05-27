output "public_urls" {
  description = "HTTPS URLs per service (DNS must point at Coolify)."
  value       = module.stack.public_urls
}

output "hosts" {
  value = module.stack.hosts
}

output "application_ids" {
  value     = module.stack.application_ids
  sensitive = false
}

output "auth_hub_public_url" {
  value = module.stack.auth_hub_public_url
}
