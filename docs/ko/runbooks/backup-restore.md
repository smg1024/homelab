---
icon: fontawesome/solid/box-archive
---

# 백업과 복구

디스크가 죽었을 때 살아남는 것, 사라지는 것, 그리고 되돌아오는 길.

!!! warning "자동 백업 미구성"
    2026년 6월 현재 이 홈랩 어디에도 자동 백업이 구성되어 있지 않습니다.
    아래 "재현 가능한 것 vs 데이터인 것"에서 데이터로 분류한 항목은 모두
    무방비 상태입니다.
    해결은 [로드맵](../roadmap.md) 항목입니다.

## 재현 가능한 것 vs 데이터인 것

저장소에서 재현 가능: 모든 호스트의 시스템 구성 전체.
[부트스트랩 런북](bootstrap-host.md)으로 머신을 처음부터 재구축할 수 있으므로
백업이 필요 없습니다.

진짜 데이터는 호스트에만 존재하는 상태입니다:

| 데이터 | 호스트 | 위치 (NixOS 모듈 기본값) | 유실 시 |
| --- | --- | --- | --- |
| Vaultwarden DB + 첨부파일 | midgard | `/var/lib/vaultwarden` | **치명적**: 모든 비밀번호 |
| Forgejo 저장소 + DB | midgard | `/var/lib/forgejo` | **치명적**: 다른 곳에 push 안 된 Git 히스토리 전부 |
| Uptime Kuma 설정/이력 | yggdrasil | `/var/lib/private/uptime-kuma` | 성가심: 체크를 손으로 재생성 |
| Grafana 대시보드 (비프로비저닝) | yggdrasil | `/var/lib/grafana` | 낮음: 주 대시보드는 저장소에서 프로비저닝됨 |
| Prometheus TSDB | yggdrasil | `/var/lib/prometheus2` | 수용 가능: 보존 15d 메트릭 |
| Loki 로그 | yggdrasil | Loki `dataDir` | 수용 가능 |

키 두 가지는 특별히 신경 써야 합니다:

- **호스트 SSH 키**(`/etc/ssh/ssh_host_ed25519_key`): sops age 신원이기도
  합니다. 호스트가 죽으면 키도 함께 죽고 복구는 `poby` 운영자 키가
  `.sops.yaml` 수신자라는 사실에 의존합니다(현재 등록됨). 재구축 후 새
  호스트 키를 등록하고 재암호화하세요 ([절차](secrets.md)).
- **`poby`의 age 키와 SSH 개인키**는 신뢰의 뿌리입니다. 홈랩 밖에 사본을
  보관하세요 (Vaultwarden 비상 키트 등, 단 Vaultwarden *안에만* 두면
  순환 의존이 됩니다).

## 복구 경로 (호스트 유실 시)

1. 호스트 재구축: [부트스트랩 런북](bootstrap-host.md)
2. tailnet 재합류 (`sudo tailscale up`), MagicDNS 이름 복구
3. 호스트 키가 바뀌었으면 sops 재암호화 후 재배포
4. 백업에서 데이터 디렉토리 복원 *(백업이 생긴 뒤의 이야기)*
5. 각 서비스 페이지의 점검 절차 수행, Uptime Kuma 녹색 확인

## 앞으로 갈 방향

가치 순서대로, 자연스러운 첫 단계들:

1. `services.vaultwarden.backupDir`: 모듈에 SQLite 백업이 내장되어 있어
   가장 비용이 낮은 첫 단계
2. Forgejo dump 또는 외부 원격으로 저장소 미러링
3. midgard `/var/lib` 상태를 호스트 밖(예: alfheim 또는 오브젝트
   스토리지)으로 보내는 restic/borgbackup 작업
