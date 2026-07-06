---
icon: fontawesome/solid/door-open
---

# 인그레스

외부 트래픽은 직접 노출된 포트 대신 Cloudflare Tunnel을 거쳐
들어옵니다. `cloudflared`와 Caddy 모두 `yggdrasil`에서 실행됩니다.

## Cloudflare Tunnel (`services/cloudflared.nix`)

Tunnel은 다음 공개 호스트네임을 yggdrasil의 로컬 Caddy(`https://localhost:443`)로
보냅니다. 요청의 `Host` 헤더와 TLS 오리진 서버 이름은 각 공개 호스트네임에
맞게 설정됩니다.

- `home.ridewithmin.com`
- `blog.ridewithmin.com`
- `git.ridewithmin.com`
- `vault.ridewithmin.com`
- `jamye-plz.ridewithmin.com`
- `status.ridewithmin.com`
- `docs.ridewithmin.com`

매칭되지 않는 요청은 `http_status:404`로 떨어집니다. Tunnel 자격 증명은
`cloudflare/cloudflared_tunnel_credentials` SOPS 비밀입니다.

## Caddy (`services/ingress.nix`)

Caddy는 공개 호스트네임별로 내부 백엔드를 선택합니다.

| 호스트네임 | 백엔드 | 비고 |
| --- | --- | --- |
| `home.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:8082` | |
| `blog.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:8083` | midgard의 정적 Astro 블로그 |
| `git.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:3000` | |
| `vault.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:8222` | |
| `docs.ridewithmin.com` | `http://midgard.tail6fc192.ts.net:8084` | midgard의 정적 문서 사이트 |
| `jamye-plz.ridewithmin.com` | `http://alfheim.tail6fc192.ts.net:8080` | alfheim의 jamye-plz |
| `status.ridewithmin.com` | `http://127.0.0.1:3001` | 상태 페이지 경로만 허용, 그 외 `404` |
| `grafana.ridewithmin.com` | `http://127.0.0.1:3003` | tailnet 클라이언트만, 그 외 `404` |

인증서는 Caddy의 Cloudflare DNS 플러그인으로 ACME DNS 챌린지를 거쳐
발급합니다. Cloudflare API 토큰은 `cloudflare/caddy_env` SOPS 비밀에서
환경 변수로 주입됩니다.

## tailnet 전용 라우트 패턴

Grafana는 Tunnel 공개 호스트네임 목록에 포함되지 않으며 Caddy에서 Tailscale
주소 대역으로 접근을 제한합니다.

```caddy
@tailnet remote_ip 100.64.0.0/10 fd7a:115c:a1e0::/48

handle @tailnet {
  # ...백엔드...
}

respond 404
```

## 새 서비스 노출 절차 {#expose-a-service}

1. `services/ingress.nix`에 `virtualHosts."<name>.ridewithmin.com"` 추가
2. 공개 서비스라면 `services/cloudflared.nix`의 `ingress`에 같은 호스트네임
   추가 (tailnet 전용이면 생략)
3. Cloudflare DNS에 레코드 추가 (공개: Tunnel CNAME, tailnet 전용:
   yggdrasil의 tailnet 주소). 공개 Tunnel route는 다음 명령으로 등록합니다:

    ```bash
    cloudflared tunnel route dns 7464b4c7-93aa-4ef0-990d-76d6b0bb158a <name>.ridewithmin.com
    ```

4. PR을 열고 CI를 기다린 뒤 병합해 CD가 변경을 배포하게 둡니다.
