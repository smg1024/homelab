---
icon: fontawesome/solid/server
---

# yggdrasil

The public entry point and lightweight infrastructure node. It only has 4 GB
of RAM, so the rule is to **keep it lightweight**. No applications run here.

## Responsibilities

- Maintain the Cloudflare Tunnel (`cloudflared`)
- Run the Caddy reverse proxy to route public domains to internal services
- Serve the Uptime Kuma public status page
- Run Prometheus for node metrics and alert rule evaluation
- Serve Grafana dashboards (tailnet-restricted Caddy route)
- Run the Loki log store
- Serve this documentation site publicly through Cloudflare Tunnel

## Loaded service modules

```text
services/ingress.nix      # Caddy + Cloudflare DNS plugin
services/cloudflared.nix  # Cloudflare Tunnel
services/uptime-kuma.nix
services/prometheus/
services/loki.nix
services/grafana/
services/docs-site.nix    # this documentation site
```

## Local ports

| Port | Service | Binding |
| --- | --- | --- |
| `443` | Caddy | public (Tunnel origin) |
| `3001` | Uptime Kuma | localhost |
| `3003` | Grafana | localhost |
| `8081` | Grafana image renderer | localhost |
| `9090` | Prometheus | localhost |
| `9100` | node_exporter | not opened on the firewall |

## Health checks

```bash
systemctl is-active caddy cloudflared-tunnel-* uptime-kuma
systemctl is-active prometheus grafana loki
curl -fsS http://127.0.0.1:9090/-/ready
curl -fsS http://127.0.0.1:3003/api/health | jq
```
