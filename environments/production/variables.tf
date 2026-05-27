variable "coolify_endpoint" {
  description = "Coolify base URL (no /api/v1), e.g. https://coolify.bdziam.dev"
  type        = string
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
  description = "Read KV secrets at apply time. Set false only for dry bootstrap."
  type        = bool
  default     = true
}

variable "project_uuid" {
  description = "Existing Beskid Coolify project UUID."
  type        = string
}

variable "server_uuid" {
  type = string
}

variable "manage_environment" {
  description = "When false, use existing production environment (import path)."
  type        = bool
  default     = false
}

variable "coolify_environment_name" {
  type    = string
  default = "production"
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

variable "import_site_app_id" {
  description = "When set, documents import target for existing site app (see docs/coolify-import.md)."
  type        = string
  default     = null
}
