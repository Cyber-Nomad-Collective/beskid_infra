variable "mount" {
  type    = string
  default = "secret"
}

variable "openbao_lane" {
  description = "production or staging (KV path segment)."
  type        = string
}

variable "coolify_endpoint" {
  type = string
}

variable "coolify_api_token" {
  type      = string
  sensitive = true
}

variable "project_uuid" {
  type = string
}

variable "server_uuid" {
  type = string
}

variable "image_tag" {
  type = string
}

variable "service_secrets" {
  description = "Per-service KV payloads (auth, site, …)."
  type        = map(map(string))
  default     = {}
}
