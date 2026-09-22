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

## Jamye host swap (September 2026)

The swap moves jamye-plz to midgard and jamye-server to alfheim. PostgreSQL
stays at major version 18 for jamye-plz and 17 for jamye-server. Public URLs
and secrets stay the same; Caddy changes only the four backend addresses.

**Do not merge the host-swap PR before both incoming snapshots are staged.**
The `jamye-host-swap` unit refuses to start either app without its snapshot.
It restores the logical PostgreSQL dump, compares every public table's row
count, then restores MinIO, application state, and Redis before startup.

1. Wait for all three PR build checks, and prebuild the reviewed system
   closures on the destination hosts without activating them.
2. Arrange a maintenance window. On each old host, run the checked-in snapshot
   script as root using the operator's SSH aliases:

   ```bash
   ssh alfheim sudo bash -s -- jamye-plz < scripts/jamye-host-swap-snapshot.sh
   ssh midgard sudo bash -s -- jamye-server < scripts/jamye-host-swap-snapshot.sh
   ```

   Each script stops its app and storage services and leaves them stopped.
   Snapshots are root-only under `/var/lib/jamye-host-swap/2026-09-17/<app>`.
   A failed or existing snapshot must be inspected; the script will not overwrite it.
3. Copy each complete snapshot directory to the same path on the opposite
   host over SSH. Preserve the root-only permissions. Verify `SHA256SUMS` and
   `SNAPSHOT_COMPLETE` on both destinations before merging.
4. Merge the reviewed PR and let normal GitHub Actions CD activate all hosts.
5. Verify `RESTORE_COMPLETE` on both destinations, service health, and all four
   public routes. Check authenticated chat/media behavior with an existing user.

The original PostgreSQL clusters and `/var/lib/minio/data` remain on their
source hosts. New MinIO paths are `/var/lib/jamye-plz-minio/data` on midgard
and `/var/lib/jamye-server-minio/data` on alfheim. The transcription model
cache remains on alfheim; midgard downloads it again when first needed.

If staging fails before deployment, resume the source stacks after checking
their snapshots. If a restore fails, the dependent units stay stopped; inspect
`journalctl -u jamye-host-swap` and the per-step completion files. Never delete
a completion file to force a restore over a live database. After cutover,
rolling back configuration alone would lose access to new writes: stop the
apps and plan the reverse data transfer before returning traffic to old hosts.

## Explicit manual path

`just test` and `just switch` are break-glass/bootstrap commands. Run them only
when an operator explicitly asks for a local activation. Building and
activation still happen remotely **on the target host**.

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
