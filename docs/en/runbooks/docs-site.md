---
icon: fontawesome/solid/book-open
---

# Docs site

The flake declares the docs site. Markdown lives under `docs/`, and
[Zensical](https://zensical.org/), the Material for MkDocs team's static site
generator, builds it. Caddy serves the result directly from the Nix store on
yggdrasil with `file_server`. Public traffic reaches Caddy through Cloudflare
Tunnel. Zensical reads its native `zensical.toml` configuration.

English is the default language; a Korean translation is built as a separate
subsite under `/ko/`. The language selector in the header switches between
them.

## Structure

```text
docs/
├── package.nix       # the derivation, wired via callPackage in flake.nix
├── shell.nix         # dev shell for `zensical serve`, inherits package deps
├── Makefile          # build (`make`) and install (`make install`) targets
├── zensical.toml     # English (default) site config
├── zensical.ko.toml  # Korean site config (full copy, TOML has no inheritance)
├── en/               # English content (source of truth)
└── ko/               # Korean translation, mirrors en/
```

- The `packages.<system>.docs` flake output builds both languages with
  `zensical build --strict` and places Korean under the `ko/` subdirectory.
- The `docs.ridewithmin.com` virtual host in `services/ingress.nix` serves the
  built package with Caddy `file_server` on yggdrasil. Cloudflare Tunnel carries
  public requests to Caddy.

## Editing workflow

1. Edit the English page under `docs/en/` first, then mirror the change in
   `docs/ko/`. A new page also needs two updates in both languages:
    - add it to the `nav` of `zensical.toml` and `zensical.ko.toml`
    - give it a navigation icon via front matter at the top of the file:

      ```markdown
      ---
      icon: fontawesome/solid/<name>
      ---
      ```

      Icon names: [zensical/ui icon sets](https://github.com/zensical/ui/tree/master/dist/.icons).
2. Validate the build locally.

    ```bash
    nix build .#docs
    ```

    `--strict` mode turns broken internal links into build failures.

3. For a live preview, use the devShell.

    ```bash
    nix develop .#docs
    cd docs && zensical serve                       # English
    cd docs && zensical serve -f zensical.ko.toml   # Korean
    # open http://127.0.0.1:8000
    ```

4. Commit and open a PR. Once CI is green, merge it and let CD deploy the
   docs with the rest of the system closure. Do not run a local `just switch`
   unless an operator explicitly asks for it.

!!! note "flakes and git"
    Flake builds only see files tracked by git. New files must be
    `git add`ed before `nix build .#docs` picks them up.
