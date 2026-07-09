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
- `blog.ridewithmin.com`
- `git.ridewithmin.com`
- `vault.ridewithmin.com`
- `jamye-plz.ridewithmin.com`
- `status.ridewithmin.com`
- `docs.ridewithmin.com`

Unmatched requests fall through to `http_status:404`. The tunnel credential
is the `cloudflare/cloudflared_tunnel_credentials` SOPS secret.

## Caddy (`services/ingress.nix`)

Caddy selects the internal backend by public hostname.

| Hostname | Backend | Notes |
| --- | --- | --- |
| `home.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:8082` | |
| `blog.ridewithmin.com` | local `file_server` from the Nix store | Static Astro blog, built from the `blog` flake input |
| `git.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:3000` | |
| `vault.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:8222` | |
| `docs.ridewithmin.com` | local `file_server` from the Nix store | This docs site, built from the flake's `docs` package |
| `jamye-plz.ridewithmin.com` | `http://alfheim.tail6fc192.ts.net:8080` | jamye-plz on alfheim |
| `status.ridewithmin.com` | `http://127.0.0.1:3001` | status-page paths only, `404` otherwise |
| `beszel.ridewithmin.com` | `http://127.0.0.1:8090` | tailnet clients only, `404` otherwise |
| `logs.ridewithmin.com` | `http://127.0.0.1:9428` | tailnet clients only, `/` redirects to the VictoriaLogs web UI |

Certificates are issued through ACME DNS challenges using Caddy's Cloudflare
DNS plugin. The Cloudflare API token is injected as an environment variable
from the `cloudflare/caddy_env` SOPS secret.

## The tailnet-only route pattern

Beszel and the VictoriaLogs UI are not part of the tunnel's public hostname
list; Caddy restricts them to Tailscale address ranges.

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
   yggdrasil's tailnet address). Public tunnel routes can be registered with:

    ```bash
    cloudflared tunnel route dns 7464b4c7-93aa-4ef0-990d-76d6b0bb158a <name>.ridewithmin.com
    ```

4. Open a PR, wait for CI, then merge and let CD deploy the change.
