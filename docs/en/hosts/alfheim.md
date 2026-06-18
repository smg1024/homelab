---
icon: fontawesome/solid/server
---

# alfheim

Oracle Cloud Infrastructure ARM VM (`aarch64-linux`). It is the first
cloud-hosted application node in the homelab and runs jamye-plz.

## Responsibilities

- Validate NixOS operation on OCI with a real service
- Run the jamye-plz full-stack PWA from its upstream flake module
- Provide a small remote node with the shared operator baseline

Public traffic still enters through yggdrasil. Caddy on yggdrasil proxies
`jamye-plz.ridewithmin.com` to `alfheim.tail6fc192.ts.net:8080` over the
tailnet.

## Loaded host-specific modules

```text
modules/podman.nix
services/jamye-plz.nix
```

## Service ports

| Port | Service | Public URL |
| --- | --- | --- |
| `8080` | jamye-plz full-stack PWA entrypoint | `https://jamye-plz.ridewithmin.com` |
| `9100` | node_exporter | Not exposed; scraped by Prometheus over the tailnet |

## jamye-plz notes

- Upstream application code comes from the `jamye-plz` flake input, currently
  pinned in `flake.lock`.
- `services/jamye-plz.nix` imports the upstream NixOS module and enables
  `services.jamye-plz`.
- The upstream module runs the frontend, backend API, local PostgreSQL
  database, and alfheim-local Caddy for the service.
- Secrets live in `secrets/jamye-plz.yaml` and are rendered into
  `jamye-plz.env` with `sops.templates`.
- OAuth redirect URIs and `FRONTEND_ORIGIN` use
  `https://jamye-plz.ridewithmin.com`.

## Access

SSH is intentionally exposed **only through the tailnet**. The public OCI
address does not accept SSH.

```bash
ssh poby@alfheim.tail6fc192.ts.net
```

!!! note "SSH key for deploys"
    The `Justfile` uses `~/.config/sops-nix/secrets/github_ssh_key` as the
    SSH key when deploying to alfheim. Unlike the other hosts, the target
    address is also the full MagicDNS name.

## Health checks

The application systemd unit is named `jamye-plz-backend`, but the public
service is the full PWA served through Caddy with its local PostgreSQL
database.

```bash
systemctl is-active jamye-plz-backend caddy postgresql
journalctl -u jamye-plz-backend -f
curl -fsS https://jamye-plz.ridewithmin.com/
```
