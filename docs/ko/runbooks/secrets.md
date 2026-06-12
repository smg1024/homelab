---
icon: lucide/key-round
---

# 시크릿 관리

시크릿은 `sops-nix`로 관리합니다. **평문 시크릿을 `.nix` 파일이나 Nix
스토어에 절대 넣지 않습니다.**

## 동작 방식

- 암호화된 파일: `secrets/*.yaml` (현재 `ingress.yaml`, `vaultwarden.yaml` 등)
- 암호화 정책: `.sops.yaml` — `secrets/[^/]+\.yaml` 패턴이 `poby`,
  `yggdrasil`, `midgard` age 수신자로 암호화됩니다.
- 각 호스트는 자신의 SSH 호스트 키(`/etc/ssh/ssh_host_ed25519_key`)를 age
  신원으로 사용해 복호화합니다. 즉 `.sops.yaml`에 등록된 호스트만 시크릿을
  읽을 수 있습니다.
- 활성화/런타임 시 sops-nix가 `/run/secrets` 아래 파일 또는 서비스별
  템플릿으로 시크릿을 구체화하고 owner/group/mode를 적용합니다.

## 새 시크릿 추가

1. 해당 `secrets/*.yaml`을 sops로 열어 편집합니다.

    ```bash
    sops secrets/ingress.yaml
    ```

2. 모듈에서 `sops.secrets."<path>"`로 선언하고 owner/mode와
   `restartUnits`를 지정합니다.

    ```nix
    sops.secrets."myservice/api_token" = {
      owner = "myservice";
      mode = "0400";
      restartUnits = ["myservice.service"];
    };
    ```

3. 서비스에서는 `config.sops.secrets."<path>".path`로 참조하거나
   `sops.templates`로 환경 파일을 렌더링합니다.

## 현재 시크릿 소비자

| 시크릿 | 소비자 | 용도 |
| --- | --- | --- |
| `cloudflare/caddy_env` | Caddy | DNS 챌린지용 Cloudflare API 토큰 |
| `cloudflare/cloudflared_tunnel_credentials` | cloudflared | Tunnel 자격 증명 |
| `grafana/admin_password` | Grafana | 관리자 비밀번호 |
| `vaultwarden/admin_token` | Vaultwarden | 관리자 토큰 (`ADMIN_TOKEN`) |

## 새 호스트를 수신자로 추가

1. 새 호스트의 SSH 호스트 공개 키에서 age 수신자 키를 얻습니다.

    ```bash
    ssh-keyscan -t ed25519 <host> | ssh-to-age
    ```

2. `.sops.yaml`에 수신자를 추가합니다.
3. 기존 시크릿 파일을 재암호화합니다.

    ```bash
    sops updatekeys secrets/<file>.yaml
    ```
