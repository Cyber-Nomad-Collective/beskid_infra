terraform {
  required_version = ">= 1.6.0"

  required_providers {
    coolify = {
      source  = "registry.terraform.io/arcusis/coolify"
      version = ">= 0.3.0"
    }
  }
}
