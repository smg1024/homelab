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
    @case "{{ host }}" in yggdrasil|midgard) ;; *) echo "unknown host: {{ host }}" >&2; exit 2;; esac
    nix run {{ nixos_rebuild }} -- \
      {{ action }} \
      --fast \
      --flake ".#{{ host }}" \
      --build-host "{{ host }}" \
      --target-host "{{ host }}" \
      --use-remote-sudo
