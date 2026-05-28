resource "random_password" "pckg_postgres" {
  count   = try(var.enable_services["pckg"], false) ? 1 : 0
  length  = 32
  special = true
}
