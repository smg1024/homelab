# Homelab — agent guidance

This repo is the **single source of truth** for a NixOS homelab declared as a
Nix flake. Treat the repo as the server: never fix machines by editing config
directly on a host. All changes happen here, are committed, then deployed.

See `README.md` for the full architecture; this file is the operational summary
the agent should keep in mind.

> This file is the shared source of truth. `CLAUDE.md` is a symlink to it, so
> Codex (`AGENTS.md`) and Claude Code (`CLAUDE.md`) read the same content. Edit
> `AGENTS.md` only.

## Layout

- `flake.nix` — tracks `nixos-unstable`, with revisions pinned in `flake.lock`;
  uses flake-parts, import-tree, and Den from their `main` branches.
- `modules/den.nix` — Den integration and supported output systems.
- `modules/hosts/<host>.nix` — Den host declarations and explicit aspect includes;
  generates `nixosConfigurations.{yggdrasil,midgard,alfheim}` (alfheim is ARM).
- `modules/hosts/_<host>/` — ordinary hardware and Disko modules, imported explicitly.
- `modules/aspects/` — shared system, service, and operator aspects.
  `homelab-base` selects common system aspects; `poby` configures the account
  and integrated Home Manager environment.
- `modules/outputs.nix` — documentation package/shell, restore and MinIO checks, formatter.
- `secrets/` — `sops-nix` encrypted YAML. Policy in `.sops.yaml`.

## Host roles

- **yggdrasil** — edge/infra node: Cloudflare Tunnel, Caddy ingress, Beszel hub,
  VictoriaLogs, Uptime Kuma. Keep it lightweight (4 GB RAM).
- **midgard** — application host: Forgejo, Vaultwarden, Homepage, Podman.
- **alfheim** — OCI ARM VM running jamye-server, with Podman enabled.
  SSH only over the tailnet.

## Conventions

- Match the existing Nix formatting exactly (alejandra style: 2-space indent,
  trailing commas, `inputs @ { ... }`). Don't reformat unrelated code.
- Prefer **NixOS modules** for infra; use **OCI containers** on hosts that
  enable Podman (midgard and alfheim) for apps that package better upstream. **Pin image tags — never
  `latest`.**
- Define services as `den.aspects.<name>.nixos` in `modules/aspects/` and select
  them through a host's `includes` or `homelab-base.includes` for shared services.
  File discovery defines an aspect; inclusion enables it. Keep `jamye-plz` unselected.
- Route host-specific home settings through `provides.poby.homeManager` or
  `provides.poby.includes`. Home Manager remains integrated with NixOS.
- import-tree loads top-level Den/flake-parts modules. Keep ordinary NixOS modules
  beneath `_` directories and import them inside a `nixos` class.
- Internal service ports are **not** opened on the firewall. Reach midgard
  backends via the MagicDNS name `midgard.tail6fc192.ts.net`. Public traffic
  arrives only through Cloudflare Tunnel → Caddy.
- `system.stateVersion` records initial-install defaults — **do not bump it**
  unless release notes explicitly say to.

## Secrets

- Managed by `sops-nix`; each host decrypts using its own SSH host key
  (`/etc/ssh/ssh_host_ed25519_key`) as the age identity.
- Never write plaintext secrets into `.nix` files or the Nix store. Add new
  secrets to the appropriate `secrets/*.yaml` (re-encrypt per `.sops.yaml`) and
  reference them through `sops.secrets`/templates.

## Workflow

Normal changes go through GitHub Actions CI/CD, never a direct host edit:

1. Edit the repo on a branch and open a PR.
2. CI builds every host (`yggdrasil`, `midgard`, `alfheim`); merge only once the
   required `build …` checks are green.
3. CD builds each closure on a GitHub runner matching the host architecture,
   then switches all three hosts on merge to `main`. Builds stay off the live
   hosts; `--use-substitutes` lets targets fetch cached paths before transfer.

Validate locally before opening the PR (CI is the authoritative check):

```bash
nix flake check --no-build
nix flake show --all-systems
```

`just test` / `just switch` are **break-glass / bootstrap only** — local
activation that builds and activates **on the target host** over SSH. This is an
outward, hard-to-reverse action: use it only when the operator explicitly asks,
never as the default deploy path, and confirm with the user first.

```bash
just test <host>     # activate without making it the boot default
just switch <host>   # activate and set as boot default
```

Hosts: `yggdrasil`, `midgard`, `alfheim`. Roll back on a host with
`sudo nixos-rebuild switch --rollback` or the boot menu.

## Don't

- Don't use `just test`/`just switch` for normal changes — that path is
  break-glass/bootstrap only and touches live hosts. Normal deploys go through
  CI/CD (PR → merge), and any manual `just` activation needs explicit
  confirmation.
- Don't edit `flake.lock` by hand; use `nix flake update`.
- Don't commit or push unless asked.
