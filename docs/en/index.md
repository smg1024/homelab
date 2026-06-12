# Homelab

This site is the operations documentation for a homelab made up of NixOS
machines. Everything is declared in a single Nix flake in the
[Git repository](https://git.ridewithmin.com) — **the repo is the single
source of truth**. Machines are never fixed by editing config on a host;
changes are made in the repo, committed, then deployed.

## Hosts at a glance

| Host | Role | Architecture | Notes |
| --- | --- | --- | --- |
| `yggdrasil` | Edge/infra node — Cloudflare Tunnel, Caddy, monitoring stack | `x86_64-linux` | 4 GB RAM, keep it lightweight |
| `midgard` | Application host — Forgejo, Vaultwarden, Homepage, Podman | `x86_64-linux` | |
| `alfheim` | Experimental OCI ARM VM | `aarch64-linux` | SSH over the tailnet only |

## Repository layout

```text
flake.nix        # pins nixos-26.05, 3 nixosConfigurations + docs package
modules/         # system modules shared by every host
services/        # service modules (ingress, monitoring, forgejo, ...)
hosts/<host>/    # per-host default.nix + hardware + disko
home/poby/       # Home Manager profiles for the poby operator
secrets/         # sops-nix encrypted YAML
docs/            # this documentation site (MkDocs Material)
```

## Public URLs

| URL | Service | Access |
| --- | --- | --- |
| `https://home.ridewithmin.com` | Homepage dashboard | Public (Cloudflare Tunnel) |
| `https://git.ridewithmin.com` | Forgejo | Public (Cloudflare Tunnel) |
| `https://vault.ridewithmin.com` | Vaultwarden | Public (Cloudflare Tunnel) |
| `https://status.ridewithmin.com` | Uptime Kuma status page | Public (status-page paths only) |
| `https://grafana.ridewithmin.com` | Grafana | Tailnet only |
| `https://docs.ridewithmin.com` | This documentation site | Tailnet only |

## Read next

- [Architecture](architecture.md) — traffic flow and network boundaries
- [Deploy & rollback](runbooks/deploy.md) — how changes reach the hosts
- [Secrets](runbooks/secrets.md) — the sops-nix workflow
