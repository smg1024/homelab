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
- Run the Beszel hub for metrics and alerting (tailnet-restricted Caddy route)
- Run the VictoriaLogs log store and query UI (tailnet-restricted Caddy route)

## Loaded service modules

```text
services/ingress.nix      # Caddy + Cloudflare DNS plugin
services/cloudflared.nix  # Cloudflare Tunnel
services/uptime-kuma.nix
services/victorialogs.nix
services/beszel/hub.nix
```

## Local ports

| Port | Service | Binding |
| --- | --- | --- |
| `443` | Caddy | public (Tunnel origin) |
| `3001` | Uptime Kuma | localhost |
| `8090` | Beszel hub | all interfaces; reachable only via the trusted `tailscale0` interface |
| `9428` | VictoriaLogs | all interfaces; reachable only via the trusted `tailscale0` interface |
| `9429` | vlagent | all interfaces; tailnet-reachable via the trusted `tailscale0` interface, fed by journal-upload via localhost |
| `45876` | beszel-agent | not opened on the firewall (agent dials the hub outbound) |

## Health checks

```bash
systemctl is-active caddy cloudflared-tunnel-* uptime-kuma
systemctl is-active beszel-hub victorialogs beszel-agent vlagent
curl -fsS http://127.0.0.1:8090/api/health
curl -fsS http://127.0.0.1:9428/ping
```
