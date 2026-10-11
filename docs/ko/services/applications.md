---
icon: fontawesome/solid/cubes
---

# 애플리케이션

애플리케이션 서비스는 호스트별 역할에 맞춰 실행됩니다. 기존 앱 대부분은
`midgard`에 있고 jamye-server는 `alfheim`에서 실행됩니다. yggdrasil의
Caddy가 공개 트래픽을 tailnet으로 전달하고 정적 블로그와 문서 사이트는
직접 서빙합니다. jamye-plz는 현재 비활성화되어 있습니다.

## Homepage (`services/homepage.nix`)

Homepage는 홈랩 대시보드입니다. `:8082`에서 실행되며
`https://home.ridewithmin.com`으로 노출됩니다.

## Dev with Min 블로그 (`services/ingress.nix`)

Dev with Min은 정적 Astro 개인 블로그입니다. `blog` flake input에서 빌드하고
yggdrasil의 Caddy가 `file_server`로 Nix 스토어에서 직접 서빙하며
`https://blog.ridewithmin.com`으로 노출됩니다. 별도 서비스 프로세스가
없습니다.

## 문서 사이트 (`services/ingress.nix`)

홈랩 문서는 정적 사이트입니다. 이 flake의 `docs` 패키지에서 빌드하고
yggdrasil의 Caddy가 `file_server`로 Nix 스토어에서 직접 서빙하며
`https://docs.ridewithmin.com`으로 노출됩니다. 편집 워크플로는
[문서 사이트 런북](../runbooks/docs-site.md)을 참고하세요.

## Forgejo (`services/forgejo.nix`)

Forgejo는 Git 호스팅 서비스입니다. `:3000`에서 실행되며
`https://git.ridewithmin.com`으로 노출됩니다.

- 공개 회원가입 비활성화
- Forgejo SSH 비활성화 (HTTPS로만 push/pull)

## Vaultwarden (`services/vaultwarden.nix`)

Vaultwarden은 Bitwarden 호환 비밀번호 관리자입니다. `:8222`에서 실행되며
`https://vault.ridewithmin.com`으로 노출됩니다.

- SQLite 백엔드
- 공개 가입 비활성화, 초대만 허용
- 관리자 토큰은 `vaultwarden/admin_token` SOPS 비밀에서
  `vaultwarden.env` 템플릿으로 렌더링

## jamye-plz (`services/jamye-plz.nix`)

jamye-plz는 비활성화되어 어떤 호스트에서도 import하지 않습니다. 향후 복구를
위해 소스 모듈, 암호화된 비밀, alfheim의 기존 데이터는 보존합니다.
`jamye-plz.ridewithmin.com`과 `minio.ridewithmin.com`은 서비스 중단 기간에
HTTP `503`을 반환합니다.

## jamye-server (`services/jamye-server.nix`)

Rust API와 worker는 alfheim에서 로컬 PostgreSQL 17, Redis, MinIO와 함께
실행됩니다. upstream `jamye-server` flake가 네이티브 `aarch64-linux` 패키지를 제공합니다.

- API: `https://jamye-api.ridewithmin.com` → `alfheim.tail6fc192.ts.net:8080`
- 미디어: `https://jamye-media.ridewithmin.com` → `alfheim.tail6fc192.ts.net:9000`
- MinIO 데이터: `/var/lib/jamye-server-minio/data`
- 비밀: `secrets/jamye-server.yaml`에서 `sops.templates`로 렌더링

## 새 앱 추가 가이드라인

- 업스트림이 NixOS 모듈을 제공한다면 그 방식을 우선합니다. OCI 컨테이너는
  Podman을 의도적으로 활성화한 호스트에서, 업스트림이 컨테이너로 더 잘
  배포될 때만 사용합니다.
- 이미지 태그는 반드시 고정하고 `latest`는 금지합니다.
- 새 공유 서비스는 `services/` 아래 모듈로 추가하고 `flake.nix`(공유) 또는
  `hosts/<host>/default.nix`(호스트 전용)에 연결합니다.
- 내부 서비스 포트는 방화벽에서 열지 않습니다. 노출이 필요하면
  [인그레스 절차](ingress.md#expose-a-service)를 따릅니다.
