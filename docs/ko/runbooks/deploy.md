---
icon: fontawesome/solid/rocket
---

# 배포와 롤백

모든 변경은 저장소에서 시작합니다. 호스트에서 직접 설정을 고치지 않습니다.

## PR 전 검증

GitHub Actions CI가 기준 빌드 체크입니다. PR을 열기 전에 로컬에서 확인하면
문제를 빨리 찾습니다.

```bash
nix flake check --no-build
nix flake show --all-systems
```

## 배포

표준 배포 경로는 GitHub Actions입니다.

1. PR을 엽니다.
2. CI가 모든 호스트를 빌드할 때까지 기다립니다.
3. 체크가 초록색이면 병합합니다.
4. CD가 `yggdrasil`, `midgard`, `alfheim`을 switch하게 둡니다.

자세한 흐름은 [CI/CD 파이프라인](ci-cd.md)을 참고합니다.

## Jamye 종료와 서버 호스트 이동 (2026년 10월)

jamye-plz를 비활성화하고 jamye-server를 midgard에서 alfheim으로 옮깁니다.
jamye-plz는 보관만 하고 다른 호스트에 복원하지 않습니다. jamye-server는
PostgreSQL 17을 유지하며 처음 시작하기 전에 데이터베이스, MinIO object,
애플리케이션 상태와 Redis 데이터를 복원합니다.

**두 스냅샷을 완료하고 jamye-server 스냅샷을 alfheim에 준비하기 전에는 PR을
병합하지 않습니다.** `jamye-host-swap` unit은 jamye-server target, 인프라,
migration, API와 worker를 모두 차단합니다. checksum을 확인하고 PostgreSQL
dump를 단일 transaction으로 복원한 뒤 public schema의 모든 테이블 행 수와
파일 데이터를 검증합니다.

1. PR의 호스트 빌드 세 개가 통과하면 검토한 system closure를 대상 호스트에
   미리 빌드합니다. 아직 활성화하지 않습니다.
2. 점검 시간을 정하고 alfheim에서 jamye-plz의 cold archive를 만든 다음,
   midgard에서 jamye-server를 snapshot합니다.

   ```bash
   ssh alfheim sudo bash -s -- jamye-plz < scripts/jamye-host-swap-snapshot.sh
   ssh midgard sudo bash -s -- jamye-server < scripts/jamye-host-swap-snapshot.sh
   ```

   두 source stack은 중지 상태로 남습니다. root 전용 snapshot은
   `/var/lib/jamye-host-swap/2026-10-11/<app>`에 저장합니다. 기존 snapshot이나
   일부만 만들어진 snapshot은 덮어쓰지 않습니다.
3. jamye-server snapshot을 alfheim의 같은 경로로 복사합니다. 별도 호스트에
   복구본을 남기기 위해 jamye-plz archive는 midgard로 복사하고 둘 다 검증합니다.

   ```bash
   ssh midgard sudo tar -C /var/lib/jamye-host-swap/2026-10-11 -cf - jamye-server \
     | ssh alfheim sudo tar -C /var/lib/jamye-host-swap/2026-10-11 -xf -
   ssh alfheim sudo tar -C /var/lib/jamye-host-swap/2026-10-11 -cf - jamye-plz \
     | ssh midgard sudo tar -C /var/lib/jamye-host-swap/2026-10-11 -xf -
   ssh alfheim "sudo sh -c 'cd /var/lib/jamye-host-swap/2026-10-11/jamye-server && sha256sum --check --quiet SHA256SUMS && test -f SNAPSHOT_COMPLETE'"
   ssh midgard "sudo sh -c 'cd /var/lib/jamye-host-swap/2026-10-11/jamye-plz && sha256sum --check --quiet SHA256SUMS && test -f SNAPSHOT_COMPLETE'"
   ```

4. 검토한 PR을 병합하고 GitHub Actions CD로 모든 호스트를 활성화합니다.
   alfheim은 jamye-server를 시작하기 전에 자동 복원합니다. jamye-plz archive는
   어떤 자동 복원도 사용하지 않습니다.
5. alfheim의 `RESTORE_COMPLETE`, 배포 job, 서비스 상태, API와 media 경로,
   기존 계정의 인증 동작을 확인합니다. `jamye-plz.ridewithmin.com`과
   `minio.ridewithmin.com`이 HTTP `503`을 반환하는지도 확인합니다.

jamye-server 원본 데이터는 midgard에 남습니다. 비활성 jamye-plz PostgreSQL
18 cluster, `/var/lib/minio/data`, Redis와 애플리케이션 상태는 alfheim에
보존하고, midgard의 검증된 archive를 별도 복구본으로 유지합니다.
jamye-server MinIO는 `/var/lib/jamye-server-minio/data`에 복원하므로 보존한
jamye-plz object를 덮어쓰지 않습니다.

배포 전 staging에 실패하면 snapshot을 확인한 뒤 source stack을 재개합니다.
복원에 실패하면 jamye-server unit은 중지 상태를 유지합니다.
`journalctl -u jamye-host-swap`과 단계별 완료 파일을 확인합니다. 운영 중인 DB에
복원을 강제하려고 완료 파일을 삭제하지 않습니다. 전환 후 설정만 롤백하면
alfheim의 새 쓰기가 빠집니다. jamye-server를 중지하고 역방향 데이터 이전을
계획한 뒤에만 midgard로 트래픽을 되돌립니다.

## 명시적 수동 경로

`just test`와 `just switch`는 비상/부트스트랩용 명령입니다. 운영자가 로컬
활성화를 명시적으로 요청한 경우에만 실행합니다. 이때도 빌드와 활성화는
**대상 호스트에서** 원격으로 수행됩니다.

```bash
just test <host>     # 부팅 기본값으로 만들지 않고 활성화
just switch <host>   # 활성화 + 부팅 기본값으로 설정
```

호스트: `yggdrasil`, `midgard`, `alfheim`.

내부적으로는 다음과 같이 실행됩니다.

```text
nixos-rebuild <test|switch>
  --no-reexec
  --flake .#<host>
  --build-host <host>
  --target-host <host>
  --sudo
```

!!! tip "수동 test 활성화"
    명시적 수동 경로가 필요한 경우 `just test`는 설정을 부팅 기본값으로
    만들지 않고 활성화합니다. `test`로 활성화한 상태는 재부팅하면
    사라집니다.

## 롤백

호스트에서 직전 세대로 되돌리기:

```bash
sudo nixos-rebuild switch --rollback
```

부팅이 안 되는 수준의 문제라면 systemd-boot 부팅 메뉴에서 이전 세대를
선택합니다.

## 주의사항

- `flake.lock`은 손으로 편집하지 않고 `nix flake update`를 사용합니다.
- `system.stateVersion`은 초기 설치 시점의 기본값 기록입니다. 릴리스 노트가
  명시적으로 요구하지 않는 한 올리지 않습니다.
- 배포는 라이브 호스트를 건드리는 작업입니다. 일반 변경은 CI/CD에 맡기고
  로컬 `just test` / `just switch`는 명시적 요청이 있을 때만 실행합니다.
