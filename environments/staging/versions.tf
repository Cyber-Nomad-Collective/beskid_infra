terraform {
  required_version = ">= 1.6.0"
  backend "pg" {}

  required_providers {
    coolify = {
      source  = "registry.terraform.io/arcusis/coolify"
      version = "1.1.18-beskid"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.0"
    }
  }
}
