---
icon: fontawesome/solid/shield-halved
---

# Security model

Who can reach what, and why. The model has four boundaries: public Internet,
the private home LAN, the tailnet, and localhost.

## Access tiers

| Tier | Who | What they can reach |
| --- | --- | --- |
| **Public Internet** | anyone | Only hostnames routed through Cloudflare Tunnel: `home`, `blog`, `git`, `vault`, `jamye-plz`, `status`, `docs` |
| **Home LAN** | devices on `192.168.0.0/24` | AdGuard Home DNS at `192.168.0.53:53` |
| **Tailnet** | devices in the Tailscale tailnet | Everything above, plus the `beszel` and `logs` routes, plus direct host/port access per Tailscale ACLs (the trusted `tailscale0` interface exposes e.g. Beszel `:8090`, VictoriaLogs `:9428`, and vlagent `:9429`) |
| **Localhost** | processes on the host itself | Uptime Kuma bound to `127.0.0.1`; journald → vlagent hand-off on each host |

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

The NixOS firewall is enabled on every host. The home hosts accept SSH `22` on
their host interfaces, but the ipTIME NAT router does not expose it to the
public Internet without a port-forward. Direct administration uses the
tailnet. `alfheim` accepts SSH only through the trusted `tailscale0` interface,
and its public OCI address does not answer SSH. Application and monitoring
ports (`3000`, `3001`, `8080`, `8082`, `8090`, `8222`, `9428`, `9429`, ...)
are never opened publicly; tailnet-internal traffic reaches them through the
trusted `tailscale0` interface.

AdGuard Home is the only service opened to the physical home LAN. Its TCP and
UDP `:53` rules require both a source in `192.168.0.0/24` and the reserved
destination `192.168.0.53`. The admin UI on `:3000` is not opened to the LAN.

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
- **ipTIME router state.** DHCP reservations, advertised DNS servers, NAT, and
  port-forwarding rules live in the router. Do not forward AdGuard Home ports
  from the WAN.
