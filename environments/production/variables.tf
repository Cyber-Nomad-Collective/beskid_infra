# Production variables
# Sensitive values MUST be set via environment or tfvars file outside version control.

variable "coolify_url" {
  description = "Coolify instance URL"
  type        = string
  sensitive   = false
}

variable "coolify_api_token" {
  description = "Coolify API token (admin scope)"
  type        = string
  sensitive   = true
}

variable "openbao_addr" {
  description = "OpenBao cluster address"
  type        = string
  default     = ""
}

variable "openbao_token" {
  description = "OpenBao token (read secrets at apply time)"
  type        = string
  sensitive   = true
  default     = ""
}
