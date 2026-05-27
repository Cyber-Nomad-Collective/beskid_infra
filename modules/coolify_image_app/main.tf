# Coolify application that pulls a GHCR image.
#
# IMPORTANT: This module targets the `SierraJC/coolify` Terraform provider.
# The provider has partial coverage — verify attributes against the provider
# version you pin.  Import existing apps first, then Terraform manages them.

locals {
  # GHCR registry is public — no pull secret needed when Coolify server
  # has ghcr.io credentials configured.
  image_name = "ghcr.io/cyber-nomad-collective/${var.app_name}"
}

# --- Application resource ---
#
# The application is either imported (terraform import) for existing apps
# or created fresh.  Compose-based apps use docker-compose.yml from the
# repository.
#
# provider schema snapshot (SierraJC/coolify):
#   coolify_application {
#     name           = string
#     project_uuid   = string
#     server_uuid    = string
#     environment_name = string
#     git_repository = string
#     git_branch     = string
#     base_directory = string
#     compose_path   = string
#     ports_exposes  = string
#     fqdn           = string (optional)
#     health_check_* = ...
#     environment_variables = map(string) (if provider supports)
#   }
#
# If the provider does not expose env_vars, use a null_resource with
# the Coolify API directly, or set them in the UI until provider support lands.

resource "coolify_application" "app" {
  # These attributes are inferred from the provider schema — adjust after
  # terraform validate against the actual provider binary.
  name         = var.app_name
  project_uuid = var.project_uuid
  server_uuid  = var.server_uuid

  git_repository = var.git_repository
  git_branch     = var.git_branch
  base_directory = var.base_directory

  ports_exposes = tostring(var.expose_port)
  fqdn          = var.fqdn

  health_check_enabled = true
  health_check_path    = var.health_check_path

  # IMAGE_TAG is the single required env var for the compose file.
  # Other secrets come from OpenBao at `tofu apply` time.
}

# --- Environment variables via Coolify API ---
#
# If the provider omits env var management, apply them with a
# provisioner or external data source.  The compose file already defaults
# IMAGE_TAG to "main", so env vars are optional for basic operation.
#
# For staging: set IMAGE_TAG = "staging" via Coolify UI or this module's
# var.image_tag when the provider supports it.

# --- OpenBao secrets lookup ---
#
# Runtime secrets (AUTH_HUB_PUBLIC_URL, SESSION_SECRET, etc.) are stored
# in OpenBao and read at apply time.  They are NOT committed to git.
#
# data "openbao_kv_secret_v2" "app_secrets" {
#   count = var.openbao_path != null ? 1 : 0
#   path = var.openbao_path
# }
#
# Use data.openbao_kv_secret_v2[0].data to populate Coolify env vars
# when the provider supports bulk env configuration.
