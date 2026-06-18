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
- [ ] **Alert delivery:** Prometheus rules exist but Alertmanager is not
      configured, so alerts are visible only in the UI
      ([details](services/monitoring.md))
- [ ] **Deploy this docs site:** merge the docs branch, `just switch
      yggdrasil`, add the `docs.ridewithmin.com` DNS record

## Next

- [x] Give **alfheim** a real job: [jamye-plz](services/applications.md)
      now runs on the OCI node and validates the cloud-host pattern
- [ ] Per-page **edit buttons** on this site (`content.action.edit` +
      Forgejo `edit_uri`)
- [ ] Review whether any tailnet-only surface deserves **Cloudflare Access**
      as a second factor

## Someday / ideas

- [ ] Public (read-only) version of this documentation
- [ ] Declarative Hermes Agent setup on midgard (promote from mutable
      `~/.hermes` once stable)
- [ ] Dashboards-as-code expansion in Grafana (more provisioned dashboards)

!!! tip "How to use this page"
    When an item ships, check it off and link the relevant page or commit.
    When priorities change, reorder. This page is a living document, not a
    promise.
