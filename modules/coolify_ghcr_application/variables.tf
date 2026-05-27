variable "app_name" {
  type = string
}

variable "description" {
  type    = string
  default = null
}

variable "project_uuid" {
  type = string
}

variable "server_uuid" {
  type = string
}

variable "destination_uuid" {
  description = "Coolify destination on server (required when server has multiple destinations)."
  type        = string
}

variable "environment_name" {
  type = string
}

variable "ghcr_image" {
  description = "Image repository without tag, e.g. ghcr.io/cyber-nomad-collective/beskid-site."
  type        = string
}

variable "image_tag" {
  type = string
}

variable "expose_port" {
  type = number
}

variable "domains" {
  description = "Comma-separated hostnames for Let's Encrypt (Traefik HTTP-01)."
  type        = string
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
  description = "KV path under mount, e.g. beskid/staging/auth."
  type        = string
}

variable "static_env" {
  type    = map(string)
  default = {}
}

variable "manage_env" {
  description = "When true, coolify_envs_bulk replaces all app env vars in Coolify."
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

variable "storage_volumes" {
  description = "Named Docker volumes to attach."
  type = map(object({
    name       = string
    mount_path = string
    readonly   = optional(bool, false)
  }))
  default = {}
}
