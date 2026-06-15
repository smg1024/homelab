---
icon: fontawesome/solid/rocket
---

# 배포와 롤백

모든 변경은 저장소에서 시작합니다. 호스트에서 직접 설정을 고치지 않습니다.

## 배포 전 검증

```bash
nix flake check --no-build
nix flake show --all-systems
```

## 배포

`Justfile`이 표준 배포 진입점입니다. 빌드와 활성화는 **대상 호스트에서**
원격으로 수행됩니다.

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

!!! tip "test 먼저"
    영향이 불확실한 변경은 `just test`로 먼저 활성화해 보고 문제가 없으면
    `just switch`로 부팅 기본값까지 올립니다. `test`로
    활성화한 상태는 재부팅하면 사라집니다.

## 롤백

호스트에서 직전 세대로 되돌리기:

```bash
sudo nixos-rebuild switch --rollback
```

부팅이 안 되는 수준의 문제라면 systemd-boot 부팅 메뉴에서 이전 세대를
선택합니다.

## 주의사항

- `flake.lock`은 손으로 편집하지 않고 `nix flake update`를 사용합니다.
- `system.stateVersion`은 초기 설치 시점의 기본값 기록입니다 — 릴리스 노트가
  명시적으로 요구하지 않는 한 올리지 않습니다.
- 배포는 라이브 호스트를 건드리는 작업이므로 변경 내용을 커밋한 뒤 의도를
  확인하고 실행합니다.
