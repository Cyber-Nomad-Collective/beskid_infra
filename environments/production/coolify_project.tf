# Greenfield: OpenTofu manages the Beskid project (legacy Beskid_MANUAL is untouched).
# CI runs scripts/ci/ensure-coolify-project-import.sh after init so an existing project is
# imported instead of created again when state was lost or apply retried.

resource "coolify_project" "beskid" {
  count = var.manage_coolify_project ? 1 : 0

  name        = var.coolify_project_name
  description = var.coolify_project_description
}

locals {
  # arcusis/coolify exposes the project UUID as `.id` (not `.uuid`).
  coolify_project_uuid = coalesce(
    var.project_uuid,
    try(coolify_project.beskid[0].id, null),
  )
}

check "project_uuid_resolved" {
  assert {
    condition     = local.coolify_project_uuid != null && local.coolify_project_uuid != ""
    error_message = "Coolify project UUID missing — set manage_coolify_project=true (production) or project_uuid (staging)."
  }
}
