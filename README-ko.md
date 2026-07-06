# Homelab

[English](README.md) | 한국어

이 저장소는 NixOS homelab의 단일 진실 공급원입니다. 호스트 설정, 공통 모듈,
서비스, 운영자 환경, 암호화된 비밀을 하나의 Nix flake로 선언하고 GitHub
Actions로 배포합니다.

## 문서

자세한 내용은 문서 사이트에 있습니다.

- English: <https://docs.ridewithmin.com/>
- 한국어: <https://docs.ridewithmin.com/ko/>

아키텍처, 호스트 runbook, 서비스 설명, 비밀 관리, CI/CD, 롤백, 운영 절차는
문서 사이트를 기준으로 봅니다.

## 개요

이 homelab은 edge/infra 노드, 애플리케이션 호스트, ARM 클라우드 노드로
나뉩니다. 공개 트래픽은 Cloudflare Tunnel을 통해 `yggdrasil`의 Caddy로
들어오고, 내부 backend 트래픽은 Tailscale 위에서 이동합니다. 저장소를 서버처럼
다룹니다. 변경은 이곳에서 만들고 PR로 검토한 뒤 CI/CD로 배포합니다.

## 호스트

| 호스트 | 역할 | 메모 |
| --- | --- | --- |
| `yggdrasil` | Edge / infrastructure | Cloudflare Tunnel, Caddy ingress, monitoring, status page |
| `midgard` | Application host | 정적 사이트, Forgejo, Vaultwarden, Homepage, Podman 기반 애플리케이션 |
| `alfheim` | OCI ARM node | ARM/cloud-host 검증과 `jamye-plz` |

## 아키텍처

`flake.nix`는 NixOS 26.05를 고정하고 호스트별 `nixosConfiguration`을 노출합니다.
공통 시스템 동작은 `modules/`에서 오고, 서비스 정의는 `services/`에 있으며, 각
호스트는 `hosts/<host>/`에서 hardware config와 호스트 전용 모듈을 연결합니다.

외부 사용자는 다음 경로로 공개 서비스에 접근합니다.

```text
Internet -> Cloudflare -> yggdrasil의 cloudflared -> Caddy -> service backend
```

비공개 운영과 호스트 간 통신은 Tailscale tailnet을 사용합니다. 애플리케이션
포트는 공개 인터넷에 직접 열지 않습니다.

## 저장소 구조

| 경로 | 용도 |
| --- | --- |
| `flake.nix` / `flake.lock` | Nix flake 입력과 호스트 출력 |
| `hosts/` | 호스트별 NixOS 설정, hardware config, disk layout |
| `modules/` | 모든 호스트가 공유하는 NixOS 모듈 |
| `services/` | 서비스 모듈과 ingress/monitoring 설정 |
| `home/` | `poby` 운영자 계정용 Home Manager profile |
| `secrets/` | `sops-nix`로 암호화한 비밀 |
| `docs/` | 영어/한국어 문서 사이트 source |

## 변경 흐름

일반 변경은 GitHub Actions workflow를 따릅니다.

```text
edit -> pull request -> CI builds every host -> merge -> CD deploys all nodes
```

로컬 `just test`와 `just switch`는 명시적으로 요청된 비상 또는 부트스트랩 명령이며,
기본 검증이나 배포 경로가 아닙니다.

## 주요 문서

- [아키텍처](https://docs.ridewithmin.com/ko/architecture/)
- [보안 모델](https://docs.ridewithmin.com/ko/security/)
- [호스트](https://docs.ridewithmin.com/ko/hosts/yggdrasil/)
- [서비스](https://docs.ridewithmin.com/ko/services/applications/)
- [CI/CD 파이프라인](https://docs.ridewithmin.com/ko/runbooks/ci-cd/)
- [배포와 롤백](https://docs.ridewithmin.com/ko/runbooks/deploy/)
- [비밀 관리](https://docs.ridewithmin.com/ko/runbooks/secrets/)
