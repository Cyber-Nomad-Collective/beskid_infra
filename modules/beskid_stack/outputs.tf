output "coolify_environment_name" {
  value = local.environment_name
}

output "application_ids" {
  value = { for k, m in module.apps : k => m.application_id }
}

output "public_urls" {
  value = merge(
    { for k, m in module.apps : k => m.public_url },
    try(var.enable_services["pckg"], false) ? { pckg = module.pckg[0].public_url } : {},
  )
}

output "hosts" {
  value = merge(
    { for k, h in module.hostnames : k => h.host },
    try(var.enable_services["pckg"], false) ? { pckg = module.pckg[0].host } : {},
  )
}

output "auth_hub_public_url" {
  value = module.hostname_auth.url
}
