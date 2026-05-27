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
  description = "Public hostname (no scheme). Passed to coolify_service.urls with expose_port."
  type        = string
}

variable "expose_port" {
  description = "Container port exposed for OpenBao; included in Coolify urls (required by Coolify UI for :8200 services)."
  type        = number
  default     = 8200
}

variable "compose_service_name" {
  description = "Docker Compose service key; must match SERVICE_FQDN_<NAME>_PORT in compose."
  type        = string
  default     = "openbao"
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
