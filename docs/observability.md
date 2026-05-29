# Observability (metrics + logs)

Production metrics and logs for the Beskid platform: **Prometheus**, **Loki**, and **Grafana Alloy** scrape `/metrics` and container logs from `beskid-platform-production`, visualized in Grafana at **https://monitor.beskid-lang.org**.

## Architecture

| Component | Role |
|-----------|------|
| **Grafana Alloy** | Docker SD: scrapes `auth`, `tracker`, `nexus`, `pckg` at `/metrics`; tails container logs → Loki |
| **Prometheus** | TSDB; receives metrics via remote write from Alloy |
| **Loki** | Log aggregation (30-day retention) |
| **Grafana** | Coolify service **Beskid Monitoring** — datasources point at Prometheus + Loki |

Platform apps expose **`GET /metrics`** (Prometheus text format). `/metrics` is not routed on public hostnames — Alloy reaches containers via Docker network IPs.

## Deploy observability stack

1. Create a Coolify compose service from [`compose/monitoring/docker-compose.yml`](../compose/monitoring/docker-compose.yml).
2. Enable **Connect to Predefined Network** and attach the **Beskid Monitoring** network (`o143swr9kk3ph7d7r72lqnvb`) so Grafana can resolve `prometheus:9090` and `loki:3100`.
3. Redeploy after platform images with `/metrics` instrumentation are live.

Service metadata: [`config/coolify-monitoring-observability.json`](../config/coolify-monitoring-observability.json).

## Grafana setup

### Fix root URL (if unhealthy)

In Coolify **Beskid Monitoring** env:

```bash
GF_SERVER_ROOT_URL=https://monitor.beskid-lang.org
```

Remove any `:3000` suffix from the public URL.

### Datasources

Provisioned via [`monitoring/grafana/provisioning/datasources/datasources.yml`](../monitoring/grafana/provisioning/datasources/datasources.yml). Mount into the Grafana container:

```yaml
volumes:
  - /path/to/beskid_infra/monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
  - /path/to/beskid_infra/monitoring/grafana/dashboards:/var/lib/grafana/dashboards:ro
```

Or add manually in Grafana UI:

| Datasource | URL |
|------------|-----|
| Prometheus | `http://prometheus:9090` |
| Loki | `http://loki:3100` |

## Verify

```bash
# Alloy health
curl -s http://127.0.0.1:12345/-/healthy

# Prometheus targets (after platform deploy)
curl -s 'http://127.0.0.1:9090/api/v1/query?query=up' | jq .

# Loki labels
curl -s 'http://127.0.0.1:3100/loki/api/v1/labels' | jq .
```

In Grafana **Explore**:

- Prometheus: `up{project="beskid"}`
- Loki: `{project="beskid"} |= "error"`
- Loki (structured): `{service="gitnexus"} | json | level="error"`

## App env (optional)

| Service | Variable | Default |
|---------|----------|---------|
| auth, tracker | `LOG_LEVEL` | `info` |
| pckg | `OTEL_SERVICE_NAME` | `beskid-pckg` |
| pckg | `OTEL_RESOURCE_ATTRIBUTES` | `deployment.environment=production` |
| nexus | `GITNEXUS_LOG_LEVEL` | `info` |

## Security

- Do not expose `/metrics` on public Coolify domains.
- Grafana admin password stays in Coolify env (`GF_SECURITY_ADMIN_PASSWORD`).
- Alloy requires read-only `docker.sock` — filter limited to `coolify.projectName=beskid`.
