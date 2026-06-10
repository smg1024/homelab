nixos_rebuild := "github:NixOS/nixpkgs/nixos-26.05#nixos-rebuild"

# List available homelab commands.
default:
    @just --list

# Activate a host configuration without making it the boot default.
[group('homelab')]
test host:
    @just _rebuild {{ host }} test

# Activate a host configuration and make it the boot default.
[group('homelab')]
switch host:
    @just _rebuild {{ host }} switch

_rebuild host action:
    @case "{{ host }}" in yggdrasil|midgard|alfheim) ;; *) echo "unknown host: {{ host }}" >&2; exit 2;; esac
    @case "{{ host }}" in \
      alfheim) target="poby@alfheim.tail6fc192.ts.net"; ssh_opts="-i $HOME/.config/sops-nix/secrets/github_ssh_key";; \
      *) target="{{ host }}"; ssh_opts="";; \
    esac; \
    NIX_SSHOPTS="$ssh_opts" nix run {{ nixos_rebuild }} -- \
      {{ action }} \
      --no-reexec \
      --flake ".#{{ host }}" \
      --build-host "$target" \
      --target-host "$target" \
      --sudo
