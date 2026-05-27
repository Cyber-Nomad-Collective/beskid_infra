variable "app_name" {
  description = "Coolify application name"
  type        = string
}

variable "project_uuid" {
  description = "Coolify project UUID"
  type        = string
}

variable "server_uuid" {
  description = "Coolify server UUID"
  type        = string
}

variable "environment_name" {
  description = "Coolify environment name"
  type        = string
  default     = "production"
}

variable "git_repository" {
  description = "GitHub repository (org/repo)"
  type        = string
  default     = "Cyber-Nomad-Collective/beskid"
}

variable "git_branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "base_directory" {
  description = "Base directory for compose file in the repo"
  type        = string
}

variable "compose_path" {
  description = "Relative path to docker-compose.yml from base_directory"
  type        = string
  default     = "/docker-compose.yml"
}

variable "ghcr_image" {
  description = "GHCR image name (without tag)"
  type        = string
}

variable "image_tag" {
  description = "Image tag (main, staging, or sha-*)"
  type        = string
  default     = "main"
}

variable "expose_port" {
  description = "Port to expose"
  type        = number
  default     = 80
}

variable "fqdn" {
  description = "Fully qualified domain name"
  type        = string
  default     = null
}

variable "domains" {
  description = "JSON-encoded domain mapping (service_name -> domain)"
  type        = string
  default     = null
}

variable "env_vars" {
  description = "Additional environment variables { key = value }"
  type        = map(string)
  default     = {}
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "health_check_port" {
  description = "Health check port"
  type        = number
  default     = null
}

variable "volumes" {
  description = "Named volumes to mount"
  type        = list(string)
  default     = []
}

variable "openbao_path" {
  description = "OpenBao KV path for secrets (e.g. secret/beskid/production/auth)"
  type        = string
  default     = null
}
