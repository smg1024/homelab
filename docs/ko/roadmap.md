---
icon: fontawesome/solid/map
---

# 로드맵

이 홈랩이 향하는 곳. 체크된 항목은 완료된 작업으로 연결되고, 미체크 항목은
아직 하려는 일입니다. 각 구간 안에서는 대략 우선순위 순으로 적었습니다.

## 지금 (운영 공백)

- [ ] **자동 백업** (현재 없음, [상세](runbooks/backup-restore.md)):
    - [ ] Vaultwarden SQLite DB용 `services.vaultwarden.backupDir`
    - [ ] Forgejo dump 또는 외부 원격 미러링
    - [ ] midgard `/var/lib`를 호스트 밖으로 보내는 백업 작업 (restic/borgbackup)
- [x] **알림 전달**: Beszel이 시스템별 임계값으로 이메일 알림을 보내며,
      연결돼 있지 않던 기존 Prometheus 규칙을 대체
      ([상세](services/monitoring.md))

## 다음

- [x] **alfheim**에 실제 역할 부여:
      [jamye-plz](services/applications.md)가
      OCI 노드에서 실행되며 클라우드 호스트 패턴을 검증
- [x] 이 문서를 공개 서빙:
      [docs.ridewithmin.com](https://docs.ridewithmin.com/)은 Cloudflare
      Tunnel을 거쳐 yggdrasil의 Caddy가 Nix 스토어에서 직접 제공합니다
- [x] Grafana/Prometheus/Loki/Alloy 스택을 **Beszel + VictoriaLogs**로
      교체: yggdrasil 4 GB에 더 가볍고, UI가 더 친절하고, 알림 전달이
      실제로 동작 ([상세](services/monitoring.md))
- [ ] 이 사이트에 페이지별 **편집 버튼** (`content.action.edit` +
      Forgejo `edit_uri`)
- [ ] tailnet 전용 화면 중 **Cloudflare Access**를 2차 방어로 둘 곳이
      있는지 검토

## 언젠가 / 아이디어

- [ ] midgard의 Hermes Agent 선언적 구성 (안정화되면 변경 가능한 `~/.hermes`에서
      승격)
- [ ] Beszel 알림 임계값의 선언적 구성 (현재는 UI에서 관리하는 상태;
      업스트림이 DB 밖 설정을 지원하게 되면)

!!! tip "이 페이지 사용법"
    항목이 완료되면 체크하고 관련 페이지나 커밋을 링크하세요. 우선순위가
    바뀌면 순서를 조정하세요. 이 페이지는 약속이 아니라 살아있는
    문서입니다.
