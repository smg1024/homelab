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

## Jamye 호스트 교환 (2026년 9월)

jamye-plz를 midgard로, jamye-server를 alfheim으로 옮깁니다. PostgreSQL은
jamye-plz의 18과 jamye-server의 17을 유지합니다. 공개 URL과 비밀은 유지하고
Caddy의 백엔드 주소 네 개를 변경합니다.

**대상 호스트 두 곳에 스냅샷을 모두 준비하기 전에는 호스트 교환 PR을 병합하지 않습니다.**
`jamye-host-swap` unit은 스냅샷 없이 앱을 시작하지 않습니다. PostgreSQL 논리
덤프를 복원하고 public schema의 모든 테이블 행 수를 비교한 뒤 MinIO, 앱 상태,
Redis를 복원해야 앱이 시작됩니다.

1. PR의 호스트 빌드 세 개가 통과하면 검토한 system closure를 대상 호스트에
   미리 빌드합니다. 아직 활성화하지 않습니다.
2. 점검 시간을 정한 뒤 기존 호스트에서 저장소의 스냅샷 스크립트를 root로
   실행합니다. 운영자의 SSH alias를 사용합니다.

   ```bash
   ssh alfheim sudo bash -s -- jamye-plz < scripts/jamye-host-swap-snapshot.sh
   ssh midgard sudo bash -s -- jamye-server < scripts/jamye-host-swap-snapshot.sh
   ```

   스크립트는 앱과 스토리지 서비스를 중지한 상태로 둡니다. 스냅샷은 root만
   접근하는 `/var/lib/jamye-host-swap/2026-09-17/<app>`에 저장합니다.
   기존 스냅샷이나 실패한 스냅샷을 덮어쓰지 않으므로 상태를 먼저 확인합니다.
3. 완성한 스냅샷 디렉토리를 SSH로 반대 호스트의 같은 경로에 복사합니다.
   root 전용 권한을 유지하고 양쪽 대상에서 `SHA256SUMS`와
   `SNAPSHOT_COMPLETE`를 확인합니다.
4. 검토한 PR을 병합하고 GitHub Actions CD로 모든 호스트를 활성화합니다.
5. 양쪽의 `RESTORE_COMPLETE`, 서비스 상태, 공개 경로 네 개를 확인합니다.
   기존 계정으로 인증 후 채팅과 미디어 동작을 확인합니다.

원본 PostgreSQL cluster와 `/var/lib/minio/data`는 기존 호스트에 남겨둡니다.
새 MinIO 경로는 midgard의 `/var/lib/jamye-plz-minio/data`와 alfheim의
`/var/lib/jamye-server-minio/data`입니다. 음성 전사 모델 캐시는 alfheim에
남으며 midgard는 첫 사용 시 다시 다운로드합니다.

배포 전 복사가 실패하면 스냅샷을 확인한 뒤 원래 서비스를 재개합니다. 복원이
실패하면 의존 서비스는 중지 상태를 유지합니다. `journalctl -u jamye-host-swap`과
단계별 완료 파일을 확인합니다. 운영 중인 DB에 복원을 강제하려고 완료 파일을
삭제하지 않습니다. 전환 후에는 새 쓰기가 있으므로 설정만 롤백해서는 안 됩니다.
앱을 중지하고 데이터를 역방향으로 옮길 계획을 세운 후 트래픽을 되돌립니다.

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
