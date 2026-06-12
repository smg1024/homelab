---
icon: lucide/layout-grid
---

# 애플리케이션

애플리케이션 서비스는 모두 `midgard`에서 실행되며, yggdrasil의 Caddy가
tailnet을 통해 트래픽을 전달합니다.

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
- 관리자 토큰은 `vaultwarden/admin_token` SOPS 시크릿에서
  `vaultwarden.env` 템플릿으로 렌더링

## 새 앱 추가 가이드라인

- 업스트림이 컨테이너로 더 잘 패키징되어 있으면 **OCI 컨테이너**(Podman,
  midgard 전용), 그렇지 않으면 **NixOS 모듈**을 우선합니다.
- 이미지 태그는 반드시 고정합니다 — `latest` 금지.
- 새 공유 서비스는 `services/` 아래 모듈로 추가하고, `flake.nix`(공유) 또는
  `hosts/<host>/default.nix`(호스트 전용)에 연결합니다.
- 내부 서비스 포트는 방화벽에서 열지 않습니다. 노출이 필요하면
  [인그레스 절차](ingress.md#expose-a-service)를 따릅니다.
