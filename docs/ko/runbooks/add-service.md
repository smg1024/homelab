---
icon: fontawesome/solid/circle-plus
---

# 새 서비스 추가

"X를 돌리고 싶다"에서 "X가 배포되어 접근 가능하다"까지의 절차입니다.

## 어디에, 어떻게 돌릴지 결정

먼저 두 가지를 정합니다:

1. **어느 호스트?** 애플리케이션은 애플리케이션 호스트(`midgard` 또는
   `alfheim`)에 둡니다. yggdrasil에는 인그레스/모니터링 인프라만 둡니다
   ([설계 원칙](../principles.md)).
2. **모듈인가 컨테이너인가?**

=== "NixOS 모듈"

    nixpkgs에서 패키지가 잘 유지된다면 이쪽을 우선합니다.
    `services/<name>.nix` 생성:

    ```nix
    {...}: {
      services.<name> = {
        enable = true;
        # localhost 또는 tailnet에서 닿는 포트에 바인딩,
        # 방화벽은 절대 열지 않음
      };
    }
    ```

=== "OCI 컨테이너"

    업스트림이 컨테이너 배포를 더 잘 지원하고 선택한 호스트에 Podman이
    활성화되어 있을 때 사용합니다 (**태그 고정**):

    ```nix
    {...}: {
      virtualisation.oci-containers.containers.<name> = {
        image = "ghcr.io/org/app:1.2.3";  # :latest 금지
        ports = ["127.0.0.1:8090:8080"];
      };
    }
    ```

## 체크리스트

- [ ] `services/<name>.nix`로 모듈 생성
- [ ] 연결: 호스트 전용이면 `hosts/<host>/default.nix`의 imports, 공유면
      `flake.nix` 모듈 목록
- [ ] 비밀이 있다면: sops로 `secrets/*.yaml`에 추가하고
      `sops.secrets."..."` 선언 ([비밀 관리](secrets.md) 참고)
- [ ] 노출이 필요하다면:
    - [ ] `services/ingress.nix`에 Caddy virtualHost 추가
    - [ ] 공개 서비스 → `services/cloudflared.nix` ingress에 호스트네임 추가;
          tailnet 전용 → 대신 `@tailnet` 매처 패턴 사용
    - [ ] Cloudflare에 DNS 레코드 (공개: Tunnel CNAME, tailnet 전용:
          yggdrasil의 tailnet 주소). 공개 Tunnel route는 다음 명령으로 등록:

          ```bash
          cloudflared tunnel route dns <tunnel-id> <name>.ridewithmin.com
          ```
- [ ] 모니터링: 공개 엔드포인트라면 Uptime Kuma 체크 추가
- [ ] 검증: `nix flake check --no-build`
- [ ] 커밋하고 PR 생성
- [ ] CI가 모든 호스트를 빌드할 때까지 대기
- [ ] 초록색이면 병합; CD가 변경을 배포
- [ ] CD 완료 후 서비스 확인

## 검증

```bash
# 호스트에서
systemctl status <name>
curl -fsS http://127.0.0.1:<port>/

# 노출했다면 tailnet 클라이언트에서
curl -fsS https://<name>.ridewithmin.com/
```

## 잘못됐을 때

호스트에서 롤백합니다:

```bash
sudo nixos-rebuild switch --rollback
```

명시적인 수동 `just test` 활성화를 사용했다면, 그 활성화는 재부팅하면
사라집니다.
