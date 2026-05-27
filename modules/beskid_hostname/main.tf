# Canonical Beskid public hostnames per environment.
#
# Patterns:
#   site     → beskid-lang.org | stg.beskid-lang.org
#   auth, …  → auth.beskid-lang.org | stg-auth.beskid-lang.org
#   pckg     → pckg.beskid-lang.org | stg-pckg.beskid-lang.org

locals {
  env_prefix = lookup({
    production = ""
    staging    = "stg-"
  }, var.environment, "stg-")

  apex_host = lookup({
    production = var.base_domain
    staging    = "stg.${var.base_domain}"
  }, var.environment, "stg.${var.base_domain}")

  hyphenated_host = var.environment == "production" ? (
    "${var.service}.${var.base_domain}"
    ) : (
    "${local.env_prefix}${var.service}.${var.base_domain}"
  )

  host = var.service == "site" ? local.apex_host : local.hyphenated_host
}
