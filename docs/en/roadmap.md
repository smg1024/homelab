---
icon: fontawesome/solid/map
---

# Roadmap

Where this homelab is headed. Checked items link to what shipped; unchecked
items are intentions, roughly ordered by priority within each horizon.

## Now (operational gaps)

- [ ] **Automated backups** (currently none, [details](runbooks/backup-restore.md)):
    - [ ] `services.vaultwarden.backupDir` for the Vaultwarden SQLite DB
    - [ ] Forgejo dump or mirror to an external remote
    - [ ] Off-host backup job (restic/borgbackup) for midgard `/var/lib`
- [x] **Alert delivery:** Beszel sends email notifications with per-system
      thresholds, replacing the old unwired Prometheus rules
      ([details](services/monitoring.md))

## Next

- [x] Give **alfheim** a real job: [jamye-plz](services/applications.md)
      now runs on the OCI node and validates the cloud-host pattern
- [x] Serve this documentation publicly:
      [docs.ridewithmin.com](https://docs.ridewithmin.com/) is routed through
      Cloudflare Tunnel and backed by static-web-server on midgard
- [x] Replace the Grafana/Prometheus/Loki/Alloy stack with
      **Beszel + VictoriaLogs**: lighter on yggdrasil's 4 GB, friendlier UIs,
      and working alert delivery ([details](services/monitoring.md))
- [ ] Per-page **edit buttons** on this site (`content.action.edit` +
      Forgejo `edit_uri`)
- [ ] Review whether any tailnet-only surface deserves **Cloudflare Access**
      as a second factor

## Someday / ideas

- [ ] Declarative Hermes Agent setup on midgard (promote from mutable
      `~/.hermes` once stable)
- [ ] Declarative Beszel alert thresholds, if upstream ever supports config
      outside its database (today they are UI-managed state)

!!! tip "How to use this page"
    When an item ships, check it off and link the relevant page or commit.
    When priorities change, reorder. This page is a living document, not a
    promise.
