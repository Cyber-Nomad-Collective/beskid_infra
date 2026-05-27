terraform {
  required_version = ">= 1.6.0"

  required_providers {
    coolify = {
      source  = "terraform.io/arcusis/coolify"
      version = ">= 0.3.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 4.0"
    }
  }
}
