---
icon: fontawesome/solid/server
---

# alfheim

Oracle Cloud Infrastructure ARM VM입니다 (`aarch64-linux`). 홈랩에서 처음으로
클라우드에 둔 애플리케이션 노드이며 jamye-plz를 실행합니다.

## 책임

- 실제 서비스를 올린 상태에서 OCI 위의 NixOS 동작 검증
- upstream flake module로 jamye-plz full-stack PWA 실행
- 공유 운영자 베이스라인을 갖춘 소형 원격 노드 제공

공개 트래픽은 여전히 yggdrasil로만 들어옵니다. yggdrasil의 Caddy가
`jamye-plz.ridewithmin.com`을 tailnet의
`alfheim.tail6fc192.ts.net:8080`으로 프록시합니다.

## 호스트 전용으로 로드하는 모듈

```text
modules/podman.nix
services/jamye-plz.nix
```

## 서비스 포트

| 포트 | 서비스 | 공개 URL |
| --- | --- | --- |
| `8080` | jamye-plz full-stack PWA 엔트리포인트 | `https://jamye-plz.ridewithmin.com` |
| `9429` | vlagent | localhost 전용; journald 로그를 VictoriaLogs로 버퍼링 전송 |
| `45876` | beszel-agent | 미개방 (에이전트가 tailnet으로 Beszel 허브에 먼저 접속) |

## jamye-plz 메모

- 애플리케이션 코드는 `jamye-plz` flake input에서 오며 현재 `flake.lock`에
  고정되어 있습니다.
- `services/jamye-plz.nix`가 upstream NixOS 모듈을 import하고
  `services.jamye-plz`를 활성화합니다.
- upstream 모듈이 frontend, backend API, 로컬 PostgreSQL 데이터베이스,
  alfheim-local Caddy를 함께 실행합니다.
- 비밀은 `secrets/jamye-plz.yaml`에 있고 `sops.templates`로
  `jamye-plz.env`를 렌더링합니다.
- OAuth redirect URI와 `FRONTEND_ORIGIN`은
  `https://jamye-plz.ridewithmin.com`을 사용합니다.

## 접근

SSH는 의도적으로 tailnet으로만 노출됩니다. OCI 공인 주소로는 SSH가
열려 있지 않습니다.

```bash
ssh poby@alfheim.tail6fc192.ts.net
```

!!! note "배포 시 SSH"
    GitHub Actions CD는 저장소의 배포 키 비밀을 사용합니다. 로컬 비상 배포는
    운영자의 SSH 클라이언트 설정에 의존합니다. `just`와 `nixos-rebuild`는 호스트
    이름(`alfheim`)을 그대로 넘기고, `~/.ssh/config`의 alias가 이를
    `alfheim.tail6fc192.ts.net`과 알맞은 키로 연결합니다. 다른 호스트도 같은
    방식으로 접근합니다. `Justfile` 자체는 SSH 키나 호스트 이름을 지정하지
    않습니다.

## 점검

애플리케이션 systemd unit 이름은 `jamye-plz-backend`지만, 공개 서비스는
Caddy가 제공하는 full PWA이며 로컬 PostgreSQL 데이터베이스를 함께
사용합니다.

```bash
systemctl is-active jamye-plz-backend caddy postgresql
journalctl -u jamye-plz-backend -f
curl -fsS https://jamye-plz.ridewithmin.com/
```
