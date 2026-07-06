---
icon: fontawesome/solid/server
---

# yggdrasil

공개 진입점이자 경량 인프라 노드입니다. RAM이 4 GB뿐이라 가볍게
유지하는 것을 원칙으로 삼고, 애플리케이션은 올리지 않습니다.

## 책임

- Cloudflare Tunnel 유지 (`cloudflared`)
- 공개 도메인을 내부 서비스로 라우팅하는 Caddy 리버스 프록시 운영
- Uptime Kuma 공개 상태 페이지 서빙
- Beszel 허브: 메트릭 수집과 알림 (tailnet 제한 Caddy 라우트)
- VictoriaLogs 로그 저장소 + 조회 UI (tailnet 제한 Caddy 라우트)

## 로드하는 서비스 모듈

```text
services/ingress.nix      # Caddy + Cloudflare DNS 플러그인
services/cloudflared.nix  # Cloudflare Tunnel
services/uptime-kuma.nix
services/victorialogs.nix
services/beszel/hub.nix
```

## 로컬 포트

| 포트 | 서비스 | 바인딩 |
| --- | --- | --- |
| `443` | Caddy | 공개 (Tunnel 오리진) |
| `3001` | Uptime Kuma | localhost |
| `8090` | Beszel 허브 | 전체 인터페이스, 신뢰된 `tailscale0` 경유만 도달 가능 |
| `9428` | VictoriaLogs | 전체 인터페이스, 신뢰된 `tailscale0` 경유만 도달 가능 |
| `9429` | vlagent | 전체 인터페이스, 방화벽 미개방 (journal-upload가 localhost로 전송) |
| `45876` | beszel-agent | 방화벽 미개방 (에이전트가 허브로 먼저 접속) |

## 점검

```bash
systemctl is-active caddy cloudflared-tunnel-* uptime-kuma
systemctl is-active beszel-hub victorialogs beszel-agent vlagent
curl -fsS http://127.0.0.1:8090/api/health
curl -fsS http://127.0.0.1:9428/ping
```
