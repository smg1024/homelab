---
icon: fontawesome/solid/shield-halved
---

# 보안 모델

누가 무엇에 접근할 수 있고, 왜 그런지. 모델은 동심원 세 겹입니다 — 공개
인터넷, tailnet, localhost.

## 접근 계층

| 계층 | 누가 | 닿을 수 있는 것 |
| --- | --- | --- |
| **공개 인터넷** | 누구나 | Cloudflare Tunnel로 라우팅된 호스트네임만: `home`, `git`, `vault`, `status` |
| **tailnet** | Tailscale tailnet에 속한 기기 | 위 전부 + `grafana`/`docs` 라우트 + Tailscale ACL에 따른 호스트/포트 직접 접근 |
| **localhost** | 호스트 위의 프로세스 | `127.0.0.1`에 바인딩된 Prometheus, Grafana, Uptime Kuma 백엔드 |

## 인그레스 경로

공개 트래픽은 열린 포트에 닿지 않습니다. `cloudflared`가 Cloudflare로
아웃바운드 터널을 유지하고, 요청은 터널을 타고 로컬
Caddy(`https://localhost:443`)에 도착해 호스트네임별로 라우팅됩니다.
명시적으로 라우팅되지 않은 요청은 전부 `404`입니다.

두 라우트는 의도적으로 터널 호스트네임 목록에 **없고**, Caddy에서
Tailscale 주소 대역(`100.64.0.0/10`, `fd7a:115c:a1e0::/48`)으로
제한됩니다: `grafana.ridewithmin.com`과 `docs.ridewithmin.com`.
tailnet 밖 클라이언트는 `404`를 받습니다.

공개 Uptime Kuma 라우트는 상태 페이지 경로만 허용하고 나머지는 모두
`404`를 반환합니다.

## 방화벽

모든 호스트에서 NixOS 방화벽이 켜져 있습니다. 집 안의 호스트들은 SSH
`22`를 직접 허용하지만, `alfheim`은 신뢰된 `tailscale0` 인터페이스를
통해서만 SSH를 받습니다 — 공개 OCI 주소로는 SSH가 아예 응답하지 않습니다.
애플리케이션/모니터링 포트(`3000`, `3001`, `8082`, `8222`, `9090`,
`9100`, ...)는 공개로 열지 않습니다.

## SSH 정책

- 루트 로그인 전면 비활성화.
- 패스워드 로그인 전면 비활성화 — 키 전용.
- 운영은 `poby` 운영자 계정으로 (`wheel`, passwordless sudo).

## 시크릿 신뢰 모델

각 호스트는 자기 SSH 호스트 키를 age 신원으로 사용해 저장소 시크릿을
복호화합니다. `.sops.yaml`에 수신자로 등록된 호스트(그리고 `poby` 운영자
키)만 읽을 수 있습니다. 평문은 런타임의 `/run/secrets` 아래에만 존재하고,
저장소나 Nix 스토어에는 없습니다. 자세한 내용은
[시크릿 관리](runbooks/secrets.md).

## 이 저장소가 관리하지 않는 것

- **Tailscale ACL** — tailnet 내부 접근 제어는 Tailscale 관리 콘솔에서
  설정하며 여기에 선언되지 않습니다.
- **Cloudflare 쪽 정책** — DNS 레코드와 Cloudflare Access 규칙은
  Cloudflare 대시보드에 있습니다.
