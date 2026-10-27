---
icon: fontawesome/solid/cubes
---

# Applications

Application services run on host-specific nodes. Most existing applications
run on `midgard`, while jamye-server runs on `alfheim`. Caddy on yggdrasil
forwards public traffic over the tailnet and serves the static blog and docs
sites locally. jamye-plz is currently disabled.

## Homepage (`modules/aspects/homepage.nix`)

Homepage is the homelab dashboard. It runs on `:8082` and is available at
`https://home.ridewithmin.com`.

## Dev with Min blog (`modules/aspects/ingress.nix`)

The Dev with Min blog is a static Astro site built from the `blog` flake input.
Caddy on yggdrasil serves it directly from the Nix store with `file_server` at
`https://blog.ridewithmin.com`; it has no dedicated service process.

## Docs site (`modules/aspects/ingress.nix`)

The homelab documentation is a static site built from this flake's `docs`
package. Caddy on yggdrasil serves it directly from the Nix store with
`file_server` at `https://docs.ridewithmin.com`. See the
[docs site runbook](../runbooks/docs-site.md) for the editing workflow.

## Forgejo (`modules/aspects/forgejo.nix`)

Forgejo provides Git hosting on `:3000` at `https://git.ridewithmin.com`.

- Public registration disabled
- Forgejo SSH disabled (push/pull over HTTPS only)

## Vaultwarden (`modules/aspects/vaultwarden.nix`)

Vaultwarden is a Bitwarden-compatible password manager. It runs on `:8222` at
`https://vault.ridewithmin.com`.

- SQLite backend
- Public signup disabled, invitations allowed
- The admin token is rendered into the `vaultwarden.env` template from the
  `vaultwarden/admin_token` SOPS secret

## jamye-plz (`modules/aspects/jamye-plz.nix`)

jamye-plz is disabled and its aspect is not selected by any host. Its source module,
encrypted secrets, and retained alfheim data remain available for a future
recovery. `jamye-plz.ridewithmin.com` and `minio.ridewithmin.com` return HTTP
`503` while the service is closed.

## jamye-server (`modules/aspects/jamye-server.nix`)

The Rust API and worker run on alfheim, with local PostgreSQL 17, Redis, and
MinIO. The upstream `jamye-server` flake supplies native `aarch64-linux` packages.

- API: `https://jamye-api.ridewithmin.com` → `alfheim.tail6fc192.ts.net:8080`
- Media: `https://jamye-media.ridewithmin.com` → `alfheim.tail6fc192.ts.net:9000`
- MinIO data: `/var/lib/jamye-server-minio/data`
- Secrets: `secrets/jamye-server.yaml`, rendered through `sops.templates`

## Guidelines for adding a new app

- Prefer **NixOS modules** when upstream packages the service that way. Use
  OCI containers only on hosts where Podman is deliberately enabled and
  upstream packages better as a container.
- Always pin image tags, never `latest`.
- Define a service aspect under `modules/aspects/` and select it through
  `homelab-base.includes` (shared) or a host aspect's `includes` in
  `modules/hosts/<host>.nix` (host-specific).
- Internal service ports are not opened on the firewall. To expose a service,
  follow the [ingress procedure](ingress.md#expose-a-service).
