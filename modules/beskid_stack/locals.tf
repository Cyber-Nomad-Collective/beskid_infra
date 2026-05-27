locals {
  cfg = {
    production = {
      coolify_environment = "production"
      image_tag           = "main"
      openbao_lane        = "production"
      name_suffix         = ""
    }
    staging = {
      coolify_environment = "staging"
      image_tag           = "staging"
      openbao_lane        = "staging"
      name_suffix         = "-staging"
    }
  }[var.environment]

  ghcr_org = var.ghcr_org

  service_catalog = {
    site = {
      ghcr_image      = "ghcr.io/${local.ghcr_org}/beskid-site"
      port            = 80
      openbao_service = "site"
      storage_volumes = {}
      description     = "Beskid documentation site"
    }
    auth = {
      ghcr_image      = "ghcr.io/${local.ghcr_org}/beskid-auth"
      port            = 8090
      openbao_service = "auth"
      storage_volumes = {
        data = {
          name       = "auth-data"
          mount_path = "/app/site/auth/data/runtime"
        }
      }
      description = "Beskid auth hub"
    }
    tracker = {
      ghcr_image      = "ghcr.io/${local.ghcr_org}/beskid-tracker"
      port            = 3000
      openbao_service = "tracker"
      storage_volumes = {
        data = {
          name       = "tracker-data"
          mount_path = "/app/beskid_tracker/data/runtime"
        }
      }
      description = "Beskid issue tracker"
    }
    nexus = {
      ghcr_image      = "ghcr.io/${local.ghcr_org}/beskid-nexus"
      port            = 8452
      openbao_service = "nexus"
      storage_volumes = {
        data = {
          name       = "nexus-data"
          mount_path = "/data/gitnexus"
        }
      }
      description = "Beskid GitNexus"
    }
  }

  enabled_ghcr_services = {
    for name, cfg in local.service_catalog :
    name => cfg
    if try(var.enable_services[name], false)
  }
}
