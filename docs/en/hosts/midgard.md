---
icon: lucide/server
---

# midgard

The actual application host. External traffic is forwarded by Caddy on
yggdrasil over the tailnet (`midgard.tail6fc192.ts.net`); midgard's service
ports are never opened on the public firewall.

## Responsibilities

- Run the Homepage dashboard
- Run Forgejo (Git hosting)
- Run Vaultwarden (password manager)
- Provide the Podman runtime for containerized application services

## Loaded modules

```text
services/homepage.nix
services/forgejo.nix
services/vaultwarden.nix
modules/podman.nix      # host-specific module
```

## Service ports

| Port | Service | Public URL |
| --- | --- | --- |
| `8082` | Homepage | `https://home.ridewithmin.com` |
| `3000` | Forgejo | `https://git.ridewithmin.com` |
| `8222` | Vaultwarden | `https://vault.ridewithmin.com` |
| `9100` | node_exporter | — (scraped by Prometheus over the tailnet) |

## Container runtime

Podman is enabled only on midgard (`modules/podman.nix`).

- `virtualisation.oci-containers.backend = "podman"`
- weekly auto-prune (`podman-prune.timer`)
- registry search path limited to `docker.io` and `ghcr.io`
- image tags are **always pinned** — never `latest`

Long-running container services should be declared with
`virtualisation.oci-containers.containers` instead of ad-hoc compose
commands. `podman-compose` is kept only for temporary testing and manual
operator workflows.

## Hermes Agent

Hermes Agent is installed as part of `poby`'s Home Manager environment
(`home/poby/hermes-agent.nix`), not as a NixOS system service. Runtime state
and credentials live mutably under `/home/poby/.hermes`; once the setup is
stable it will be promoted into declarative Nix configuration.
