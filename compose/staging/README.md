# Staging lane

Staging uses the shared template at `../production/docker-compose.yml`, rendered
from the exact same release manifest format as production. The renderer changes
the Compose project name to `beskid-platform-staging` and replaces every Beskid
image with its immutable digest.

Lane configuration is `../../config/coolify-staging.json`; hostnames are in
`../../config/domains.json`. Staging must use separate volumes, Postgres data,
OAuth callbacks, session secrets, Coolify service UUID, and OpenBao prefix from
production.

Successful main delivery runs deploy staging automatically. No `stg` branch or
mutable `staging` image tag participates in deployment.
