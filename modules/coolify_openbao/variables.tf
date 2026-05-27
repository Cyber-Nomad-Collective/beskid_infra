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

variable "app_name" {
  type    = string
  default = "beskid-openbao"
}

variable "description" {
  type    = string
  default = "OpenBao KV for Beskid platform secrets"
}

variable "domains" {
  description = "Public hostname for Coolify (Let's Encrypt via Traefik)."
  type        = string
}

variable "openbao_version" {
  type    = string
  default = "2.1.0"
}

variable "instant_deploy" {
  type    = bool
  default = true
}

variable "auto_deploy" {
  type    = bool
  default = false
}
