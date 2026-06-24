---
icon: fontawesome/solid/hard-drive
---

# Bootstrapping a host

Installing NixOS on a new (or dead) machine from this repo, using
`nixos-anywhere` over an installer USB. This is the generic per-host
procedure. Do one host at a time and verify it before starting the next,
rather than installing two machines in parallel.

The procedure itself is simple: the **first** install always goes through
`nixos-anywhere`. After the host is reachable and trusts the deploy key, normal
changes go through GitHub Actions CI/CD. Local `just test` / `just switch` is
reserved for explicit bootstrap or break-glass requests.

!!! danger "This wipes the target disk"
    `disko` repartitions and formats the disk it is pointed at. Triple-check
    the disk ID before installing, and never point it at the USB installer's
    own disk.

## Prepare

- [ ] Boot the target machine from a NixOS installer USB.
- [ ] On its console, set a temporary root password and start SSH, then note
      the LAN IP. That password lives only in the installer environment; the
      installed system disables root and password login.

    ```bash
    sudo passwd root
    sudo systemctl start sshd
    ip addr
    ```

- [ ] From the workstation, confirm you reached the right machine:

    ```bash
    ssh root@<INSTALLER_IP> 'hostname; cat /etc/os-release'
    ```

- [ ] Find the internal disk's stable `by-id` path. Match it by size, model,
      and serial, never by a `/dev/sda`-style name (those move with boot order
      and USB devices). If you cannot tell which disk is the internal one,
      stop and recheck.

    ```bash
    ssh root@<INSTALLER_IP> 'lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE; ls -l /dev/disk/by-id/'
    ```

    Use a path like `ata-Samsung_SSD_860_EVO_...` or `nvme-...`, not
    `/dev/sda` or `/dev/nvme0n1`.

- [ ] Set that path as `device` in `hosts/<host>/disko.nix`. It produces a
      single-disk GPT layout: a 512M EFI partition at `/boot` (vfat) and the
      rest as `/` (ext4).

- [ ] Generate the hardware config from the target, then review it instead of
      trusting it as-is:

    ```bash
    ssh root@<INSTALLER_IP> 'nixos-generate-config --show-hardware-config' \
      > hosts/<host>/hardware-configuration.nix
    ```

    Keep the `not-detected.nix` import, the kernel module lines,
    `nixpkgs.hostPlatform`, and the CPU microcode entries. Drop
    `fileSystems."/"`, `fileSystems."/boot"`, and `swapDevices`: `disko` owns
    `/` and `/boot`, and `modules/swap.nix` owns swap via zram. Those entries
    are usually live-environment values that would clash with `disko`.

- [ ] Enable (uncomment) the `imports` in `hosts/<host>/default.nix`:

    ```nix
    imports = [
      ./hardware-configuration.nix
      ./disko.nix
    ];
    ```

- [ ] Review the changes before installing. A parse check catches syntax
      errors early:

    ```bash
    git diff -- hosts/<host>
    nix-instantiate --parse hosts/<host>/default.nix >/dev/null
    nix-instantiate --parse hosts/<host>/disko.nix >/dev/null
    nix-instantiate --parse hosts/<host>/hardware-configuration.nix >/dev/null
    ```

## Install

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#<host> \
  --build-on-remote \
  root@<INSTALLER_IP>
```

This partitions and formats with `disko`, copies and installs the system
closure, installs the bootloader, and applies the initial config. This step
erases the disk, so confirm the disk ID one last time.

!!! tip "If the workstation has flakes disabled"
    Add the experimental features to the same command:

    ```bash
    nix --extra-experimental-features "nix-command flakes" \
      run github:nix-community/nixos-anywhere -- \
      --flake .#<host> --build-on-remote root@<INSTALLER_IP>
    ```

## After first boot

Remove the USB and boot from the internal disk, then:

- [ ] `ssh poby@<host>` works; `ssh root@<host>` and password login **fail**
- [ ] Join the tailnet: `sudo tailscale up`, verify with `tailscale status`
- [ ] Switch to the normal deploy model: commit the host changes, open a PR,
      and let CI/CD take over (see [Deploy & rollback](deploy.md))
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

## After the base install

With the host booting and reachable, build it out one change at a time:

- Configure its secrets with sops-nix (see [Secrets](secrets.md)).
- Add and expose services (see [Adding a new service](add-service.md)).
- Every change follows the same loop: edit the repo, open a PR, let CI build,
  merge once green, then let CD deploy.
