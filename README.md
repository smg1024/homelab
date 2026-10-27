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
| `yggdrasil` | Edge / infrastructure | Cloudflare Tunnel, Caddy ingress, monitoring, status page |
| `midgard` | Application host | Forgejo, Vaultwarden, Homepage, Podman-backed applications |
| `alfheim` | OCI ARM node | ARM/cloud-host validation and `jamye-server` |

## Architecture

The flake tracks `nixos-unstable`, with exact revisions pinned in `flake.lock`.
[Den](https://den.denful.dev/) composes one `nixosConfiguration` per host from
explicit aspect includes in `modules/hosts/<host>.nix`. Shared system behavior,
services, and the operator environment live in `modules/aspects/`. Home Manager
activates with each NixOS configuration.

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
| `modules/den.nix` | Den integration and supported systems |
| `modules/hosts/` | Host aspects and explicitly imported hardware/Disko modules under `_` directories |
| `modules/aspects/` | Shared system and service aspects, plus `poby`'s integrated Home Manager configuration |
| `modules/outputs.nix` | Documentation package/shell, restore and MinIO checks, formatter |
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
