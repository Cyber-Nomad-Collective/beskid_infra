# Staging environment — isolated from production.
# Same modules, different tags and secret paths.

terraform {
  required_version = ">= 1.8.0"

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

provider "coolify" {}

provider "openbao" {}

# Staging uses the same project but a separate Coolify environment
resource "coolify_environment" "staging" {
  project_uuid = var.project_uuid
  name         = "staging"
}

module "beskid_site" {
  source = "../../modules/coolify_image_app"

  app_name         = "beskid-site-staging"
  project_uuid     = var.project_uuid
  server_uuid      = var.server_uuid
  environment_name = "staging"
  git_repository   = "Cyber-Nomad-Collective/beskid"
  git_branch       = "staging"
  base_directory   = "/site"

  image_tag   = "staging"
  expose_port = 80

  openbao_path = "secret/beskid/staging/site"
}

module "beskid_auth" {
  source = "../../modules/coolify_image_app"

  app_name         = "beskid-auth-staging"
  project_uuid     = var.project_uuid
  server_uuid      = var.server_uuid
  environment_name = "staging"
  git_repository   = "Cyber-Nomad-Collective/beskid"
  git_branch       = "staging"
  base_directory   = "/site/auth"

  image_tag   = "staging"
  expose_port = 8090

  openbao_path = "secret/beskid/staging/auth"
}

variable "project_uuid" { type = string }
variable "server_uuid" { type = string }
