---
icon: fontawesome/solid/server
---

# midgard

실제 애플리케이션 호스트입니다. 외부 트래픽은 yggdrasil의 Caddy가 tailnet의
`midgard.tail6fc192.ts.net`으로 전달합니다. midgard의 서비스 포트는 공개
방화벽에서 열지 않습니다.

## 책임

- Homepage 대시보드 운영
- Dev with Min 정적 블로그 운영
- 홈랩 문서 정적 사이트 운영
- Forgejo (Git 호스팅) 운영
- Vaultwarden (비밀번호 관리자) 운영
- 컨테이너화된 앱을 위한 Podman 런타임 제공

## 로드하는 모듈

```text
services/blog-site.nix
services/docs-site.nix
services/homepage.nix
services/forgejo.nix
services/vaultwarden.nix
modules/podman.nix      # 호스트 전용 모듈
```

## 서비스 포트

| 포트 | 서비스 | 공개 URL |
| --- | --- | --- |
| `8082` | Homepage | `https://home.ridewithmin.com` |
| `8083` | Dev with Min 블로그 | `https://blog.ridewithmin.com` |
| `8084` | 홈랩 문서 사이트 | `https://docs.ridewithmin.com` |
| `3000` | Forgejo | `https://git.ridewithmin.com` |
| `8222` | Vaultwarden | `https://vault.ridewithmin.com` |
| `9429` | vlagent | 공개 미노출 (신뢰 인터페이스 경유 tailnet 도달 가능); journald 로그를 VictoriaLogs로 버퍼링 전송 |
| `45876` | beszel-agent | 미개방 (에이전트가 tailnet으로 Beszel 허브에 먼저 접속) |

## 컨테이너 런타임

Podman은 midgard에만 활성화됩니다 (`modules/podman.nix`).

- `virtualisation.oci-containers.backend = "podman"`
- 주간 자동 prune (`podman-prune.timer`)
- 레지스트리 검색 경로: `docker.io`, `ghcr.io`로 제한
- 이미지 태그는 **반드시 고정**, `latest` 금지

장기 실행 컨테이너 서비스는 ad-hoc compose 명령 대신
`virtualisation.oci-containers.containers`로 선언합니다.
`podman-compose`는 임시 테스트와 수동 운영 용도로만 유지합니다.

## Hermes Agent

Hermes Agent는 시스템 서비스가 아니라 `poby`의 Home Manager 환경
(`home/poby/hermes-agent.nix`)으로 설치됩니다. 런타임 상태와 자격 증명은
`/home/poby/.hermes` 아래에 변경 가능한 상태로 둡니다. 구성이 안정화되면
선언적 Nix 구성으로 승격할 예정입니다.
