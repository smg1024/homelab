---
icon: fontawesome/solid/key
---

# Secrets

Secrets are managed with `sops-nix`. **Plaintext secrets never go into
`.nix` files or the Nix store.**

## How it works

- Encrypted files: `secrets/*.yaml` (currently `ingress.yaml`,
  `vaultwarden.yaml`, `jamye-plz.yaml`, `beszel.yaml`, ...)
- Encryption policy `.sops.yaml`: new or re-keyed files matching
  `secrets/[^/]+\.yaml` are encrypted for the `poby`, `yggdrasil`,
  `midgard`, and `alfheim` age recipients.
- Each host decrypts using its own SSH host key
  (`/etc/ssh/ssh_host_ed25519_key`) as the age identity. A host can read only
  files whose SOPS metadata includes that host's age recipient; older files may
  need `sops updatekeys` before a newly added host can decrypt them.
- At activation/runtime, sops-nix materializes secrets as files under
  `/run/secrets` or as service-specific templates, applying owner, group, and
  mode.

## Adding a new secret

1. Open the appropriate `secrets/*.yaml` with sops and edit it.

    ```bash
    sops secrets/ingress.yaml
    ```

2. Declare it in the module with `sops.secrets."<path>"`, setting owner/mode
   and `restartUnits`.

    ```nix
    sops.secrets."myservice/api_token" = {
      owner = "myservice";
      mode = "0400";
      restartUnits = ["myservice.service"];
    };
    ```

3. Reference it from the service via `config.sops.secrets."<path>".path`, or
   render an environment file with `sops.templates`.

## Current secret consumers

| Secret | Consumer | Purpose |
| --- | --- | --- |
| `cloudflare/caddy_env` | Caddy | Cloudflare API token for DNS challenges |
| `cloudflare/cloudflared_tunnel_credentials` | cloudflared | Tunnel credential |
| `beszel/admin_email`, `beszel/admin_password` | Beszel hub | first-admin seed rendered into `beszel-hub.env` |
| `beszel/hub_key`, `beszel/universal_token` | Beszel agents | agent registration credentials rendered into `beszel-agent.env` |
| `jamye-plz/*` | jamye-plz | JWT and OAuth client settings rendered into `jamye-plz.env` |
| `vaultwarden/admin_token` | Vaultwarden | admin token (`ADMIN_TOKEN`) |

## Adding a new host as a recipient

1. Derive the age recipient key from the new host's SSH host public key.

    ```bash
    ssh-keyscan -t ed25519 <host> | ssh-to-age
    ```

2. Add the recipient to `.sops.yaml`.
3. Re-encrypt the affected secret files.

    ```bash
    sops updatekeys secrets/<file>.yaml
    ```
