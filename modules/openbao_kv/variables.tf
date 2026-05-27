variable "enabled" {
  description = "When false, skip KV read (bootstrap without OpenBao)."
  type        = bool
  default     = true
}

variable "mount" {
  description = "KV v2 mount (usually secret)."
  type        = string
  default     = "secret"
}

variable "secret_path" {
  description = "Path under mount, e.g. beskid/production/auth (no leading secret/)."
  type        = string
}

variable "static_env" {
  description = "Non-secret env vars merged on top of KV (e.g. IMAGE_TAG)."
  type        = map(string)
  default     = {}
}
