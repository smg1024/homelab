---
icon: fontawesome/solid/map
---

# 로드맵

이 홈랩이 향하는 곳. 체크된 항목은 완료된 작업으로 연결되고 미체크 항목은
의도이며 각 구간 안에서 대략 우선순위 순입니다.

## 지금 (운영 공백)

- [ ] **자동 백업** (현재 없음, [상세](runbooks/backup-restore.md)):
    - [ ] Vaultwarden SQLite DB용 `services.vaultwarden.backupDir`
    - [ ] Forgejo dump 또는 외부 원격 미러링
    - [ ] midgard `/var/lib`를 호스트 밖으로 보내는 백업 작업 (restic/borgbackup)
- [ ] **알림 전달**: Prometheus 규칙은 있지만 Alertmanager가 미구성이라
      알림이 UI에서만 보임 ([상세](services/monitoring.md))
- [ ] **이 문서 사이트 배포**: docs 브랜치 머지, `just switch yggdrasil`,
      `docs.ridewithmin.com` DNS 레코드 추가

## 다음

- [ ] **alfheim**에 실제 역할 부여: 위험도 낮은 서비스 하나를 OCI 노드로
      승격해 클라우드 호스트 패턴 검증
- [ ] 이 사이트에 페이지별 **편집 버튼** (`content.action.edit` +
      Forgejo `edit_uri`)
- [ ] tailnet 전용 화면 중 **Cloudflare Access**를 2차 방어로 둘 곳이
      있는지 검토

## 언젠가 / 아이디어

- [ ] 이 문서의 공개(읽기 전용) 버전
- [ ] midgard의 Hermes Agent 선언적 구성 (안정화되면 변경 가능한 `~/.hermes`에서
      승격)
- [ ] Grafana 대시보드 코드화 확대 (프로비저닝 대시보드 추가)

!!! tip "이 페이지 사용법"
    항목이 완료되면 체크하고 관련 페이지나 커밋을 링크하세요. 우선순위가
    바뀌면 순서를 조정하세요. 이 페이지는 약속이 아니라 살아있는
    문서입니다.
