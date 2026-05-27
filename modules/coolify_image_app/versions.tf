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
