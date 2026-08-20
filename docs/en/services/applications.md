---
icon: fontawesome/solid/cubes
---

# Applications

Application services run on host-specific nodes. Most existing applications
run on `midgard`, while jamye-plz runs on `alfheim`. Caddy on yggdrasil
forwards public traffic over the tailnet and serves the static blog and docs
sites locally.

## Homepage (`services/homepage.nix`)

Homepage is the homelab dashboard. It runs on `:8082` and is available at
`https://home.ridewithmin.com`.

## Dev with Min blog (`services/ingress.nix`)

The Dev with Min blog is a static Astro site built from the `blog` flake input.
Caddy on yggdrasil serves it directly from the Nix store with `file_server` at
`https://blog.ridewithmin.com`; it has no dedicated service process.

## Docs site (`services/ingress.nix`)

The homelab documentation is a static site built from this flake's `docs`
package. Caddy on yggdrasil serves it directly from the Nix store with
`file_server` at `https://docs.ridewithmin.com`. See the
[docs site runbook](../runbooks/docs-site.md) for the editing workflow.

## Forgejo (`services/forgejo.nix`)

Forgejo provides Git hosting on `:3000` at `https://git.ridewithmin.com`.

- Public registration disabled
- Forgejo SSH disabled (push/pull over HTTPS only)

## Vaultwarden (`services/vaultwarden.nix`)

Vaultwarden is a Bitwarden-compatible password manager. It runs on `:8222` at
`https://vault.ridewithmin.com`.

- SQLite backend
- Public signup disabled, invitations allowed
- The admin token is rendered into the `vaultwarden.env` template from the
  `vaultwarden/admin_token` SOPS secret

## jamye-plz (`services/jamye-plz.nix`)

jamye-plz is a closed-group, full-stack social PWA. It runs on `alfheim` at
`:8080` and is available at `https://jamye-plz.ridewithmin.com`.

- Imported from the upstream `jamye-plz` flake input
- Enabled through the upstream `services.jamye-plz` NixOS module
- The upstream module manages the frontend, backend API, local PostgreSQL
  database, and alfheim-local Caddy
- OAuth and JWT secrets are stored in `secrets/jamye-plz.yaml` and rendered
  into `jamye-plz.env` through `sops.templates`
- Public traffic path: Cloudflare Tunnel on yggdrasil → Caddy on yggdrasil →
  the full-stack service entrypoint at `alfheim.tail6fc192.ts.net:8080`

## Guidelines for adding a new app

- Prefer **NixOS modules** when upstream packages the service that way. Use
  OCI containers only on hosts where Podman is deliberately enabled and
  upstream packages better as a container.
- Always pin image tags, never `latest`.
- Add a new shared service as a module under `services/` and wire it into
  `flake.nix` (shared) or `hosts/<host>/default.nix` (host-specific).
- Internal service ports are not opened on the firewall. To expose a service,
  follow the [ingress procedure](ingress.md#expose-a-service).
