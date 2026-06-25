---
icon: fontawesome/solid/chart-line
---

# Monitoring

The metrics and log stack runs on `yggdrasil`. Uptime Kuma runs the public
endpoint checks and serves the status page.

## Components

| Module | Role | Binding |
| --- | --- | --- |
| `services/prometheus/` | node metrics, alert rule evaluation, 15d retention | `127.0.0.1:9090` |
| `services/grafana/` | dashboards, Prometheus provisioned as default datasource | `127.0.0.1:3003` |
| `services/loki.nix` | log store | localhost |
| `services/alloy.nix` | log collection on each host → ships to Loki (all hosts) | |
| `services/node-exporter.nix` | node metrics (all hosts, systemd collector enabled) | `:9100` |
| `services/uptime-kuma.nix` | public endpoint checks + status page | `127.0.0.1:3001` |

## Prometheus scrape targets

```text
127.0.0.1:9100                  -> yggdrasil node_exporter
midgard.tail6fc192.ts.net:9100  -> midgard node_exporter (over the tailnet)
```

The scrape interval is `3m`.

## Alert rules

Defined in `services/prometheus/node-health-alert-rule.yml`.

- `NodeDown`, `CriticalServiceInactive`, `SystemdServiceFailed`
- `RootDiskLow`, `RootInodesLow`, `RootFilesystemReadOnly`
- `LowMemory`, `HighCpuUsage`, `HighLoad`

!!! warning "No Alertmanager yet"
    Rules are visible in the Prometheus UI, but external notification
    delivery through Alertmanager is not configured yet.

## Access

Grafana, from a tailnet-connected client:

```text
https://grafana.ridewithmin.com
```

Prometheus UI, through SSH port forwarding:

```bash
ssh -L 9090:127.0.0.1:9090 yggdrasil
# open http://127.0.0.1:9090
```

## Health checks

```bash
# on yggdrasil
systemctl is-active prometheus prometheus-node-exporter grafana loki
curl -fsS http://127.0.0.1:9090/-/ready
curl -fsS http://127.0.0.1:9090/api/v1/targets | jq
curl -fsS http://127.0.0.1:3003/api/health | jq
```
