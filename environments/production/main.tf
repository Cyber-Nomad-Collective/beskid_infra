# Production environment — manages Coolify apps for the Beskid platform.
#
# Resources that already exist in Coolify must be imported:
#   tofu import coolify_project.beskid <project-uuid>
#   tofu import coolify_server.localhost <server-uuid>
#
# Apps:
#   beskid-site   — existing app, import then manage
#   beskid-auth   — new app, create with this config

terraform {
  required_version = ">= 1.8.0"

  # Backend: use a remote state (S3, GCS, or OpenTofu Cloud) so multiple
  # operators can apply without conflicts.  Pick one:
  #
  # backend "s3" {
  #   bucket  = "beskid-tfstate"
  #   key     = "beskid_infra/production/terraform.tfstate"
  #   region  = "eu-central-1"
  #   encrypt = true
  # }
  #
  # backend "pg" { ... }
  #
  # For bootstrap, keep state local — move to remote before staging.

  required_providers {
    coolify = {
      source  = "github.com/SierraJC/coolify"
      version = ">= 0.0.1"
    }
    openbao = {
      source  = "OpenBao/openbao"
      version = ">= 0.7.0"
    }
  }
}

# --- Provider configuration ---

provider "coolify" {
  # COOLIFY_URL and COOLIFY_API_TOKEN are read from environment variables.
  # Set before running tofu:
  #   export COOLIFY_URL="https://your-coolify-instance"
  #   export COOLIFY_API_TOKEN="your-api-token"
}

provider "openbao" {
  # OpenBao (HashiCorp Vault fork) for runtime secrets.
  # Set OPENBAO_ADDR and OPENBAO_TOKEN before running tofu apply.
  #
  # address = var.openbao_addr is automatically read from OPENBAO_ADDR
}

# --- Coolify resources (import existing, create new) ---

# Project — import existing
resource "coolify_project" "beskid" {
  name        = "Beskid"
  description = "Beskid language platform"
}

# Server — import existing (localhost where Coolify runs)
resource "coolify_server" "beskid" {
  name = "beskid"
}

# Environment — already exists as "production" (id: 9)
resource "coolify_environment" "production" {
  project_uuid = coolify_project.beskid.uuid
  name         = "production"
}

# --- Application: beskid site ---

# EXISTING APP — import before applying:
#   tofu import module.beskid_site.coolify_application.app rsso488sscg80kookoo00sk4
module "beskid_site" {
  source = "../modules/coolify_image_app"

  app_name        = "beskid-site"
  project_uuid    = coolify_project.beskid.uuid
  server_uuid     = coolify_server.beskid.uuid
  environment_name = "production"
  git_repository  = "Cyber-Nomad-Collective/beskid"
  git_branch      = "main"
  base_directory  = "/site"

  image_tag    = "main"
  expose_port  = 80
  fqdn         = "beskid-lang.org"

  health_check_path = "/"

  # OpenBao path for runtime secrets
  openbao_path = "secret/beskid/production/site"
}

# --- Application: beskid auth ---

# NEW APP — will be created by tofu apply
module "beskid_auth" {
  source = "../modules/coolify_image_app"

  app_name        = "beskid-auth"
  project_uuid    = coolify_project.beskid.uuid
  server_uuid     = coolify_server.beskid.uuid
  environment_name = "production"
  git_repository  = "Cyber-Nomad-Collective/beskid"
  git_branch      = "main"
  base_directory  = "/site/auth"

  image_tag    = "main"
  expose_port  = 8090
  fqdn         = "auth.beskid-lang.org"

  health_check_path = "/api/v1/health"
  health_check_port = 8090

  # Secrets from OpenBao
  openbao_path = "secret/beskid/production/auth"

  env_vars = {
    # These are runtime secrets — populated from OpenBao.
    # COMPOSE_FILE = ".env" is mounted into the container.
    # See docs/openbao-layout.md for the full secret layout.
  }
}
