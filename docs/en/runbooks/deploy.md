---
icon: fontawesome/solid/rocket
---

# Deploy & rollback

Every change starts in the repository. Machines are never fixed by editing
config directly on a host.

## Validate before deploying

```bash
nix flake check --no-build
nix flake show --all-systems
```

## Deploy

The `Justfile` is the normal deployment entrypoint. Building and activation
happen remotely **on the target host**.

```bash
just test <host>     # activate without making it the boot default
just switch <host>   # activate and set as boot default
```

Hosts: `yggdrasil`, `midgard`, `alfheim`.

Internally this runs:

```text
nixos-rebuild <test|switch>
  --no-reexec
  --flake .#<host>
  --build-host <host>
  --target-host <host>
  --sudo
```

!!! tip "test first"
    For changes with uncertain impact, activate with `just test` first and
    promote to `just switch` once everything looks fine. A configuration
    activated with `test` disappears on reboot.

## Rollback

Roll back to the previous generation on the host:

```bash
sudo nixos-rebuild switch --rollback
```

If the system no longer boots, pick the previous generation from the
systemd-boot menu.

## Caveats

- Never edit `flake.lock` by hand; use `nix flake update`.
- `system.stateVersion` records initial-install defaults; do not bump it
  unless release notes explicitly say to.
- Deploys touch live hosts: commit your changes and run them deliberately.
