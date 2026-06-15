---
icon: fontawesome/solid/network-wired
---

# Architecture

The setup is split into an edge/infra node (`yggdrasil`) and an application
node (`midgard`). External traffic enters only through **Cloudflare Tunnel →
Caddy** instead of directly exposed ports, and the **Tailscale tailnet** is
the internal network boundary between hosts.

```mermaid
flowchart TD
    internet["Internet users"]
    cloudflare["Cloudflare<br/>DNS / Tunnel edge"]

    subgraph yggdrasil["yggdrasil: edge / infra node"]
        cloudflared["cloudflared<br/>Cloudflare Tunnel client"]
        caddy["Caddy<br/>HTTPS ingress / reverse proxy"]
        kuma["Uptime Kuma<br/>127.0.0.1:3001"]
        prometheus["Prometheus<br/>127.0.0.1:9090"]
        grafana["Grafana<br/>127.0.0.1:3003"]
        yNodeExporter["node_exporter<br/>:9100"]
    end

    subgraph tailnet["Tailscale tailnet"]
        midgardDns["midgard.tail6fc192.ts.net"]

        subgraph midgard["midgard: application host"]
            homepage["Homepage dashboard<br/>:8082"]
            forgejo["Forgejo<br/>:3000"]
            vaultwarden["Vaultwarden<br/>:8222"]
            mNodeExporter["node_exporter<br/>:9100"]
        end
    end

    internet --> cloudflare
    cloudflare --> cloudflared
    cloudflared -->|"home/git/vault/status.ridewithmin.com<br/>https://localhost:443"| caddy

    caddy -->|"status.ridewithmin.com"| kuma
    caddy -->|"home.ridewithmin.com"| homepage
    caddy -->|"git.ridewithmin.com"| forgejo
    caddy -->|"vault.ridewithmin.com"| vaultwarden
    caddy -->|"grafana.ridewithmin.com<br/>tailnet only"| grafana

    caddy -.->|backend access over Tailscale| midgardDns
    midgardDns -.-> homepage
    midgardDns -.-> forgejo
    midgardDns -.-> vaultwarden

    prometheus --> yNodeExporter
    prometheus -.->|scrape over Tailscale| mNodeExporter
    grafana --> prometheus
```

Who can reach what across these boundaries (public Internet, tailnet,
localhost) is covered in the [security model](security.md).

## Shared system configuration

All hosts load the same common modules through `flake.nix`.

| Module | Purpose |
| --- | --- |
| `modules/base.nix` | flakes/`nix-command`, systemd-boot, NetworkManager, firewall |
| `modules/gc.nix` | weekly Nix GC + automatic store optimisation |
| `modules/swap.nix` | zram swap (no separate swap partition) |
| `modules/users.nix` | operator `poby` (`wheel`, passwordless sudo) |
| `modules/ssh.nix` | OpenSSH, password/root login disabled |
| `modules/tailscale.nix` | Tailscale |
| `modules/secrets.nix` | sops-nix base configuration |
| `services/node-exporter.nix` | node_exporter on every host (`:9100`) |
| `services/alloy.nix` | log collection (shipped to Loki) |

## Storage

Disk layout is declared with `disko`. All hosts use a simple single-disk GPT
layout.

```text
GPT partition table
512M EFI System Partition  -> /boot, vfat
remaining disk             -> /, ext4
```

## User environment

Home Manager is enabled through the NixOS module and applied as part of each
host switch. It is used **only for the `poby` operator environment**, not for
long-running services. The shared profiles (`home/poby/base.nix`, `ops.nix`)
carry shell/Git/tmux configuration and operator tools such as `age`, `sops`,
and `just`; per-host profiles add host-specific aliases.
