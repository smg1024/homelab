---
icon: fontawesome/solid/chart-line
---

# 모니터링

메트릭은 **Beszel**, 로그는 **VictoriaLogs**가 담당하며 둘 다 `yggdrasil`에서
실행됩니다. Uptime Kuma는 공개 엔드포인트 체크를 수행하고 상태 페이지를
제공합니다.

## 구성 요소

| 모듈 | 역할 | 바인딩 |
| --- | --- | --- |
| `services/beszel/hub.nix` | Beszel 허브: 메트릭 UI, 이력, 알림 | `0.0.0.0:8090` (신뢰 인터페이스 경유 tailnet 전용) |
| `services/beszel/agent.nix` | Beszel 에이전트: 호스트별 메트릭 소스 (전 호스트 공통) | 허브로 나가는 WebSocket |
| `services/victorialogs.nix` | VictoriaLogs 로그 저장소 + 조회 UI, `14d` 보존 | `:9428` (신뢰 인터페이스 경유 tailnet 전용) |
| `services/log-shipper.nix` | journald → VictoriaLogs 전송 (전 호스트 공통) | vlagent `127.0.0.1:9429` |
| `services/uptime-kuma.nix` | 공개 엔드포인트 체크 + 상태 페이지 | `127.0.0.1:3001` |

## 메트릭 흐름

각 호스트의 Beszel 에이전트가 tailnet을 통해 허브로 **먼저 접속**합니다
(WebSocket). 수집용 인바운드 포트가 필요 없습니다. 에이전트는
`secrets/beszel.yaml`의 허브 공개 키와 universal token으로 스스로 등록하며
(`SYSTEM_NAME`은 호스트네임), CPU·메모리·디스크·네트워크·로드·온도·systemd
서비스 상태·Podman 컨테이너 통계(midgard)를 보고합니다.

```text
beszel-agent (yggdrasil) ──┐
beszel-agent (midgard)   ──┼── WebSocket ──> beszel-hub :8090 (yggdrasil)
beszel-agent (alfheim)   ──┘
```

!!! note "등록에는 universal token 활성화가 필요"
    에이전트 자동 등록은 허브의 universal token이 활성화된 동안에만
    가능합니다. `secrets/beszel.yaml`에 토큰을 넣은 뒤
    `GET /api/beszel/universal-token?token=<값>&enable=1`(인증 필요)로 한 번
    활성화합니다. 등록된 에이전트는 허브 DB에 fingerprint가 남아 토큰 없이
    재접속합니다.

## 알림

알림 임계값(상태, CPU, 메모리, 디스크, 로드, 온도, 대역폭)과 이메일 전송은
저장소가 아니라 **Beszel UI**(Settings → Notifications, shoutrrr URL)에서
설정합니다. 이 설정은 `/var/lib/beszel-hub` 아래 허브 데이터베이스에
저장되는, 선언형이 아닌 몇 안 되는 상태입니다.

## 로그 흐름

```text
journald -> systemd-journal-upload -> vlagent :9429 (로컬 버퍼)
         -> yggdrasil의 VictoriaLogs :9428 (/internal/insert)
```

- `systemd-journal-upload`가 각 호스트의 저널을 읽습니다. 콜드 부트 시
  로컬 리스너와 경합하지 않도록 `vlagent` 뒤로 순서를 강제했습니다.
- `vlagent`는 디스크에 버퍼링하고 재시도하므로 허브 재시작(예: yggdrasil
  배포) 중에도 로그가 유실되지 않습니다.
- 보존 기간은 `14d`입니다. journald 필드(`_HOSTNAME`, `_SYSTEMD_UNIT`,
  `PRIORITY` 등)가 VictoriaLogs에 그대로 매핑되어 LogsQL로 조회할 수
  있습니다.

## 접근 방법

tailnet에 연결된 클라이언트에서:

```text
https://beszel.ridewithmin.com   # 메트릭 + 알림
https://logs.ridewithmin.com     # 로그 검색 (VictoriaLogs 웹 UI)
```

두 라우트 모두 Caddy에서 tailnet 대역으로 제한됩니다. tailnet 직접 접근도
가능합니다 (`yggdrasil.tail6fc192.ts.net:8090`, `:9428/select/vmui/`).

## 점검

```bash
# yggdrasil에서
systemctl is-active beszel-hub victorialogs
curl -fsS http://127.0.0.1:8090/api/health
curl -fsS http://127.0.0.1:9428/ping

# 모든 호스트에서
systemctl is-active beszel-agent vlagent systemd-journal-upload
```

tailnet 클라이언트에서 최근 1시간 호스트별 로그 수를 빠르게 확인:

```bash
curl -s http://yggdrasil.tail6fc192.ts.net:9428/select/logsql/query \
  --data-urlencode 'query=_time:1h | stats by (_HOSTNAME) count() logs'
```
