---
icon: fontawesome/solid/cubes
---

# 애플리케이션

애플리케이션 서비스는 호스트별 역할에 맞춰 실행됩니다. 기존 앱 대부분은
`midgard`에 있고 jamye-plz는 `alfheim`에서 실행됩니다. yggdrasil의 Caddy가
공개 트래픽을 tailnet으로 전달하고, 정적 블로그와 문서 사이트는 직접
서빙합니다.

## Homepage (`services/homepage.nix`)

홈랩 대시보드. `:8082`에서 실행되며 `https://home.ridewithmin.com`으로
노출됩니다.

## Dev with Min 블로그 (`services/ingress.nix`)

정적 Astro 개인 블로그. `blog` flake input에서 빌드하고 yggdrasil의 Caddy가
`file_server`로 Nix 스토어에서 직접 서빙하며
`https://blog.ridewithmin.com`으로 노출됩니다. 별도 서비스 프로세스가
없습니다.

## 문서 사이트 (`services/ingress.nix`)

정적 홈랩 문서 사이트. 이 flake의 `docs` 패키지에서 빌드하고 yggdrasil의
Caddy가 `file_server`로 Nix 스토어에서 직접 서빙하며
`https://docs.ridewithmin.com`으로 노출됩니다. 편집 워크플로는
[문서 사이트 런북](../runbooks/docs-site.md)을 참고하세요.

## Forgejo (`services/forgejo.nix`)

Git 호스팅. `:3000`에서 실행되며 `https://git.ridewithmin.com`으로
노출됩니다.

- 공개 회원가입 비활성화
- Forgejo SSH 비활성화 (HTTPS로만 push/pull)

## Vaultwarden (`services/vaultwarden.nix`)

Bitwarden 호환 비밀번호 관리자. `:8222`에서 실행되며
`https://vault.ridewithmin.com`으로 노출됩니다.

- SQLite 백엔드
- 공개 가입 비활성화, 초대만 허용
- 관리자 토큰은 `vaultwarden/admin_token` SOPS 비밀에서
  `vaultwarden.env` 템플릿으로 렌더링

## jamye-plz (`services/jamye-plz.nix`)

지인 폐쇄 그룹용 full-stack 소셜 PWA. `alfheim`의 `:8080`에서 실행되며
`https://jamye-plz.ridewithmin.com`으로 노출됩니다.

- upstream `jamye-plz` flake input에서 가져옵니다.
- upstream `services.jamye-plz` NixOS 모듈로 활성화합니다.
- upstream 모듈이 frontend, backend API, 로컬 PostgreSQL 데이터베이스,
  alfheim-local Caddy를 관리합니다.
- OAuth/JWT 비밀은 `secrets/jamye-plz.yaml`에 있고 `sops.templates`로
  `jamye-plz.env`를 렌더링합니다.
- 공개 트래픽 경로: yggdrasil의 Cloudflare Tunnel → yggdrasil의 Caddy →
  `alfheim.tail6fc192.ts.net:8080`의 full-stack 서비스 엔트리포인트

## 새 앱 추가 가이드라인

- 업스트림이 NixOS 모듈을 제공한다면 그 방식을 우선합니다. OCI 컨테이너는
  Podman을 의도적으로 활성화한 호스트에서, 업스트림이 컨테이너로 더 잘
  배포될 때만 사용합니다.
- 이미지 태그는 반드시 고정하고 `latest`는 금지합니다.
- 새 공유 서비스는 `services/` 아래 모듈로 추가하고 `flake.nix`(공유) 또는
  `hosts/<host>/default.nix`(호스트 전용)에 연결합니다.
- 내부 서비스 포트는 방화벽에서 열지 않습니다. 노출이 필요하면
  [인그레스 절차](ingress.md#expose-a-service)를 따릅니다.
