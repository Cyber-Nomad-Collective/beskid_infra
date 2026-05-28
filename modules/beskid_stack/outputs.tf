output "coolify_environment_name" {
  value = local.environment_name
}

output "openbao_url" {
  description = "Configured external OpenBao API URL."
  value       = null
}

output "openbao_service_id" {
  value = null
}

output "openbao_host" {
  value = null
}

output "auth_hub_public_url" {
  value = module.hostname_auth.url
}

output "public_urls" {
  value = merge(
    { for k, m in module.hostnames : k => m.url },
    length(module.pckg) > 0 ? { pckg = module.pckg[0].public_url } : {},
  )
}

output "hosts" {
  value = merge(
    { for k, m in module.hostnames : k => m.host },
    length(module.pckg) > 0 ? { pckg = module.pckg[0].host } : {},
  )
}

output "application_ids" {
  value = merge(
    { for k, m in module.apps : k => m.application_id },
    length(module.pckg) > 0 ? { pckg = module.pckg[0].application_id } : {},
  )
}
