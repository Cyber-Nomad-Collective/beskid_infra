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

variable "base_domain" {
  type    = string
  default = "beskid-lang.org"
}

variable "openbao_enabled" {
  type    = bool
  default = true
}

variable "project_uuid" {
  description = "UUID of coolify_project.beskid (from production apply or CI resolve)."
  type        = string
  default     = null
  nullable    = true
}

variable "server_uuid" {
  type = string
}

variable "destination_uuid" {
  description = "Coolify destination for server (localhost → coolify network)."
  type        = string
}

variable "manage_environment" {
  type    = bool
  default = true
}

variable "enable_services" {
  type = map(bool)
  default = {
    site    = true
    auth    = true
    tracker = true
    nexus   = true
    pckg    = true
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
