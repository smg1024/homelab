---
icon: fontawesome/solid/server
---

# yggdrasil

공개 진입점이자 경량 인프라 노드입니다. RAM이 4 GB뿐이므로 가볍게
유지하는 것이 원칙이고 애플리케이션은 올리지 않습니다.

## 책임

- Cloudflare Tunnel 유지 (`cloudflared`)
- Caddy 리버스 프록시 운영 — 공개 도메인을 내부 서비스로 라우팅
- Uptime Kuma 공개 상태 페이지 서빙
- Prometheus 노드 메트릭 수집 및 알림 규칙 평가
- Grafana 대시보드 (tailnet 제한 Caddy 라우트)
- Loki 로그 저장소
- 이 문서 사이트 공개 서빙 (Cloudflare Tunnel)

## 로드하는 서비스 모듈

```text
services/ingress.nix      # Caddy + Cloudflare DNS 플러그인
services/cloudflared.nix  # Cloudflare Tunnel
services/uptime-kuma.nix
services/prometheus/
services/loki.nix
services/grafana/
services/docs-site.nix    # 이 문서 사이트
```

## 로컬 포트

| 포트 | 서비스 | 바인딩 |
| --- | --- | --- |
| `443` | Caddy | 공개 (Tunnel 오리진) |
| `3001` | Uptime Kuma | localhost |
| `3003` | Grafana | localhost |
| `8081` | Grafana image renderer | localhost |
| `9090` | Prometheus | localhost |
| `9100` | node_exporter | 방화벽 미개방 |

## 점검

```bash
systemctl is-active caddy cloudflared-tunnel-* uptime-kuma
systemctl is-active prometheus grafana loki
curl -fsS http://127.0.0.1:9090/-/ready
curl -fsS http://127.0.0.1:3003/api/health | jq
```
