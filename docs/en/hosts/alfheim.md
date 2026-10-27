---
icon: fontawesome/solid/server
---

# alfheim

alfheim is an Oracle Cloud Infrastructure ARM VM (`aarch64-linux`). It is the
homelab's cloud application node and runs jamye-server.

## Responsibilities

- Validate NixOS operation on OCI with a real service
- Run the jamye-server Rust API and worker from its upstream flake module
- Provide a small remote node with the shared operator baseline

Public traffic still enters through yggdrasil. Caddy on yggdrasil proxies
`jamye-api.ridewithmin.com` to `alfheim.tail6fc192.ts.net:8080` over the
tailnet.

## Selected host aspects

`modules/hosts/alfheim.nix` selects the shared `homelab-base` aspect and:

```text
modules/aspects/podman.nix
modules/aspects/jamye-server.nix
modules/aspects/jamye-host-swap.nix  # one-time data import, guarded by a completion stamp
```

## Service ports

| Port | Service | Public URL |
| --- | --- | --- |
| `8080` | jamye-server API | `https://jamye-api.ridewithmin.com` |
| `9000` | jamye-server MinIO | `https://jamye-media.ridewithmin.com` |
| `9429` | vlagent | No public exposure (tailnet-reachable via trusted interface); buffers journald logs to VictoriaLogs |
| `45876` | beszel-agent | Not exposed; the agent dials the Beszel hub over the tailnet |

## jamye-server notes

- Upstream application code comes from the `jamye-server` flake input, currently
  pinned in `flake.lock`.
- `modules/aspects/jamye-server.nix` imports the upstream NixOS module and enables
  `services.jamye-server`.
- The upstream module runs the API, worker, local PostgreSQL 17, Redis, and MinIO.
- Secrets live in `secrets/jamye-server.yaml` and are rendered with `sops.templates`.
- OAuth callbacks and the token issuer use `https://jamye-api.ridewithmin.com`.
- MinIO uses `/var/lib/jamye-server-minio/data`; public media URLs retain
  `https://jamye-media.ridewithmin.com`.
- Unstable removed MinIO. The aspect imports its NixOS module from
  `jamye-server.inputs.nixpkgs`, matching the application's existing MinIO
  package pin. Only the MinIO removal guard is bypassed; other removed-option
  checks remain active. MinIO is abandoned upstream, so this preserves the
  existing service until the application migrates its object storage.
- Jamye's bucket and identity setup still requires `minio-client`. The aspect
  permits only version `2025-08-13T08-35-41Z`, which unstable marks insecure
  because it is abandoned. This exception applies only to alfheim.
- jamye-plz is disabled. Its PostgreSQL 18 cluster, MinIO objects, Redis data,
  and application state remain on disk for recovery but are not started.

## Access

SSH is intentionally exposed **only through the tailnet**. The public OCI
address does not accept SSH.

```bash
ssh poby@alfheim.tail6fc192.ts.net
```

!!! note "SSH for deploys"
    GitHub Actions CD uses the repository deploy key secret. A local break-glass
    deploy relies on the operator's SSH client config: `just` and
    `nixos-rebuild` pass the bare host name (`alfheim`), and an alias in
    `~/.ssh/config` resolves it to `alfheim.tail6fc192.ts.net` with the right
    key, the same way the other hosts are reached. The `Justfile` itself sets no
    SSH identity or hostname.

## Health checks

The `jamye-server-api` and `jamye-server-worker` systemd units run the application.

```bash
systemctl is-active jamye-server-api jamye-server-worker postgresql minio
journalctl -u jamye-server-api -f
```
