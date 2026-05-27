output "application_id" {
  value = coolify_application.app.id
}

output "database_id" {
  value = coolify_database_postgresql.this.id
}

output "public_url" {
  value = module.hostname.url
}

output "host" {
  value = module.hostname.host
}
