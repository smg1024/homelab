---
icon: fontawesome/solid/box-archive
---

# Backup & restore

The repo can rebuild host configuration, but it cannot recreate application
data or private keys.

!!! warning "No automated backups yet"
    As of June 2026 **no automated backup is configured anywhere in this
    homelab.** Everything below the "Reproducible" line is currently
    unprotected. Fixing this is a [roadmap](../roadmap.md) item.

## What is reproducible vs. what is data

The repo contains the full system configuration for every host. Use the
[bootstrap runbook](bootstrap-host.md) to rebuild a machine from scratch. This
configuration does not need a separate backup.

The following data exists only on the hosts:

| Data | Host | Location (NixOS module defaults) | Loss impact |
| --- | --- | --- | --- |
| Vaultwarden DB + attachments | midgard | `/var/lib/vaultwarden` | **Critical**: all passwords |
| Forgejo repos + DB | midgard | `/var/lib/forgejo` | **Critical**: all Git history not pushed elsewhere |
| Uptime Kuma config/history | yggdrasil | `/var/lib/private/uptime-kuma` | Annoying: checks recreated by hand |
| Beszel hub DB (users, systems, alert config) | yggdrasil | `/var/lib/beszel-hub` | Annoying: alerts and notifications reconfigured by hand |
| AdGuard Home config, credentials, and filter state | yggdrasil | `/var/lib/AdGuardHome` | Annoying: DNS setup and policy recreated by hand |
| VictoriaLogs logs | yggdrasil | `/var/lib/victorialogs` | Acceptable: 14d retention logs |

Back up two kinds of keys separately:

- **Host SSH keys** (`/etc/ssh/ssh_host_ed25519_key`): also the sops age
  identity. If a host dies, its key dies with it; recovery relies on the
  `poby` operator key being a `.sops.yaml` recipient (it is). After rebuild,
  register the new host key and re-encrypt
  ([procedure](secrets.md#adding-a-new-host-as-a-recipient)).
- **The `poby` age key and SSH private key** are the root of trust.
  Keep copies outside the homelab (e.g., in Vaultwarden's emergency kit,
  but note the circularity: not *only* in Vaultwarden).

## Restore path (host loss)

1. Rebuild the host: [bootstrap runbook](bootstrap-host.md)
2. Re-join the tailnet (`sudo tailscale up`); MagicDNS names recover
3. Re-key sops if the host key changed, redeploy
4. Restore data directories from backup *(once backups exist)*
5. Verify services per their pages, check Uptime Kuma goes green

## Backup priorities

Implement backups in this order:

1. `services.vaultwarden.backupDir`: the module has built-in SQLite backup
   support and is the lowest-effort first step
2. Forgejo dump or repo mirroring to an external remote
3. A proper restic/borgbackup job for `/var/lib` state on midgard,
   off-host (e.g., to alfheim or object storage)
