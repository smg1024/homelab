---
icon: fontawesome/solid/rocket
---

# Deploy & rollback

Every change starts in the repository. Machines are never fixed by editing
config directly on a host.

## Validate before opening a PR

GitHub Actions CI is the authoritative build check. Local validation is still
useful before opening a PR:

```bash
nix flake check --no-build
nix flake show --all-systems
```

## Deploy

The normal deployment path is GitHub Actions:

1. Open a PR.
2. Wait for CI to build every host.
3. Merge once the checks are green.
4. Let CD switch `yggdrasil`, `midgard`, and `alfheim`.

See [CI/CD pipeline](ci-cd.md) for the workflow details.

## Explicit manual path

`just test` and `just switch` are break-glass/bootstrap commands. Run them only
when an operator explicitly asks for a local activation. Building and
activation still happen remotely **on the target host**.

```bash
just test <host>     # activate without making it the boot default
just switch <host>   # activate and set as boot default
```

Hosts: `yggdrasil`, `midgard`, `alfheim`.

Internally this runs `nh`. Evaluation happens on the workstation; the build and
activation run remotely on the target host:

```text
nh os <test|switch> .
  --hostname <host>
  --build-host <host>            # build on the node itself
  --target-host <host>           # activate on the node itself
  --elevation-strategy passwordless
  --ask                          # switch only: confirm before activating
```

`just switch` adds `--ask`, so nh prints the package diff and waits for
confirmation before making the new generation the boot default; `just test`
activates without prompting. Passwordless elevation works because `wheel` has
`security.sudo.wheelNeedsPassword = false`.

!!! tip "manual test activation"
    When the explicit manual path is needed, `just test` activates a
    configuration without making it the boot default. A configuration activated
    with `test` disappears on reboot.

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
- Deploys touch live hosts: use CI/CD for normal changes, and run local
  `just test` / `just switch` only on explicit request.
