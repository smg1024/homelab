---
icon: fontawesome/solid/scale-balanced
---

# Design principles

These rules guide changes to the homelab. Check new decisions against them
before editing the configuration.

## The repo is the server

The Git repository is the single source of truth. Do not fix machines by
editing configuration on a host. Edit and validate changes in the repo,
commit them, and then deploy. If a host differs from the repo, rebuild the host
to match the repo.

## Zero open ports

No application port is ever exposed to the public Internet. External traffic
enters only through Cloudflare Tunnel → Caddy, which means the firewall stays
closed and the attack surface is the tunnel, not the hosts. See the
[security model](security.md) for the full picture.

## The tailnet is the internal boundary

Hosts talk to each other over Tailscale, and tailnet membership is what makes
a machine "inside". Operator-only surfaces such as Beszel are gated by
tailnet address ranges, not passwords on public endpoints.

## Secrets never touch the store

Plaintext secrets never go into `.nix` files or the Nix store. Sensitive values
live in sops-encrypted YAML, and each host decrypts them at activation time
with its own SSH key. A leaked repo does not expose the plaintext values.

## Pin everything

- Container image tags are pinned, never `latest`.
- `flake.lock` pins the entire system; it is updated deliberately with
  `nix flake update`, never edited by hand.
- `system.stateVersion` records install-time defaults and is not bumped.

## Keep yggdrasil light

The edge node has 4 GB of RAM and one job: routing and observing. Applications
belong on application hosts (`midgard` or `alfheim`), not on yggdrasil. If a
new service is not ingress or monitoring, it does not belong on yggdrasil.

## NixOS modules first

Prefer NixOS modules for infrastructure and applications that package cleanly
that way. Use OCI containers only when upstream packages the software better
as a container and the target host has Podman enabled.

## One change at a time

Keep changes small and focused. Edit the repo, open a PR, let CI build every
host, merge once the checks pass, and let CD deploy. Use local `just test` or
`just switch` only for explicit break-glass or bootstrap requests. Put
unrelated changes in separate deployments.
