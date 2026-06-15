---
icon: fontawesome/solid/door-open
---

# Ingress

All external traffic enters through **Cloudflare Tunnel** instead of directly
exposed ports. Both `cloudflared` and Caddy run on `yggdrasil`.

## Cloudflare Tunnel (`services/cloudflared.nix`)

The tunnel sends the following public hostnames to local Caddy on yggdrasil
(`https://localhost:443`). The request `Host` header and TLS origin server
name are set to match each public hostname.

- `home.ridewithmin.com`
- `git.ridewithmin.com`
- `vault.ridewithmin.com`
- `status.ridewithmin.com`
- `docs.ridewithmin.com`

Unmatched requests fall through to `http_status:404`. The tunnel credential
is the `cloudflare/cloudflared_tunnel_credentials` SOPS secret.

## Caddy (`services/ingress.nix`)

Caddy selects the internal backend by public hostname.

| Hostname | Backend | Notes |
| --- | --- | --- |
| `home.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:8082` | |
| `git.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:3000` | |
| `vault.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:8222` | |
| `status.ridewithmin.com` | `http://127.0.0.1:3001` | status-page paths only, `404` otherwise |
| `grafana.ridewithmin.com` | `http://127.0.0.1:3003` | tailnet clients only, `404` otherwise |
| `docs.ridewithmin.com` | static files (`file_server`) | public |

Certificates are issued through ACME DNS challenges using Caddy's Cloudflare
DNS plugin. The Cloudflare API token is injected as an environment variable
from the `cloudflare/caddy_env` SOPS secret.

## The tailnet-only route pattern

Grafana is not part of the tunnel's public hostname list; Caddy restricts it
to Tailscale address ranges.

```caddy
@tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48

handle @tailnet {
  # ...backend...
}

respond 404
```

## Exposing a new service {#expose-a-service}

1. Add `virtualHosts."<name>.ridewithmin.com"` to `services/ingress.nix`.
2. For a public service, add the same hostname to the `ingress` block in
   `services/cloudflared.nix` (skip for tailnet-only routes).
3. Add a DNS record in Cloudflare (public: Tunnel CNAME, tailnet-only:
   yggdrasil's tailnet address).
4. Validate, then deploy with `just switch yggdrasil`.
