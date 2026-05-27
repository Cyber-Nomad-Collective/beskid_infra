output "data" {
  description = "Raw KV data map (sensitive values)."
  value       = var.enabled ? data.vault_kv_secret_v2.this[0].data : {}
  sensitive   = true
}

output "env" {
  description = "Merged environment variables for Coolify."
  value       = local.merged_env
  sensitive   = true
}
