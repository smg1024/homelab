---
icon: fontawesome/solid/cubes
---

# Applications

Application services run on host-specific nodes. Most existing apps are on
`midgard`; jamye-plz runs on `alfheim`. Caddy on yggdrasil forwards public
traffic over the tailnet.

## Homepage (`services/homepage.nix`)

The homelab dashboard. Runs on `:8082`, exposed at
`https://home.ridewithmin.com`.

## Dev with Min blog (`services/blog-site.nix`)

Static Astro personal blog. Built from the `blog` flake input and served by
static-web-server on midgard at `:8083`, exposed at
`https://blog.ridewithmin.com`.

## Docs site (`services/docs-site.nix`)

Static homelab documentation site. Built from this flake's `docs` package and
served by static-web-server on midgard at `:8084`, exposed at
`https://docs.ridewithmin.com`.

## Forgejo (`services/forgejo.nix`)

Git hosting. Runs on `:3000`, exposed at `https://git.ridewithmin.com`.

- Public registration disabled
- Forgejo SSH disabled (push/pull over HTTPS only)

## Vaultwarden (`services/vaultwarden.nix`)

Bitwarden-compatible password manager. Runs on `:8222`, exposed at
`https://vault.ridewithmin.com`.

- SQLite backend
- Public signup disabled, invitations allowed
- The admin token is rendered into the `vaultwarden.env` template from the
  `vaultwarden/admin_token` SOPS secret

## jamye-plz (`services/jamye-plz.nix`)

Closed-group full-stack social PWA. Runs on `alfheim` at `:8080`, exposed at
`https://jamye-plz.ridewithmin.com`.

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
