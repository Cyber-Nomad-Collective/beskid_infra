# Legacy import (Beskid_MANUAL project only)

**Do not use for greenfield.** See [greenfield.md](greenfield.md).

Import existing Coolify resources from the deprecated **Beskid_MANUAL** project (`tosg8kc80g8go00sgcswsccg`) only if you intentionally migrate legacy apps.

## Import commands

```bash
cd environments/production
tofu init

tofu import 'coolify_project.beskid[0]' <project-uuid>
tofu import 'module.stack.module.apps["site"].coolify_application.this' rsso488sscg80kookoo00sk4
```

Set `manage_coolify_project = false` and `project_uuid = "..."` when importing an existing project.
