---
icon: fontawesome/solid/file-lines
---

# ADR-001: Zensical for the docs site

**Status**: accepted · **Date**: 2026-06-12

## Context

This docs site was initially built with MkDocs Material. In February 2026
the Material team announced that **MkDocs 2.0 is incompatible with Material
for MkDocs** — the plugin system is removed, theming is rewritten, and
MkDocs 1.x is effectively unmaintained. Material 9.x pins `mkdocs <2`, so
builds keep working, but the foundation is end-of-life.

## Options considered

| Option | Verdict |
| --- | --- |
| Stay on mkdocs-material (pinned) | Works today via flake pinning, but builds on an unmaintained base |
| Astro Starlight / MDX frameworks | Best looks, but npm toolchain → `buildNpmPackage` hash churn in every update |
| mdBook | In nixpkgs, very stable, but no i18n story and a plain look |
| **Zensical** | Material team's successor; reads MkDocs-style config; packaged top-level in nixpkgs |

## Decision

Migrate to **Zensical**, with configuration in its native `zensical.toml`
format (one file per language; TOML has no inheritance).

## Consequences

- Content and structure carried over unchanged; the bilingual two-build
  layout (`/` + `/ko/`) works identically.
- Build stays pure-Nix: `pkgs.zensical` from nixpkgs, no extra toolchain.
- Risk accepted: Zensical is 0.0.x. Mitigations: output is static HTML
  (failure cannot affect hosts), flake pinning freezes a known-good version,
  and the documented fallback is reverting to mkdocs-material, which remains
  buildable.
- Known quirk: some documented settings differ from implementation (e.g.,
  the generator notice toggle lives under `extra`, not `project`).
