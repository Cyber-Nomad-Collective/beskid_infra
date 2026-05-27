variable "environment" {
  description = "Logical lane: production or staging (git branch main / stg)."
  type        = string

  validation {
    condition     = contains(["production", "staging"], var.environment)
    error_message = "environment must be production or staging."
  }
}

variable "project_uuid" {
  type = string
}

variable "server_uuid" {
  type = string
}

variable "coolify_environment_name" {
  description = "Existing Coolify environment name when manage_environment=false."
  type        = string
  default     = null
}

variable "manage_environment" {
  description = "Create coolify_environment resource (set false when importing existing)."
  type        = bool
  default     = true
}

variable "base_domain" {
  type    = string
  default = "beskid-lang.org"
}

variable "ghcr_org" {
  type    = string
  default = "cyber-nomad-collective"
}

variable "image_tag_override" {
  description = "Override default tag for this lane (main / staging)."
  type        = string
  default     = null
}

variable "enable_services" {
  description = "Toggle each Beskid service in this stack."
  type        = map(bool)
  default = {
    site    = false
    auth    = false
    tracker = false
    nexus   = false
    pckg    = false
  }
}

variable "deploy_openbao" {
  description = "Deploy OpenBao on Coolify before other services."
  type        = bool
  default     = true
}

variable "coolify_endpoint" {
  description = "Coolify base URL (for OpenBao bootstrap KV)."
  type        = string
  default     = ""
}

variable "coolify_api_token" {
  description = "Coolify API token (for OpenBao bootstrap KV)."
  type        = string
  sensitive   = true
  default     = ""
}

variable "openbao_enabled" {
  description = "Read per-service secrets from OpenBao KV at apply time."
  type        = bool
  default     = true
}

variable "seed_openbao_secrets" {
  description = "Write initial KV entries (requires vault provider token)."
  type        = bool
  default     = false
}

variable "openbao_mount" {
  type    = string
  default = "secret"
}

variable "manage_coolify_env" {
  description = "Push env vars via coolify_envs_bulk (disables UI-only vars on apply)."
  type        = bool
  default     = true
}

variable "auto_deploy" {
  type    = bool
  default = false
}

variable "instant_deploy" {
  type    = bool
  default = false
}

variable "service_static_env" {
  description = "Extra static env per service key."
  type        = map(map(string))
  default     = {}
}

variable "pckg_postgres_password" {
  type      = string
  sensitive = true
  default   = null
}
