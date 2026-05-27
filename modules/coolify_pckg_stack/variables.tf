variable "environment" {
  type = string
}

variable "base_domain" {
  type    = string
  default = "beskid-lang.org"
}

variable "app_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "project_uuid" {
  type = string
}

variable "server_uuid" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "ghcr_image" {
  type    = string
  default = "ghcr.io/cyber-nomad-collective/beskid-pckg"
}

variable "image_tag" {
  type = string
}

variable "auth_hub_public_url" {
  description = "Public auth hub URL for this lane (from auth hostname module)."
  type        = string
}

variable "postgres_db" {
  type    = string
  default = "pckgdb"
}

variable "postgres_user" {
  type    = string
  default = "postgres"
}

variable "postgres_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "pckg_db_host_override" {
  description = "Optional Postgres hostname if Coolify internal DNS name differs."
  type        = string
  default     = null
}

variable "openbao_enabled" {
  type    = bool
  default = true
}

variable "openbao_mount" {
  type    = string
  default = "secret"
}

variable "openbao_secret_path" {
  type = string
}

variable "static_env" {
  type    = map(string)
  default = {}
}

variable "manage_env" {
  type    = bool
  default = true
}

variable "auto_deploy" {
  type    = bool
  default = false
}

variable "instant_deploy" {
  type    = bool
  default = false
}
