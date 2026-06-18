---
icon: fontawesome/solid/cubes
---

# 애플리케이션

애플리케이션 서비스는 호스트별 역할에 맞춰 실행됩니다. 기존 앱 대부분은
`midgard`에 있고 jamye-plz는 `alfheim`에서 실행됩니다. yggdrasil의 Caddy가
공개 트래픽을 tailnet으로 전달합니다.

## Homepage (`services/homepage.nix`)

홈랩 대시보드. `:8082`에서 실행되며 `https://home.ridewithmin.com`으로
노출됩니다.

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

지인 폐쇄 그룹용 소셜 PWA. `alfheim`의 `:8080`에서 실행되며
`https://jamye-plz.ridewithmin.com`으로 노출됩니다.

- upstream `jamye-plz` flake input에서 가져옵니다.
- upstream `services.jamye-plz` NixOS 모듈로 활성화합니다.
- alfheim의 로컬 PostgreSQL과 Caddy는 upstream 모듈이 관리합니다.
- OAuth/JWT 비밀은 `secrets/jamye-plz.yaml`에 있고 `sops.templates`로
  `jamye-plz.env`를 렌더링합니다.
- 공개 트래픽 경로: yggdrasil의 Cloudflare Tunnel → yggdrasil의 Caddy →
  `alfheim.tail6fc192.ts.net:8080`

## 새 앱 추가 가이드라인

- 업스트림이 NixOS 모듈을 제공한다면 그 방식을 우선합니다. OCI 컨테이너는
  Podman을 의도적으로 활성화한 호스트에서, 업스트림이 컨테이너로 더 잘
  배포될 때만 사용합니다.
- 이미지 태그는 반드시 고정하고 `latest`는 금지합니다.
- 새 공유 서비스는 `services/` 아래 모듈로 추가하고 `flake.nix`(공유) 또는
  `hosts/<host>/default.nix`(호스트 전용)에 연결합니다.
- 내부 서비스 포트는 방화벽에서 열지 않습니다. 노출이 필요하면
  [인그레스 절차](ingress.md#expose-a-service)를 따릅니다.
