---
icon: fontawesome/solid/robot
---

# CI/CD 파이프라인

GitHub Actions가 모든 변경을 빌드하고, `main`에 반영되면 호스트에 자동으로
배포합니다. 이 경로가 기본 검증과 배포 흐름입니다. [수동 `just`
워크플로](deploy.md)는 명시적 요청이 있을 때 쓰는 비상 수단(break-glass)으로
남습니다. 파이프라인은 같은 `nh os switch`를 무인으로 실행할 뿐입니다.

이렇게 둘로 나눈 데는 이유가 있습니다.

- **CI**는 어떤 호스트도 건드리지 않는 일회용 러너에서 모든 호스트가
  *빌드되는지* 검증합니다.
- **CD**는 tailnet에 합류해 명시적 수동 경로와 같은 `nh os switch`를
  실행해 병합된 변경을 배포합니다.

## 흐름

```text
PR / 푸시 ──▶ CI: 각 호스트의 시스템 클로저 빌드   (빌드만, 호스트는 건드리지 않음)
                 └─ 필수 체크가 병합을 막는 게이트
main에 병합 ──▶ CD: tailnet 합류 → 모든 호스트에서 nh os switch
```

## CI: 빌드 체크

`.github/workflows/ci.yml`, `main`으로 향하는 PR에서 트리거됩니다.

- 호스트마다 하나의 잡이
  `nixosConfigurations.<host>.config.system.build.toplevel`을 빌드합니다.
- **빌드만 합니다**: 활성화도, tailnet 접근도, 비밀도 없습니다. 평가나 컴파일에
  실패하는 설정은 호스트에 닿기 전에 여기서 걸러집니다.
- `yggdrasil`과 `midgard`는 `ubuntu-latest`에서, `alfheim`은 네이티브
  `ubuntu-24.04-arm` 러너에서 빌드합니다. 덕분에 `aarch64` 클로저를
  에뮬레이션 없이 네이티브로 빌드합니다.
- 암호화된 비밀은 필요 없습니다. sops 파일은 스토어에 암호문으로 들어가 그대로
  빌드됩니다 ([비밀 관리](secrets.md) 참고).

세 개의 `build …` 체크를 브랜치 보호에서 **필수**로 지정해 빌드 가능한 설정만
`main`에 도달하도록 합니다.

## CD: 병합 시 배포

`.github/workflows/deploy.yml`, `main`으로의 푸시(병합)에서 트리거됩니다.

각 호스트는 잡 하나가 담당하며, 다음을 수행합니다.

1. Tailscale OAuth 클라이언트로 `tag:ci` 태그가 붙은 **임시(ephemeral)** 노드로
   tailnet에 합류하고, 대상 노드에 연결될 때까지 기다립니다.
2. 배포 키를 불러와 해당 호스트에 대해 실행합니다.

    ```text
    nh os switch .
      --hostname <host>
      --build-host <host>      # 노드 자신
      --target-host <host>     # 노드 자신
      --elevation-strategy passwordless
      -L                       # 빌드 로그를 Actions 로그로 출력
    ```

`--build-host`와 `--target-host`가 모두 해당 노드이므로 **각 호스트가 스스로를
빌드합니다**. 명시적 수동 경로와 같은 방식입니다. 러너는 flake를 평가하고
오케스트레이션만 하므로 아키텍처 교차 빌드 문제가 없고(`alfheim`은 자신의
`aarch64` 클로저를 직접 컴파일) 유지할 바이너리 캐시도 없습니다. `concurrency`
그룹이 배포를 직렬화해 두 병합이 서로 경쟁하지 않습니다.

모든 병합에서 세 호스트가 전부 switch되지만, 영향이 없는 호스트는 같은 세대를
다시 활성화할 뿐이라 금세 끝나는 무동작(no-op)입니다.

## 사전 준비

| 항목 | 위치 | 용도 |
| --- | --- | --- |
| `DEPLOY_SSH_KEY` | GitHub Actions 비밀 | 러너가 `poby`로 SSH 접속할 때 쓰는 개인 키 |
| `TS_OAUTH_CLIENT_ID` / `TS_OAUTH_SECRET` | GitHub Actions 비밀 | 임시 `tag:ci` 노드를 발급하는 Tailscale OAuth 클라이언트 |
| 배포 공개 키 | `modules/users.nix` → `poby` 인증 키 | 모든 호스트에서 러너를 인가 |
| `tag:ci` + ACL | Tailscale 관리 콘솔 | 태그 선언 및 `tag:ci`에 호스트 22번 포트 접근 허용 |

배포 키는 `poby`의 `authorizedKeys`에 추가되는 항목일 뿐이고, `poby`는 이미
비밀번호 없는 `sudo`(`security.sudo.wheelNeedsPassword = false`)를 쓰므로
호스트 쪽 추가 설정은 필요 없습니다.

!!! warning "부트스트랩 순서"
    러너는 호스트가 배포 키를 이미 신뢰할 때에만 로그인할 수 있습니다. 그 키의
    첫 배포에는 명시적인 수동 [`just switch`](deploy.md)가 필요할 수 있습니다.
    그 이후로는 병합이 알아서 배포합니다.

## 일상 운영

1. PR을 엽니다. CI가 세 호스트를 모두 빌드합니다.
2. 체크가 초록색이면 병합합니다. CD가 몇 분 안에 모든 호스트를 switch합니다.
3. 저장소의 Actions 탭에서 실행을 따라가거나 다음으로 확인합니다.

    ```bash
    gh run watch <run-id> --exit-status
    ```

## 주의사항

- **자동 롤백이 없습니다.** 병합 `switch`에는 매직 롤백이 없고, 초록색 CI는
  설정이 *빌드된다*는 뜻이지 *동작한다*는 보장은 아닙니다. 배포 후
  [모니터링 스택](../services/monitoring.md)을 확인하고, 서비스가 이상하면 손으로
  롤백합니다.
- **비상 수단은 명시적으로만 씁니다.** 로컬 `just test` / `just switch`는
  일반 흐름에 포함되지 않습니다. 운영자가 로컬 활성화를 명시적으로 요청한
  경우에만 사용하고, `sudo nixos-rebuild switch --rollback`으로 되돌립니다.
- **변경은 PR로 흐르게 유지합니다.** `main`으로의 직접 푸시는 CI를 건너뜁니다.
  브랜치 보호로 빌드 체크를 강제해 `main`이 배포 가능한 상태를 유지하도록 합니다.
