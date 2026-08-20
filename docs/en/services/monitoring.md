---
icon: fontawesome/solid/chart-line
---

# Monitoring

Beszel collects metrics and VictoriaLogs stores logs. Both run on `yggdrasil`.
Uptime Kuma checks public endpoints and serves the status page.

## Components

| Module | Role | Binding |
| --- | --- | --- |
| `services/beszel/hub.nix` | Beszel hub: metrics UI, history, alerts | `0.0.0.0:8090` (tailnet only via trusted interface) |
| `services/beszel/agent.nix` | Beszel agent: per-host metrics source (all hosts) | outbound WebSocket to the hub |
| `services/victorialogs.nix` | VictoriaLogs log store + query UI, `14d` retention | `:9428` (tailnet only via trusted interface) |
| `services/log-shipper.nix` | journald → VictoriaLogs shipping (all hosts) | vlagent on `:9429` (tailnet-reachable via trusted interface; fed via localhost) |
| `services/uptime-kuma.nix` | public endpoint checks + status page | `127.0.0.1:3001` |

## Metrics flow

Each host runs a Beszel agent that connects to the hub over the
tailnet (WebSocket); no inbound scrape ports are needed. Agents self-register
using the hub public key and universal token from `secrets/beszel.yaml`
(`SYSTEM_NAME` is the hostname).

```text
beszel-agent (yggdrasil) ──┐
beszel-agent (midgard)   ──┼── WebSocket ──> beszel-hub :8090 (yggdrasil)
beszel-agent (alfheim)   ──┘
```

Agents report CPU, memory, disk, network, load, temperature, and systemd
service status. The agent does not collect Podman container stats because it
would need midgard's Podman docker-compatible socket
(`virtualisation.podman.dockerSocket.enable`), which is not enabled.

!!! note "Universal token must be active for registration"
    An agent can self-register only while the hub's universal token is
    active. After seeding the token into `secrets/beszel.yaml`, activate it
    once via `GET /api/beszel/universal-token?token=<value>&enable=1`
    (authenticated). Registered agents keep a persistent fingerprint in the
    hub DB and reconnect without the token.

## Alerts

Configure alert thresholds (status, CPU, memory, disk, load average,
temperature, bandwidth) and email delivery in the Beszel UI
(Settings → Notifications, shoutrrr URLs), not in the repo. They live in the
hub database under `/var/lib/beszel-hub`. This database is one of the few
pieces of state that is not declarative.

## Logs flow

```text
journald -> systemd-journal-upload -> vlagent :9429 (local buffer)
         -> VictoriaLogs :9428 on yggdrasil (/internal/insert)
```

- `systemd-journal-upload` reads the journal on every host. Its unit starts
  after `vlagent` so cold boots do not race the local listener.
- `vlagent` buffers on disk and retries, so a hub restart (e.g. a deploy on
  yggdrasil) does not drop logs.
- Retention is `14d`. Journald fields (`_HOSTNAME`, `_SYSTEMD_UNIT`,
  `PRIORITY`, ...) map directly into VictoriaLogs and are queryable in
  LogsQL.

## Access

From a tailnet-connected client:

```text
https://beszel.ridewithmin.com   # metrics + alerts
https://logs.ridewithmin.com     # log search (VictoriaLogs web UI)
```

Caddy restricts both routes to tailnet clients. Direct tailnet access also
works (`yggdrasil.tail6fc192.ts.net:8090` and `:9428/select/vmui/`).

## Health checks

```bash
# on yggdrasil
systemctl is-active beszel-hub victorialogs
curl -fsS http://127.0.0.1:8090/api/health
curl -fsS http://127.0.0.1:9428/ping

# on every host
systemctl is-active beszel-agent vlagent systemd-journal-upload
```

This command returns per-host log counts for the last hour from any tailnet
client:

```bash
curl -s http://yggdrasil.tail6fc192.ts.net:9428/select/logsql/query \
  --data-urlencode 'query=_time:1h | stats by (_HOSTNAME) count() logs'
```
