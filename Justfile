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

# Build the documentation site.
[group('docs')]
docs-build:
    nix build .#docs

# Preview the documentation site locally with live reload.
[group('docs')]
docs-preview lang="en":
    cd docs && nix develop ..#docs --command zensical serve {{ if lang == "ko" { "-f zensical.ko.toml" } else { "" } }}

# Remove local documentation build artifacts.
[group('docs')]
docs-clean:
    rm -rf docs/site result

# Update all flake inputs, including private GitHub inputs.
[group('flake')]
up:
    nix flake update --refresh --option access-tokens "github.com=$(gh auth token)"

# Update one flake input, including private GitHub inputs.
[group('flake')]
upp input:
    nix flake update '{{ input }}' --refresh --option access-tokens "github.com=$(gh auth token)"

_rebuild host action:
    @case "{{ host }}" in yggdrasil|midgard|alfheim) ;; *) echo "unknown host: {{ host }}" >&2; exit 2;; esac;
    nh os {{ action }} . \
      --hostname "{{ host }}" \
      --build-host "{{ host }}" \
      --target-host "{{ host }}" \
      --elevation-strategy passwordless {{ if action == "switch" { "--ask" } else { "" } }}
