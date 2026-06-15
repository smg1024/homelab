---
icon: fontawesome/solid/cubes
---

# Applications

All application services run on `midgard`; Caddy on yggdrasil forwards
traffic over the tailnet.

## Homepage (`services/homepage.nix`)

The homelab dashboard. Runs on `:8082`, exposed at
`https://home.ridewithmin.com`.

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

## Guidelines for adding a new app

- Prefer **OCI containers** (Podman, midgard only) when upstream packages
  better as a container; otherwise prefer **NixOS modules**.
- Always pin image tags, never `latest`.
- Add a new shared service as a module under `services/` and wire it into
  `flake.nix` (shared) or `hosts/<host>/default.nix` (host-specific).
- Internal service ports are not opened on the firewall. To expose a service,
  follow the [ingress procedure](ingress.md#expose-a-service).
