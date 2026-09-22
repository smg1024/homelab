---
icon: fontawesome/solid/server
---

# alfheim

Oracle Cloud Infrastructure ARM VM입니다 (`aarch64-linux`). 홈랩에서 처음으로
클라우드에 둔 애플리케이션 노드이며 jamye-server를 실행합니다.

## 책임

- 실제 서비스를 올린 상태에서 OCI 위의 NixOS 동작 검증
- upstream flake module로 jamye-server Rust API와 worker 실행
- 공유 운영자 베이스라인을 갖춘 소형 원격 노드 제공

공개 트래픽은 여전히 yggdrasil로만 들어옵니다. yggdrasil의 Caddy가
`jamye-api.ridewithmin.com`을 tailnet의
`alfheim.tail6fc192.ts.net:8080`으로 프록시합니다.

## 호스트 전용으로 로드하는 모듈

```text
modules/podman.nix
services/jamye-server.nix
services/jamye-host-swap.nix  # 완료 표시 파일로 재실행을 막는 일회성 데이터 복원
```

## 서비스 포트

| 포트 | 서비스 | 공개 URL |
| --- | --- | --- |
| `8080` | jamye-server API | `https://jamye-api.ridewithmin.com` |
| `9000` | jamye-server MinIO | `https://jamye-media.ridewithmin.com` |
| `9429` | vlagent | 공개 미노출 (신뢰 인터페이스 경유 tailnet 도달 가능); journald 로그를 VictoriaLogs로 버퍼링 전송 |
| `45876` | beszel-agent | 미개방 (에이전트가 tailnet으로 Beszel 허브에 먼저 접속) |

## jamye-server 메모

- 애플리케이션 코드는 `jamye-server` flake input에서 오며 현재 `flake.lock`에
  고정되어 있습니다.
- `services/jamye-server.nix`가 upstream NixOS 모듈을 import하고
  `services.jamye-server`를 활성화합니다.
- upstream 모듈이 API, worker, 로컬 PostgreSQL 17, Redis, MinIO를 실행합니다.
- 비밀은 `secrets/jamye-server.yaml`에 있고 `sops.templates`로 렌더링합니다.
- OAuth callback과 token issuer는 `https://jamye-api.ridewithmin.com`을 사용합니다.
- MinIO는 `/var/lib/jamye-server-minio/data`를 사용하며 공개 미디어 URL은
  `https://jamye-media.ridewithmin.com`을 유지합니다.

## 접근

SSH는 의도적으로 tailnet으로만 노출됩니다. OCI 공인 주소로는 SSH가
열려 있지 않습니다.

```bash
ssh poby@alfheim.tail6fc192.ts.net
```

!!! note "배포 시 SSH"
    GitHub Actions CD는 저장소의 배포 키 비밀을 사용합니다. 로컬 비상 배포는
    운영자의 SSH 클라이언트 설정에 의존합니다. `just`와 `nixos-rebuild`는 호스트
    이름(`alfheim`)을 그대로 넘기고 `~/.ssh/config`의 alias가 이를
    `alfheim.tail6fc192.ts.net`과 알맞은 키로 연결합니다. 다른 호스트도 같은
    방식으로 접근합니다. `Justfile` 자체는 SSH 키나 호스트 이름을 지정하지
    않습니다.

## 점검

`jamye-server-api`와 `jamye-server-worker` systemd unit이 애플리케이션을 실행합니다.

```bash
systemctl is-active jamye-server-api jamye-server-worker postgresql minio
journalctl -u jamye-server-api -f
```
