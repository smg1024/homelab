---
icon: lucide/circle-plus
---

# Adding a new service

The full path from "I want to run X" to "X is deployed and reachable".

## Decide where and how

Two questions first:

1. **Which host?** Applications go on midgard. Only ingress/monitoring
   infrastructure goes on yggdrasil ([principles](../principles.md)).
2. **Module or container?**

=== "NixOS module"

    Prefer this when nixpkgs packages the service well. Create
    `services/<name>.nix`:

    ```nix
    {...}: {
      services.<name> = {
        enable = true;
        # bind to localhost or a tailnet-reachable port,
        # never open the firewall
      };
    }
    ```

=== "OCI container"

    Use when upstream packages better as a container (midgard only,
    **pinned tag**):

    ```nix
    {...}: {
      virtualisation.oci-containers.containers.<name> = {
        image = "ghcr.io/org/app:1.2.3";  # never :latest
        ports = ["127.0.0.1:8090:8080"];
      };
    }
    ```

## Checklist

- [ ] Create the module under `services/<name>.nix`
- [ ] Wire it in: `hosts/<host>/default.nix` imports (host-specific) or
      `flake.nix` modules list (shared)
- [ ] Secrets, if any: add to `secrets/*.yaml` via sops, declare
      `sops.secrets."..."` — see [Secrets](secrets.md)
- [ ] Exposure, if needed:
    - [ ] Caddy virtualHost in `services/ingress.nix`
    - [ ] Public service → hostname in `services/cloudflared.nix` ingress;
          tailnet-only → `@tailnet` matcher pattern instead
    - [ ] DNS record in Cloudflare (public: Tunnel CNAME, tailnet-only:
          yggdrasil's tailnet address)
- [ ] Monitoring: add an Uptime Kuma check for public endpoints
- [ ] Validate: `nix flake check --no-build`
- [ ] Deploy: `just test <host>`, verify, then `just switch <host>`
- [ ] Commit

## Verify

```bash
# on the host
systemctl status <name>
curl -fsS http://127.0.0.1:<port>/

# from a tailnet client, if exposed
curl -fsS https://<name>.ridewithmin.com/
```

## If it goes wrong

`just test` activations disappear on reboot. For a switched deploy, roll
back on the host:

```bash
sudo nixos-rebuild switch --rollback
```
