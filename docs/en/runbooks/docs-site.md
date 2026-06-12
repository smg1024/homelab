# Docs site

This site itself is declared in the flake. Content lives as Markdown under
`docs/`, is built with [Zensical](https://zensical.org/) (the static site
generator by the Material for MkDocs team), and is served as static files by
Caddy on yggdrasil (tailnet only). Zensical reads the MkDocs-style
`mkdocs.yml` configs natively.

English is the default language; a Korean translation is built as a separate
subsite under `/ko/`. The language selector in the header switches between
them.

## Structure

```text
docs/
├── mkdocs.yml      # base config — English (default) site
├── mkdocs.ko.yml   # Korean overrides via INHERIT
├── en/             # English content (source of truth)
└── ko/             # Korean translation, mirrors en/
```

- flake output: `packages.<system>.docs` — both languages built with
  `zensical build --strict`, Korean into the `ko/` subdirectory
- serving module: `services/docs-site.nix` — Caddy `file_server`, tailnet only

## Editing workflow

1. Edit the English page under `docs/en/` first, then mirror the change in
   `docs/ko/`. A new page must be added to the `nav` of **both**
   `mkdocs.yml` and `mkdocs.ko.yml`.
2. Validate the build locally.

    ```bash
    nix build .#docs
    ```

    `--strict` mode turns broken internal links into build failures.

3. For a live preview, use the devShell.

    ```bash
    nix develop .#docs
    cd docs && zensical serve                    # English
    cd docs && zensical serve -f mkdocs.ko.yml   # Korean
    # open http://127.0.0.1:8000
    ```

4. Commit, then deploy — the docs are part of the system closure and update
   together.

    ```bash
    just switch yggdrasil
    ```

!!! note "flakes and git"
    Flake builds only see files tracked by git. New files must be
    `git add`ed before `nix build .#docs` picks them up.
