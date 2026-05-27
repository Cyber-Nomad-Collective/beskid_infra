# Vendored terraform-provider-coolify (Beskid fork)

Shallow copy of [arcusis/terraform-provider-coolify](https://github.com/arcusis/terraform-provider-coolify) **v1.1.18** (no `.git` in this tree).

Built by `scripts/ci/install-coolify-provider.sh` as provider version **`1.1.18-beskid`**.

## Beskid changes (vs upstream v1.1.18)

| Change | Files |
|--------|--------|
| `destination_uuid` on create (multi-destination servers) | `service.go`, `application.go`, `database_postgresql.go` |
| `urls` + `force_domain_override` on `coolify_service` (compose custom domains) | `service.go`, `project.go` (`kindURLs`) |
| Provider version string | `main.go` |

Upstream already base64-encodes `docker_compose_raw` on POST/PATCH.

## Refresh from upstream

```bash
VERSION=1.1.18
rm -rf /tmp/coolify-upstream
git clone --depth 1 --branch "v${VERSION}" https://github.com/arcusis/terraform-provider-coolify.git /tmp/coolify-upstream
rsync -a --delete --exclude '.git' /tmp/coolify-upstream/ beskid_infra/vendor/terraform-provider-coolify/
# Re-apply Beskid edits (this file + service/application/database_postgresql/project.go/main.go)
```
