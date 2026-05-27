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

variable "base_domain" {
  type    = string
  default = "beskid-lang.org"
}

variable "deploy_openbao" {
  description = "Deploy OpenBao on Coolify before site/auth/…"
  type        = bool
  default     = true
}

variable "openbao_enabled" {
  description = "Read per-service KV at apply time (requires initialized OpenBao + openbao_token)."
  type        = bool
  default     = true
}

variable "seed_openbao_secrets" {
  description = "Write bootstrap KV paths (set true when openbao_token is available)."
  type        = bool
  default     = false
}

variable "project_uuid" {
  description = "Optional override. When null, production creates coolify_project.beskid."
  type        = string
  default     = null
  nullable    = true
}

variable "manage_coolify_project" {
  description = "Create the Beskid Coolify project via OpenTofu (true on production only)."
  type        = bool
  default     = true
}

variable "coolify_project_name" {
  type    = string
  default = "Beskid"
}

variable "coolify_project_description" {
  type    = string
  default = "Beskid platform"
}

variable "server_uuid" {
  type = string
}

variable "manage_environment" {
  description = "Create a Coolify environment resource. Leave false for production — Coolify creates a default production environment when the project is created."
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
