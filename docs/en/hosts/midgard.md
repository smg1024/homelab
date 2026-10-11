---
icon: fontawesome/solid/server
---

# midgard

midgard is the primary application host. Caddy on yggdrasil forwards external
traffic over the tailnet (`midgard.tail6fc192.ts.net`). The public firewall
does not expose midgard's service ports.

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
| `9429` | vlagent | No public exposure (tailnet-reachable via trusted interface); buffers journald logs to VictoriaLogs |
| `45876` | beszel-agent | Not exposed; the agent dials the Beszel hub over the tailnet |

## Container runtime

Only midgard enables Podman (`modules/podman.nix`).

- `virtualisation.oci-containers.backend = "podman"`
- weekly auto-prune (`podman-prune.timer`)
- registry search path limited to `docker.io` and `ghcr.io`
- image tags are pinned, never `latest`

Long-running container services should be declared with
`virtualisation.oci-containers.containers` instead of ad-hoc compose
commands. `podman-compose` is kept only for temporary testing and manual
operator workflows.

## Hermes Agent

Hermes Agent is part of `poby`'s Home Manager environment
(`home/poby/hermes-agent.nix`), not a NixOS system service. Runtime state and
credentials remain mutable under `/home/poby/.hermes` until the setup is
stable enough to move into declarative Nix configuration.
