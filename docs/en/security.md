---
icon: fontawesome/solid/shield-halved
---

# Security model

The security model defines three network boundaries: public Internet, the
tailnet, and localhost. Each boundary has a separate access policy.

## Access tiers

| Tier | Who | What they can reach |
| --- | --- | --- |
| **Public Internet** | anyone | Only hostnames routed through Cloudflare Tunnel: `home`, `blog`, `git`, `vault`, `jamye-plz`, `status`, `docs` |
| **Tailnet** | devices in the Tailscale tailnet | Public services above, plus the `beszel` and `logs` routes, plus direct host/port access per Tailscale ACLs (the trusted `tailscale0` interface exposes e.g. Beszel `:8090`, VictoriaLogs `:9428`, and vlagent `:9429`) |
| **Localhost** | processes on the host itself | Uptime Kuma bound to `127.0.0.1`; journald → vlagent hand-off on each host |

## Ingress path

Public traffic never hits an open port. `cloudflared` keeps an outbound
tunnel to Cloudflare; requests arrive through it at local Caddy
(`https://localhost:443`), which routes by hostname. Anything not explicitly
routed gets `404`.

Caddy serves `beszel.ridewithmin.com` and `logs.ridewithmin.com` outside
Cloudflare Tunnel. It accepts these routes only
from the Tailscale address ranges (`100.64.0.0/10`,
`fd7a:115c:a1e0::/48`). Other clients receive `404`.

The public Uptime Kuma route allows only status-page paths and returns `404`
for everything else.

## Firewall

Every host runs the NixOS firewall. The home hosts accept SSH `22` on
their host interfaces, but the ipTIME NAT router does not expose it to the
public Internet without a port-forward. Direct administration uses the
tailnet. `alfheim` accepts SSH only through the trusted `tailscale0` interface,
and its public OCI address does not answer SSH. Application and monitoring
ports (`3000`, `3001`, `8080`, `8082`, `8090`, `8222`, `9428`, `9429`, ...)
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
- **ipTIME router state.** DHCP reservations, NAT, and port-forwarding rules
  live in the router.
