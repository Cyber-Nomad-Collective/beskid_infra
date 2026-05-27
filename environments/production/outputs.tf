output "coolify_project_uuid" {
  description = "Beskid Coolify project UUID (created or resolved)."
  value       = local.coolify_project_uuid
}

output "coolify_project_name" {
  value = var.coolify_project_name
}

output "openbao_url" {
  value = module.stack.openbao_url
}

output "public_urls" {
  description = "HTTPS URLs per enabled service."
  value       = module.stack.public_urls
}

output "application_ids" {
  value = module.stack.application_ids
}

output "auth_hub_public_url" {
  value = module.stack.auth_hub_public_url
}
