---
icon: fontawesome/solid/hard-drive
---

# Bootstrapping a host

Installing NixOS on a new (or dead) machine from this repo, using
`nixos-anywhere` over an installer USB. The full step-by-step guide with all
caveats lives in `INSTALL.md` at the repo root; this is the operational
summary.

!!! danger "This wipes the target disk"
    `disko` repartitions and formats the disk it is pointed at. Triple-check
    the disk ID before running the install.

## Prepare

- [ ] Boot the target machine from a NixOS installer USB
- [ ] On its console: `sudo passwd root` (temporary) and
      `sudo systemctl start sshd`, note the LAN IP
- [ ] Find the stable disk path: `ls -l /dev/disk/by-id/`. Never use
      `/dev/sda`-style names
- [ ] In the repo, set the disk in `hosts/<host>/disko.nix`
- [ ] Generate hardware config from the target:

    ```bash
    ssh root@<INSTALLER_IP> 'nixos-generate-config --show-hardware-config' \
      > hosts/<host>/hardware-configuration.nix
    ```

    Drop `fileSystems`/`swapDevices` entries; disko owns `/` and `/boot`,
    zram owns swap.

- [ ] Enable the `imports` in `hosts/<host>/default.nix` and review with
      `git diff`

## Install

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#<host> \
  --build-on-remote \
  root@<INSTALLER_IP>
```

## After first boot

- [ ] `ssh poby@<host>` works; `ssh root@<host>` and password login **fail**
- [ ] Join the tailnet: `sudo tailscale up`, verify with `tailscale status`
- [ ] First remote rebuild: `just test <host>`, then `just switch <host>`
- [ ] If the host is a sops recipient: re-key secrets if its host key changed
      (see [Secrets](secrets.md#adding-a-new-host-as-a-recipient))
- [ ] Commit `hosts/<host>/` changes and `flake.lock`

## Validation

```bash
hostname && whoami && sudo -n true
systemctl is-active sshd tailscaled
zramctl && df -h && bootctl status
```

Expected: `poby` with passwordless sudo, both services active, zram swap
present, vfat `/boot`, ext4 `/`.
