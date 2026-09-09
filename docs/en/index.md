---
icon: fontawesome/solid/house
---

# Homelab

This site documents a NixOS homelab. A single Nix flake in the
[Git repository](https://git.ridewithmin.com) declares the full system. The
repo is the source of truth: edit and validate changes there, commit them, and
then deploy. Do not fix configuration directly on a host.

## Hosts at a glance

| Host | Role | Architecture | Notes |
| --- | --- | --- | --- |
| `yggdrasil` | Edge/infra node: Cloudflare Tunnel, Caddy, monitoring stack | `x86_64-linux` | 4 GB RAM, keep it lightweight |
| `midgard` | Application host: static sites, Forgejo, Vaultwarden, Homepage, Podman | `x86_64-linux` | |
| `alfheim` | OCI ARM application node: jamye-plz | `aarch64-linux` | SSH over the tailnet only |

## Repository layout

```text
flake.nix        # pins nixos-26.05, 3 nixosConfigurations + docs package
modules/         # system modules shared by every host
services/        # service modules (ingress, monitoring, forgejo, ...)
hosts/<host>/    # per-host default.nix + hardware + disko
home/poby/       # Home Manager profiles for the poby operator
secrets/         # sops-nix encrypted YAML
docs/            # this documentation site (Zensical)
```

## Service URLs

| URL | Service | Access |
| --- | --- | --- |
| `https://home.ridewithmin.com` | Homepage dashboard | Public (Cloudflare Tunnel) |
| `https://blog.ridewithmin.com` | Dev with Min blog | Public (Cloudflare Tunnel) |
| `https://git.ridewithmin.com` | Forgejo | Public (Cloudflare Tunnel) |
| `https://vault.ridewithmin.com` | Vaultwarden | Public (Cloudflare Tunnel) |
| `https://jamye-plz.ridewithmin.com` | jamye-plz | Public (Cloudflare Tunnel) |
| `https://status.ridewithmin.com` | Uptime Kuma status page | Public (status-page paths only) |
| `https://beszel.ridewithmin.com` | Beszel (metrics + alerts) | Tailnet only |
| `https://logs.ridewithmin.com` | VictoriaLogs (log search) | Tailnet only |
| `https://docs.ridewithmin.com` | This documentation site | Public (Cloudflare Tunnel) |

## Read next

- [Design principles](principles.md): the rules everything follows
- [Architecture](architecture.md): traffic flow and components
- [Deploy & rollback](runbooks/deploy.md): how changes reach the hosts
- [Roadmap](roadmap.md): where this is headed
