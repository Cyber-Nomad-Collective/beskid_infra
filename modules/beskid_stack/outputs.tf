output "coolify_environment_name" {
  value = local.environment_name
}

output "openbao_url" {
  description = "Public OpenBao API URL."
  value       = var.deploy_openbao ? module.openbao[0].url : null
}

output "openbao_service_id" {
  value = var.deploy_openbao ? module.openbao[0].service_id : null
}

output "openbao_host" {
  value = module.hostname_openbao.host
}

output "auth_hub_public_url" {
  value = module.hostname_auth.url
}

output "public_urls" {
  value = merge(
    { for k, m in module.hostnames : k => m.url },
    var.deploy_openbao ? { bao = module.hostname_openbao.url } : {},
  )
}

output "hosts" {
  value = merge(
    { for k, m in module.hostnames : k => m.host },
    var.deploy_openbao ? { bao = module.hostname_openbao.host } : {},
  )
}

output "application_ids" {
  value = { for k, m in module.apps : k => m.application_id }
}
