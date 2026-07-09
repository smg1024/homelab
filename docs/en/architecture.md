---
icon: fontawesome/solid/network-wired
---

# Architecture

The setup is split into an edge/infra node (`yggdrasil`), a primary
application node (`midgard`), and a cloud ARM application node (`alfheim`).
External traffic enters only through **Cloudflare Tunnel → Caddy** instead of
directly exposed ports, and the **Tailscale tailnet** is the internal network
boundary between hosts.

```mermaid
flowchart TD
    internet["Internet users"]
    cloudflare["Cloudflare<br/>DNS / Tunnel edge"]

    subgraph yggdrasil["yggdrasil: edge / infra node"]
        cloudflared["cloudflared<br/>Cloudflare Tunnel client"]
        caddy["Caddy<br/>HTTPS ingress / reverse proxy"]
        blog["Dev with Min blog<br/>Caddy file_server"]
        docsSite["Docs site<br/>Caddy file_server"]
        kuma["Uptime Kuma<br/>127.0.0.1:3001"]
        beszelHub["Beszel hub<br/>:8090"]
        vlogs["VictoriaLogs<br/>:9428"]
        yShipper["beszel-agent / vlagent"]
    end

    subgraph tailnet["Tailscale tailnet"]
        midgardDns["midgard.tail6fc192.ts.net"]
        alfheimDns["alfheim.tail6fc192.ts.net"]

        subgraph midgard["midgard: application host"]
            homepage["Homepage dashboard<br/>:8082"]
            forgejo["Forgejo<br/>:3000"]
            vaultwarden["Vaultwarden<br/>:8222"]
            mShipper["beszel-agent / vlagent"]
        end

        subgraph alfheim["alfheim: OCI ARM application host"]
            jamyePlz["jamye-plz<br/>:8080"]
            aShipper["beszel-agent / vlagent"]
        end
    end

    internet --> cloudflare
    cloudflare --> cloudflared
    cloudflared -->|"home/blog/git/vault/jamye-plz/status/docs.ridewithmin.com<br/>https://localhost:443"| caddy

    caddy -->|"status.ridewithmin.com"| kuma
    caddy -->|"home.ridewithmin.com"| homepage
    caddy -->|"blog.ridewithmin.com"| blog
    caddy -->|"git.ridewithmin.com"| forgejo
    caddy -->|"vault.ridewithmin.com"| vaultwarden
    caddy -->|"jamye-plz.ridewithmin.com"| jamyePlz
    caddy -->|"beszel.ridewithmin.com<br/>tailnet only"| beszelHub
    caddy -->|"logs.ridewithmin.com<br/>tailnet only"| vlogs
    caddy -->|"docs.ridewithmin.com"| docsSite

    caddy -.->|backend access over Tailscale| midgardDns
    caddy -.->|backend access over Tailscale| alfheimDns
    midgardDns -.-> homepage
    midgardDns -.-> forgejo
    midgardDns -.-> vaultwarden
    alfheimDns -.-> jamyePlz

    yShipper --> beszelHub
    yShipper --> vlogs
    mShipper -.->|metrics WebSocket + journald logs<br/>over Tailscale| beszelHub
    mShipper -.-> vlogs
    aShipper -.->|metrics WebSocket + journald logs<br/>over Tailscale| beszelHub
    aShipper -.-> vlogs
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
| `services/log-shipper.nix` | journald → VictoriaLogs shipping on every host (journal-upload + vlagent) |
| `services/beszel/agent.nix` | Beszel metrics agent on every host |

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
