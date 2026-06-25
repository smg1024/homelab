---
icon: fontawesome/solid/robot
---

# CI/CD pipeline

GitHub Actions builds every change and, once it lands on `main`, deploys it to
the hosts automatically. This is the default validation and deployment path.
The manual [`just` workflow](deploy.md) stays as the explicit-request
break-glass path. The pipeline runs the same `nixos-rebuild`, just unattended.

The split is deliberate:

- **CI** proves every host *builds*, on a throwaway runner that touches no host.
- **CD** rolls merged changes out, joining the tailnet and running the same
  `nixos-rebuild switch` used by the explicit manual path.

## Flow

```text
PR / push ──▶ CI: build each host's system closure   (build only, no host touched)
                 └─ required checks gate the merge
merge to main ──▶ CD: join tailnet → nixos-rebuild switch on every host
```

## CI: build check

`.github/workflows/ci.yml`, triggered on pull requests to `main`.

- One job per host builds
  `nixosConfigurations.<host>.config.system.build.toplevel`.
- It **only builds**: no activation, no tailnet, no secrets. A config that
  fails to evaluate or compile fails here, before it can reach a host.
- `yggdrasil` and `midgard` build on `ubuntu-latest`; `alfheim` builds on a
  native `ubuntu-24.04-arm` runner, so its `aarch64` closure is built natively
  instead of emulated.
- Encrypted secrets are not needed: sops files are ciphertext in the store and
  build fine (see [Secrets](secrets.md)).

Mark the three `build …` checks as **required** in branch protection so only
buildable configs can reach `main`.

## CD: deploy on merge

`.github/workflows/deploy.yml`, triggered on push to `main` (a merge).

Each host is handled by a job that:

1. Joins the tailnet as an **ephemeral** node tagged `tag:ci` (via a Tailscale
   OAuth client) and waits until the target node is reachable before continuing.
2. Loads the deploy key and runs, for that host:

    ```text
    nixos-rebuild switch
      --no-reexec
      --flake .#<host>
      --build-host <host>      # the node itself
      --target-host <host>     # the node itself
      --sudo
    ```

Because `--build-host` and `--target-host` are both the node, **each host builds
itself**, matching the explicit manual path. The runner only evaluates the
flake and orchestrates, so there is no cross-architecture build problem
(`alfheim` compiles its own `aarch64` closure) and no binary cache to maintain. A
`concurrency` group serializes deploys so two merges never race.

All three hosts are switched on every merge; an unaffected host simply
re-activates the same generation, which is a fast no-op.

## Prerequisites

| What | Where | Purpose |
| --- | --- | --- |
| `DEPLOY_SSH_KEY` | GitHub Actions secret | Private key the runner uses to SSH in as `poby` |
| `TS_OAUTH_CLIENT_ID` / `TS_OAUTH_SECRET` | GitHub Actions secrets | Tailscale OAuth client that mints ephemeral `tag:ci` nodes |
| Deploy public key | `modules/users.nix` → `poby` authorized keys | Authorizes the runner on every host |
| `tag:ci` + ACL | Tailscale admin | Declares the tag and grants `tag:ci` access to the hosts on port 22 |

The deploy key is just another entry in `poby`'s `authorizedKeys`, and `poby`
already has passwordless `sudo` (`security.sudo.wheelNeedsPassword = false`), so
no extra host-side setup is required.

!!! warning "Bootstrap order"
    The runner can only log in once the hosts already trust the deploy key. The
    first rollout of that key may need an explicit manual
    [`just switch`](deploy.md). After that, merges deploy on their own.

## Day to day

1. Open a PR. CI builds all three hosts.
2. Merge once the checks are green. CD switches every host within a couple of
   minutes.
3. Follow a run from the repository's Actions tab, or:

    ```bash
    gh run watch <run-id> --exit-status
    ```

## Caveats

- **No automatic rollback.** A merge `switch` has no magic rollback, and green
  CI proves a config *builds*, not that it *runs*. Keep an eye on the
  [monitoring stack](../services/monitoring.md) after a deploy, and roll back by
  hand if a service misbehaves.
- **Break-glass stays explicit.** Local `just test` / `just switch` commands
  are not part of the normal flow. Use them only when an operator explicitly
  asks for a local activation, and roll back with
  `sudo nixos-rebuild switch --rollback`.
- **Keep changes flowing through PRs.** A direct push to `main` skips CI;
  enforce the build checks with branch protection so `main` stays deployable.
