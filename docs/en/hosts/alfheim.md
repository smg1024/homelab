# alfheim

An experimental Oracle Cloud Infrastructure ARM VM (`aarch64-linux`).

## Responsibilities

- Validate NixOS operation on OCI
- Test cloud-hosted homelab patterns before promoting persistent services
- Provide a small remote node with the shared operator baseline

It currently loads only the shared modules and no application-specific
services.

## Access

SSH is intentionally exposed **only through the tailnet**. The public OCI
address does not accept SSH.

```bash
ssh poby@alfheim.tail6fc192.ts.net
```

!!! note "SSH key for deploys"
    The `Justfile` uses `~/.config/sops-nix/secrets/github_ssh_key` as the
    SSH key when deploying to alfheim. Unlike the other hosts, the target
    address is also the full MagicDNS name.
