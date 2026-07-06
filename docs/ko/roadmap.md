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
- [ ] **알림 전달**: Prometheus 규칙은 있지만 Alertmanager가 미구성이라
      알림이 UI에서만 보임 ([상세](services/monitoring.md))

## 다음

- [x] **alfheim**에 실제 역할 부여:
      [jamye-plz](services/applications.md)가
      OCI 노드에서 실행되며 클라우드 호스트 패턴을 검증
- [x] 이 문서를 공개 서빙:
      [docs.ridewithmin.com](https://docs.ridewithmin.com/)은 Cloudflare
      Tunnel을 거쳐 midgard의 static-web-server가 제공합니다
- [ ] 이 사이트에 페이지별 **편집 버튼** (`content.action.edit` +
      Forgejo `edit_uri`)
- [ ] tailnet 전용 화면 중 **Cloudflare Access**를 2차 방어로 둘 곳이
      있는지 검토

## 언젠가 / 아이디어

- [ ] midgard의 Hermes Agent 선언적 구성 (안정화되면 변경 가능한 `~/.hermes`에서
      승격)
- [ ] Grafana 대시보드 코드화 확대 (프로비저닝 대시보드 추가)

!!! tip "이 페이지 사용법"
    항목이 완료되면 체크하고 관련 페이지나 커밋을 링크하세요. 우선순위가
    바뀌면 순서를 조정하세요. 이 페이지는 약속이 아니라 살아있는
    문서입니다.
