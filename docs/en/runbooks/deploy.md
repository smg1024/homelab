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

## Jamye shutdown and server host move (October 2026)

This change disables jamye-plz and moves jamye-server from midgard to alfheim.
jamye-plz is archived but not restored elsewhere. jamye-server keeps
PostgreSQL 17 and restores its database, MinIO objects, application state, and
Redis data before its first start on alfheim.

**Do not merge the host-move PR before both snapshots are complete and the
jamye-server snapshot is staged on alfheim.** The `jamye-host-swap` unit gates
the jamye-server target, infrastructure, migrations, API, and worker. It
verifies checksums, restores the PostgreSQL dump in one transaction, compares
every public table's row count, and restores the file-backed data.

1. Wait for all three PR build checks, and prebuild the reviewed system
   closures on the destination hosts without activating them.
2. Arrange a maintenance window. Create a cold archive of jamye-plz on
   alfheim, then snapshot jamye-server on midgard:

   ```bash
   ssh alfheim sudo bash -s -- jamye-plz < scripts/jamye-host-swap-snapshot.sh
   ssh midgard sudo bash -s -- jamye-server < scripts/jamye-host-swap-snapshot.sh
   ```

   Both source stacks remain stopped. The root-only snapshots are stored under
   `/var/lib/jamye-host-swap/2026-10-11/<app>`. The script refuses to overwrite
   an existing or partial snapshot.
3. Copy the jamye-server snapshot to the same path on alfheim. Copy the
   jamye-plz archive to midgard for off-node recovery, then verify both copies:

   ```bash
   ssh midgard sudo tar -C /var/lib/jamye-host-swap/2026-10-11 -cf - jamye-server \
     | ssh alfheim sudo tar -C /var/lib/jamye-host-swap/2026-10-11 -xf -
   ssh alfheim sudo tar -C /var/lib/jamye-host-swap/2026-10-11 -cf - jamye-plz \
     | ssh midgard sudo tar -C /var/lib/jamye-host-swap/2026-10-11 -xf -
   ssh alfheim "sudo sh -c 'cd /var/lib/jamye-host-swap/2026-10-11/jamye-server && sha256sum --check --quiet SHA256SUMS && test -f SNAPSHOT_COMPLETE'"
   ssh midgard "sudo sh -c 'cd /var/lib/jamye-host-swap/2026-10-11/jamye-plz && sha256sum --check --quiet SHA256SUMS && test -f SNAPSHOT_COMPLETE'"
   ```

4. Merge the reviewed PR and let normal GitHub Actions CD activate all hosts.
   alfheim restores jamye-server automatically before starting it. No automatic
   restore consumes the jamye-plz archive.
5. Verify the alfheim `RESTORE_COMPLETE` marker, deployment jobs, service
   health, the API and media routes, and authenticated application behavior.
   Confirm that `jamye-plz.ridewithmin.com` and `minio.ridewithmin.com` return
   HTTP `503`.

The original jamye-server data remains on midgard. The inactive jamye-plz
PostgreSQL 18 cluster, `/var/lib/minio/data`, Redis data, and application state
remain on alfheim; the verified archive copy on midgard provides off-node
recovery. jamye-server MinIO is restored to
`/var/lib/jamye-server-minio/data`, so it does not overwrite the retained
jamye-plz objects.

If staging fails before deployment, resume the source stacks after inspecting
their snapshots. If restoration fails, jamye-server units remain stopped;
inspect `journalctl -u jamye-host-swap` and the per-step completion files.
Never delete a completion file to force a restore over a live database. After
cutover, a configuration-only rollback would omit new writes made on alfheim;
stop jamye-server and plan a reverse data transfer before returning traffic to
midgard.

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
