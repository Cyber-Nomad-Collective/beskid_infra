variable "coolify_endpoint" {
  type = string
}

variable "coolify_api_token" {
  type      = string
  sensitive = true
}

variable "openbao_address" {
  type = string
}

variable "openbao_token" {
  type      = string
  sensitive = true
}

variable "openbao_mount" {
  type    = string
  default = "secret"
}

variable "openbao_enabled" {
  type    = bool
  default = true
}

variable "project_uuid" {
  type = string
}

variable "server_uuid" {
  type = string
}

variable "manage_environment" {
  type    = bool
  default = true
}

variable "enable_services" {
  type = map(bool)
  default = {
    site    = false
    auth    = true
    tracker = false
    nexus   = false
    pckg    = false
  }
}

variable "manage_coolify_env" {
  type    = bool
  default = true
}

variable "instant_deploy" {
  type    = bool
  default = false
}
