variable "environment" {
  description = "Deployment lane: production or staging."
  type        = string

  validation {
    condition     = contains(["production", "staging"], var.environment)
    error_message = "environment must be production or staging."
  }
}

variable "service" {
  description = "Logical service key (site, auth, tracker, nexus, pckg, bao)."
  type        = string
}

variable "base_domain" {
  description = "Registered apex domain."
  type        = string
  default     = "beskid-lang.org"
}
