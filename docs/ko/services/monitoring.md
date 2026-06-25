---
icon: fontawesome/solid/chart-line
---

# 모니터링

메트릭과 로그 스택은 `yggdrasil`에서 실행됩니다. Uptime Kuma는 공개 엔드포인트
체크를 수행하고 상태 페이지를 제공합니다.

## 구성 요소

| 모듈 | 역할 | 바인딩 |
| --- | --- | --- |
| `services/prometheus/` | 노드 메트릭 수집, 알림 규칙 평가, 15d 보존 | `127.0.0.1:9090` |
| `services/grafana/` | 대시보드, Prometheus 기본 데이터소스 프로비저닝 | `127.0.0.1:3003` |
| `services/loki.nix` | 로그 저장소 | localhost |
| `services/alloy.nix` | 각 호스트의 로그 수집 → Loki 전송 (전 호스트 공통) | |
| `services/node-exporter.nix` | 노드 메트릭 (전 호스트 공통, systemd 콜렉터 포함) | `:9100` |
| `services/uptime-kuma.nix` | 공개 엔드포인트 체크 + 상태 페이지 | `127.0.0.1:3001` |

## Prometheus 수집 대상

```text
127.0.0.1:9100                  -> yggdrasil node_exporter
midgard.tail6fc192.ts.net:9100  -> midgard node_exporter (tailnet 경유)
```

수집 주기는 `3m`입니다.

## 알림 규칙

`services/prometheus/node-health-alert-rule.yml`에 정의되어 있습니다.

- `NodeDown`, `CriticalServiceInactive`, `SystemdServiceFailed`
- `RootDiskLow`, `RootInodesLow`, `RootFilesystemReadOnly`
- `LowMemory`, `HighCpuUsage`, `HighLoad`

!!! warning "Alertmanager 미구성"
    규칙은 Prometheus UI에서 확인할 수 있지만 Alertmanager로 외부에 알림을
    보내는 구성은 아직 없습니다.

## 접근 방법

Grafana, tailnet에 연결된 클라이언트에서:

```text
https://grafana.ridewithmin.com
```

Prometheus UI, SSH 포트 포워딩으로:

```bash
ssh -L 9090:127.0.0.1:9090 yggdrasil
# http://127.0.0.1:9090 접속
```

## 점검

```bash
# yggdrasil에서
systemctl is-active prometheus prometheus-node-exporter grafana loki
curl -fsS http://127.0.0.1:9090/-/ready
curl -fsS http://127.0.0.1:9090/api/v1/targets | jq
curl -fsS http://127.0.0.1:3003/api/health | jq
```
