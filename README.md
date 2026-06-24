# Homelab

English | [한국어](README-ko.md)

This repository is the source of truth for a NixOS homelab. Host
configuration, shared modules, services, operator environment, and encrypted
secrets are declared in a single Nix flake and deployed through GitHub Actions.

## Documentation

The detailed documentation lives on the docs site:

- English: <https://docs.ridewithmin.com/>
- 한국어: <https://docs.ridewithmin.com/ko/>

Use the docs site for architecture details, host runbooks, service notes,
secrets, CI/CD, rollback, and operational procedures.

## Overview

The homelab is split into an edge/infra node, an application host, and an ARM
cloud node. Public traffic enters through Cloudflare Tunnel and lands on Caddy
on `yggdrasil`; internal backend traffic moves over Tailscale. The repository
is treated as the server: changes are made here, reviewed through pull
requests, and rolled out by CI/CD.

## Hosts

| Host | Role | Notes |
| --- | --- | --- |
| `yggdrasil` | Edge / infrastructure | Cloudflare Tunnel, Caddy ingress, monitoring, status page, docs site |
| `midgard` | Application host | Forgejo, Vaultwarden, Homepage, Podman-backed applications |
| `alfheim` | OCI ARM node | ARM/cloud-host validation and `jamye-plz` |

## Architecture

`flake.nix` pins NixOS 26.05 and exposes one `nixosConfiguration` per host.
Shared system behavior comes from `modules/`; service definitions live under
`services/`; each host wires in its hardware and host-specific modules from
`hosts/<host>/`.

External users reach public services through:

```text
Internet -> Cloudflare -> cloudflared on yggdrasil -> Caddy -> service backend
```

Private administration and host-to-host traffic use the Tailscale tailnet.
Application ports are not opened directly to the public Internet.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `flake.nix` / `flake.lock` | Nix flake inputs and host outputs |
| `hosts/` | Per-host NixOS configuration, hardware config, and disk layout |
| `modules/` | Shared NixOS modules used across hosts |
| `services/` | Service modules and ingress/monitoring configuration |
| `home/` | Home Manager profile for the `poby` operator account |
| `secrets/` | `sops-nix` encrypted secrets |
| `docs/` | English and Korean documentation site source |

## Change Flow

Normal changes follow the GitHub Actions workflow:

```text
edit -> pull request -> CI builds every host -> merge -> CD deploys all nodes
```

Local `just test` and `just switch` are explicit-request break-glass or
bootstrap commands, not the default validation or deployment path.

## Useful Docs

- [Architecture](https://docs.ridewithmin.com/architecture/)
- [Security model](https://docs.ridewithmin.com/security/)
- [Hosts](https://docs.ridewithmin.com/hosts/yggdrasil/)
- [Services](https://docs.ridewithmin.com/services/applications/)
- [CI/CD pipeline](https://docs.ridewithmin.com/runbooks/ci-cd/)
- [Deploy & rollback](https://docs.ridewithmin.com/runbooks/deploy/)
- [Secrets](https://docs.ridewithmin.com/runbooks/secrets/)
