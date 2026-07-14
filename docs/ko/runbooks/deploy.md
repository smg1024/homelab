---
icon: fontawesome/solid/rocket
---

# 배포와 롤백

모든 변경은 저장소에서 시작합니다. 호스트에서 직접 설정을 고치지 않습니다.

## PR 전 검증

GitHub Actions CI가 기준 빌드 체크입니다. PR을 열기 전에 로컬에서 확인하면
빠르게 문제를 잡을 수 있습니다.

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

## 명시적 수동 경로

`just test`와 `just switch`는 비상/부트스트랩용 명령입니다. 운영자가 로컬
활성화를 명시적으로 요청한 경우에만 실행합니다. 이때도 빌드와 활성화는
**대상 호스트에서** 원격으로 수행됩니다.

저장소의 개발 셸에서 실행하세요. 이 셸은 배포 도구(`just`, `nh`)를 고정하므로
아무것도 설치하지 않고도 새 체크아웃에서 바로 동작합니다.

```bash
nix develop          # 배포 셸 진입 (just + nh 제공)
just test <host>     # 부팅 기본값으로 만들지 않고 활성화
just switch <host>   # 활성화 + 부팅 기본값으로 설정
```

호스트: `yggdrasil`, `midgard`, `alfheim`.

내부적으로는 `nh`를 실행합니다. 평가는 워크스테이션에서 이뤄지고, 빌드와
활성화는 대상 호스트에서 원격으로 수행됩니다.

```text
nh os <test|switch> .
  --hostname <host>
  --build-host <host>            # 노드 자체에서 빌드
  --target-host <host>           # 노드 자체에서 활성화
  --elevation-strategy passwordless
  --use-substitutes              # 노드가 캐시에서 직접 가져옴
  --diff always                  # 무엇이 바뀌고 업그레이드됐는지 출력
  --ask                          # switch 전용: 활성화 전 확인
```

`just switch`는 `--ask`를 추가하므로, nh가 패키지 diff를 출력하고 새 세대를
부팅 기본값으로 만들기 전에 확인을 기다립니다. `just test`는 확인 없이
활성화합니다. 무암호 권한 상승은 `wheel`에 `security.sudo.wheelNeedsPassword =
false`가 설정되어 있어 동작합니다.

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
- 배포는 라이브 호스트를 건드리는 작업입니다. 일반 변경은 CI/CD에 맡기고,
  로컬 `just test` / `just switch`는 명시적 요청이 있을 때만 실행합니다.
