---
icon: fontawesome/solid/house
---

# Homelab

이 사이트는 NixOS 머신들로 구성된 홈랩의 운영 문서입니다. 모든 구성은
[Git 저장소](https://git.ridewithmin.com)의 Nix flake 하나로 선언되며
**저장소가 곧 단일 진실 공급원**입니다. 호스트에서 직접 설정을 고치지 않고
저장소를 수정하고 커밋한 뒤 배포합니다.

## 호스트 한눈에 보기

| 호스트 | 역할 | 아키텍처 | 비고 |
| --- | --- | --- | --- |
| `yggdrasil` | 엣지/인프라 노드 — Cloudflare Tunnel, Caddy, 모니터링 스택 | `x86_64-linux` | 4 GB RAM, 가볍게 유지 |
| `midgard` | 애플리케이션 호스트 — Forgejo, Vaultwarden, Homepage, Podman | `x86_64-linux` | |
| `alfheim` | 실험용 OCI ARM VM | `aarch64-linux` | SSH는 tailnet 전용 |

## 저장소 레이아웃

```text
flake.nix        # nixos-26.05 고정, nixosConfigurations 3개 + docs 패키지
modules/         # 모든 호스트가 공유하는 시스템 모듈
services/        # 서비스 모듈 (ingress, 모니터링, forgejo, ...)
hosts/<host>/    # 호스트별 default.nix + hardware + disko
home/poby/       # poby 운영자용 Home Manager 프로필
secrets/         # sops-nix 암호화 YAML
docs/            # 이 문서 사이트 (Zensical)
```

## 공개 URL

| URL | 서비스 | 접근 범위 |
| --- | --- | --- |
| `https://home.ridewithmin.com` | Homepage 대시보드 | 공개 (Cloudflare Tunnel) |
| `https://git.ridewithmin.com` | Forgejo | 공개 (Cloudflare Tunnel) |
| `https://vault.ridewithmin.com` | Vaultwarden | 공개 (Cloudflare Tunnel) |
| `https://status.ridewithmin.com` | Uptime Kuma 상태 페이지 | 공개 (상태 페이지 경로만) |
| `https://grafana.ridewithmin.com` | Grafana | tailnet 전용 |
| `https://docs.ridewithmin.com` | 이 문서 사이트 | tailnet 전용 |

## 다음으로 읽기

- [설계 원칙](principles.md) — 모든 것이 따르는 규칙
- [아키텍처](architecture.md) — 트래픽 흐름과 구성 요소
- [배포와 롤백](runbooks/deploy.md) — 변경을 호스트에 적용하는 방법
- [로드맵](roadmap.md) — 앞으로의 방향
