---
icon: fontawesome/solid/shield-halved
---

# Security model

Who can reach what, and why. The model is three concentric rings: public
Internet, tailnet, and localhost.

## Access tiers

| Tier | Who | What they can reach |
| --- | --- | --- |
| **Public Internet** | anyone | Only hostnames routed through Cloudflare Tunnel: `home`, `blog`, `git`, `vault`, `jamye-plz`, `status`, `docs` |
| **Tailnet** | devices in the Tailscale tailnet | Everything above, plus the `beszel` and `logs` routes, plus direct host/port access per Tailscale ACLs (the trusted `tailscale0` interface exposes e.g. Beszel `:8090` and VictoriaLogs `:9428`) |
| **Localhost** | processes on the host itself | Uptime Kuma and vlagent backends bound to `127.0.0.1` |

## Ingress path

Public traffic never hits an open port. `cloudflared` keeps an outbound
tunnel to Cloudflare; requests arrive through it at local Caddy
(`https://localhost:443`), which routes by hostname. Anything not explicitly
routed gets `404`.

`beszel.ridewithmin.com` and `logs.ridewithmin.com` are deliberately **not**
in the tunnel's hostname list and are gated by Caddy to Tailscale address
ranges (`100.64.0.0/10`, `fd7a:115c:a1e0::/48`). Non-tailnet clients receive
`404`.

The public Uptime Kuma route allows only status-page paths and returns `404`
for everything else.

## Firewall

The NixOS firewall is enabled on every host. Home hosts allow SSH `22`
directly; `alfheim` accepts SSH only through the trusted `tailscale0`
interface. Its public OCI address does not answer SSH at all. Application
and monitoring ports (`3000`, `3001`, `8080`, `8082`, `8083`, `8084`, `8090`, `8222`, `9428`, ...)
are never opened publicly; tailnet-internal traffic reaches them through the
trusted `tailscale0` interface.

## SSH policy

- Root login disabled everywhere.
- Password login disabled everywhere: keys only.
- Operations go through the `poby` operator account (`wheel`, passwordless
  sudo).

## Secrets trust model

Each host decrypts repo secrets with its own SSH host key as the age
identity. Only hosts registered as recipients in `.sops.yaml` (plus the
`poby` operator key) can read them. Plaintext exists only at runtime under
`/run/secrets`, never in the repo or the Nix store. Details in
[Secrets](runbooks/secrets.md).

## What this repo does not control

- **Tailscale ACLs.** Tailnet-internal access control is configured in the
  Tailscale admin console, not declared here.
- **Cloudflare-side policies.** DNS records and any Cloudflare Access rules
  live in the Cloudflare dashboard.
