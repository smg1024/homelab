---
icon: fontawesome/solid/scale-balanced
---

# Design principles

The rules this homelab is run by. When a new decision comes up, check it
against this list first.

## The repo is the server

The Git repository is the single source of truth. Machines are never fixed by
editing config on a host — changes are made in the repo, validated, deployed,
and committed. If a host and the repo disagree, the repo wins; the host gets
rebuilt to match.

## Zero open ports

No application port is ever exposed to the public Internet. External traffic
enters only through Cloudflare Tunnel → Caddy, which means the firewall stays
closed and the attack surface is the tunnel, not the hosts. See the
[security model](security.md) for the full picture.

## The tailnet is the internal boundary

Hosts talk to each other over Tailscale, and tailnet membership is what makes
a machine "inside". Operator-only surfaces (Grafana, this site) are gated by
tailnet address ranges, not passwords on public endpoints.

## Secrets never touch the store

Plaintext secrets never go into `.nix` files or the Nix store. Everything
sensitive lives in sops-encrypted YAML, decrypted at activation time by each
host's own SSH key. A leaked repo leaks nothing.

## Pin everything

- Container image tags are pinned — never `latest`.
- `flake.lock` pins the entire system; it is updated deliberately with
  `nix flake update`, never edited by hand.
- `system.stateVersion` records install-time defaults and is not bumped.

## Keep yggdrasil light

The edge node has 4 GB of RAM and one job: routing and observing. Applications
run on midgard. If a new service is not ingress or monitoring, it does not
belong on yggdrasil.

## NixOS modules first

Prefer NixOS modules for infrastructure. Reach for OCI containers (Podman,
midgard only) when upstream genuinely packages better as a container.

## One change at a time

Small, focused changes: validate locally → `just test` → `just switch` →
commit. Two unrelated changes never ride in the same deploy.
