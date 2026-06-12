---
icon: fontawesome/solid/server
---

# midgard

실제 애플리케이션 호스트입니다. 외부 트래픽은 yggdrasil의 Caddy가 tailnet을
통해(`midgard.tail6fc192.ts.net`) 전달하며, midgard의 서비스 포트는 공개
방화벽에서 열지 않습니다.

## 책임

- Homepage 대시보드 운영
- Forgejo (Git 호스팅) 운영
- Vaultwarden (비밀번호 관리자) 운영
- 컨테이너화된 앱을 위한 Podman 런타임 제공

## 로드하는 모듈

```text
services/homepage.nix
services/forgejo.nix
services/vaultwarden.nix
modules/podman.nix      # 호스트 전용 모듈
```

## 서비스 포트

| 포트 | 서비스 | 공개 URL |
| --- | --- | --- |
| `8082` | Homepage | `https://home.ridewithmin.com` |
| `3000` | Forgejo | `https://git.ridewithmin.com` |
| `8222` | Vaultwarden | `https://vault.ridewithmin.com` |
| `9100` | node_exporter | — (Prometheus가 tailnet으로 수집) |

## 컨테이너 런타임

Podman은 midgard에만 활성화됩니다 (`modules/podman.nix`).

- `virtualisation.oci-containers.backend = "podman"`
- 주간 자동 prune (`podman-prune.timer`)
- 레지스트리 검색 경로: `docker.io`, `ghcr.io`로 제한
- 이미지 태그는 **반드시 고정** — `latest` 금지

장기 실행 컨테이너 서비스는 ad-hoc compose 명령 대신
`virtualisation.oci-containers.containers`로 선언하는 것이 원칙입니다.
`podman-compose`는 임시 테스트와 수동 운영 용도로만 유지합니다.

## Hermes Agent

Hermes Agent는 시스템 서비스가 아니라 `poby`의 Home Manager 환경
(`home/poby/hermes-agent.nix`)으로 설치됩니다. 런타임 상태와 자격 증명은
`/home/poby/.hermes` 아래에 mutable하게 유지하며, 구성이 안정화되면 선언적
Nix 구성으로 승격할 예정입니다.
