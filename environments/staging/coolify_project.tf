# Staging uses the Beskid project created by production (resolve UUID in CI or tfvars).

locals {
  coolify_project_uuid = var.project_uuid
}

check "project_uuid_for_staging" {
  assert {
    condition     = local.coolify_project_uuid != null && local.coolify_project_uuid != ""
    error_message = "Set project_uuid for staging (CI resolves the Beskid project by name after production apply)."
  }
}
