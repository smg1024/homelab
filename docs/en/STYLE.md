---
icon: fontawesome/solid/pen-nib
---

# Documentation style guide

The writing conventions the English docs (`docs/en/`) follow. Use this when you
write a new page or revise an old one, or when you translate from or to the
Korean tree. The goal is not spell-checking but **consistency across the whole
site**.

These are **technical docs**: commands, paths, ports, code blocks, and tables
do most of the work. Keep the tone plain and neutral, and leave tool and
protocol names in their original spelling.

## 1. Voice and register

- Write in plain, present-tense English. Say what a thing is and what it does,
  and skip the build-up.
- Use the imperative for instructions: "Open a PR", "Roll back on the host".
- Prefer "is", "are", and "has" over "serves as", "acts as", and "is
  responsible for".
- No marketing voice. Drop "powerful", "seamless", "robust", "vibrant",
  "leverage", "showcase", and the rest of that vocabulary.
- A one-line deck under the H1 is fine, as long as it is concrete: "What
  survives a dead disk, what does not, and how to get back."
- No em dashes or en dashes. Use a period, comma, colon, or parentheses
  instead. (The em dash is the single most common AI-writing tell.)

```text
✅ yggdrasil is the public entry point. It has 4 GB of RAM, so keep it light.
✅ Caddy selects the backend by hostname.
⚠️ yggdrasil serves as the entry point — a testament to lightweight design.
   (copula avoidance + em dash + puffery)
```

## 2. Terminology

Tool, protocol, and command names keep their **original spelling**. General
words use the plain English term, spelled the same way every time.

| Kind | Spelling | Notes |
| --- | --- | --- |
| Keep as-is | `tailnet`, `flake`, `PR`, `SSH`, `DNS`, `CI/CD`, `OCI`, `RAM`, `API`, `PWA`, `JWT`, `OAuth`, `ACL`, `sops`, `MagicDNS` | Initialisms uppercase; `sops-nix` stays lowercase |
| Product / tool names | `Cloudflare Tunnel`, `Caddy`, `Tailscale`, `NixOS`, `Podman`, `Prometheus`, `Grafana`, `Loki`, `Forgejo`, `Vaultwarden`, `Zensical` | Keep upstream casing |
| House spellings | "repo" (short for the Git repository), "tailnet" (lowercase), "public Internet" (capital I), host names lowercase (`yggdrasil`, `midgard`, `alfheim`) | |

Host names are lowercase everywhere, in prose and in code. Wrap a host name in
inline code when it names a config target (`just switch midgard`), plain
otherwise ("midgard runs Forgejo").

## 3. Numbers and units

- Capacities and sizes in prose use **number + space + unit**: `4 GB`,
  `512 MB`.
- Config literals (`512M`, `15d`, `3m`) keep their raw form and go in
  `inline code`.
- Ports go in inline code: `:8080`, `127.0.0.1:9090`.

## 4. Lists and structure

- Bullets use `-`, numbered steps use `1.` `2.`, tasks use `- [ ]` checklists.
- Headings are **sentence case**: "Design principles", not "Design Principles".
- Every code block declares its language: ` ```bash `, ` ```nix `, ` ```text `,
  ` ```mermaid `.
- Every page starts with navigation-icon front matter.

```markdown
---
icon: fontawesome/solid/<name>
---
```

## 5. Code, emphasis, and quotes

- Identifiers, paths, ports, commands, filenames, hostnames, and module names
  go in `inline code`.
- Warnings and required conditions go in **bold**, used sparingly.
- Concepts and quoted phrases use straight double quotes `"..."`, never curly
  quotes.
- Boxed asides use admonitions: `!!! note`, `!!! tip`, `!!! warning`,
  `!!! danger`.

## 6. Dates

- Structured metadata (status and date fields) uses ISO `YYYY-MM-DD`, for
  example `2026-06-12`.
- Prose uses the month-and-year form: "June 2026", "as of June 2026".

## 7. Links

- Internal links are relative inline links: `[security model](security.md)`,
  `[principles](../principles.md)`.
- The build runs `zensical build --strict`, so a broken internal link or a page
  missing from `nav` fails the build. Register every new page in the `nav` of
  `zensical.toml` (see [Docs site](runbooks/docs-site.md)).
- English is the source of truth. Mirror every page in the Korean `docs/ko/`
  tree and add it to `zensical.ko.toml` as well.

## Quick checklist

- [ ] Plain present-tense voice; imperative for steps; "is/are/has" over "serves as"
- [ ] No em or en dashes; no marketing words
- [ ] Tech names kept as-is (`tailnet`, `flake`, `PR`); host names lowercase
- [ ] Capacities as `4 GB`; config literals like `15d` in inline code
- [ ] Language tag on every code block; icon front matter on every page
- [ ] Identifiers in `inline code`, warnings in **bold**, notes in `!!!` admonitions
- [ ] Dates: ISO in fields, "June 2026" in prose
- [ ] Internal links valid; new pages added to `nav` and mirrored in `docs/ko/`
