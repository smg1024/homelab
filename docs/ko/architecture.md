---
icon: fontawesome/solid/network-wired
---

# 아키텍처

구성은 엣지/인프라 노드(`yggdrasil`), 주 애플리케이션 노드(`midgard`),
클라우드 ARM 애플리케이션 노드(`alfheim`)로 나뉩니다. 외부 트래픽은 포트를
직접 열지 않고 Cloudflare Tunnel → Caddy 경로로만 들어오며, 호스트 간 내부
통신은 Tailscale tailnet을 경계로 삼습니다.

```mermaid
flowchart TD
    internet["인터넷 사용자"]
    cloudflare["Cloudflare<br/>DNS / Tunnel 엣지"]

    subgraph yggdrasil["yggdrasil: 엣지 / 인프라 노드"]
        cloudflared["cloudflared<br/>Cloudflare Tunnel 클라이언트"]
        caddy["Caddy<br/>HTTPS 인그레스 / 리버스 프록시"]
        kuma["Uptime Kuma<br/>127.0.0.1:3001"]
        beszelHub["Beszel 허브<br/>:8090"]
        vlogs["VictoriaLogs<br/>:9428"]
        yShipper["beszel-agent / vlagent"]
    end

    subgraph tailnet["Tailscale tailnet"]
        midgardDns["midgard.tail6fc192.ts.net"]
        alfheimDns["alfheim.tail6fc192.ts.net"]

        subgraph midgard["midgard: 애플리케이션 호스트"]
            homepage["Homepage 대시보드<br/>:8082"]
            blog["Dev with Min 블로그<br/>:8083"]
            docsSite["문서 사이트<br/>:8084"]
            forgejo["Forgejo<br/>:3000"]
            vaultwarden["Vaultwarden<br/>:8222"]
            mShipper["beszel-agent / vlagent"]
        end

        subgraph alfheim["alfheim: OCI ARM 애플리케이션 호스트"]
            jamyePlz["jamye-plz<br/>:8080"]
            aShipper["beszel-agent / vlagent"]
        end
    end

    internet --> cloudflare
    cloudflare --> cloudflared
    cloudflared -->|"home/blog/git/vault/jamye-plz/status/docs.ridewithmin.com<br/>https://localhost:443"| caddy

    caddy -->|"status.ridewithmin.com"| kuma
    caddy -->|"home.ridewithmin.com"| homepage
    caddy -->|"blog.ridewithmin.com"| blog
    caddy -->|"git.ridewithmin.com"| forgejo
    caddy -->|"vault.ridewithmin.com"| vaultwarden
    caddy -->|"jamye-plz.ridewithmin.com"| jamyePlz
    caddy -->|"beszel.ridewithmin.com<br/>tailnet 전용"| beszelHub
    caddy -->|"logs.ridewithmin.com<br/>tailnet 전용"| vlogs
    caddy -->|"docs.ridewithmin.com"| docsSite

    caddy -.->|Tailscale 경유 백엔드 접근| midgardDns
    caddy -.->|Tailscale 경유 백엔드 접근| alfheimDns
    midgardDns -.-> homepage
    midgardDns -.-> blog
    midgardDns -.-> docsSite
    midgardDns -.-> forgejo
    midgardDns -.-> vaultwarden
    alfheimDns -.-> jamyePlz

    yShipper --> beszelHub
    yShipper --> vlogs
    mShipper -.->|"메트릭 WebSocket + journald 로그<br/>Tailscale 경유"| beszelHub
    mShipper -.-> vlogs
    aShipper -.->|"메트릭 WebSocket + journald 로그<br/>Tailscale 경유"| beszelHub
    aShipper -.-> vlogs
```

이 경계들(공개 인터넷, tailnet, localhost)을 누가 넘는지는
[보안 모델](security.md)에서 다룹니다.

## 공유 시스템 구성

모든 호스트는 `flake.nix`에서 공통 모듈을 로드합니다.

| 모듈 | 내용 |
| --- | --- |
| `modules/base.nix` | flakes/`nix-command`, systemd-boot, NetworkManager, 방화벽 |
| `modules/gc.nix` | 주간 Nix GC + 스토어 자동 최적화 |
| `modules/swap.nix` | zram 스왑 (별도 스왑 파티션 없음) |
| `modules/users.nix` | 운영자 `poby` (`wheel`, passwordless sudo) |
| `modules/ssh.nix` | OpenSSH, 패스워드/루트 로그인 비활성 |
| `modules/tailscale.nix` | Tailscale |
| `modules/secrets.nix` | sops-nix 기본 설정 |
| `services/log-shipper.nix` | 모든 호스트의 journald → VictoriaLogs 전송 (journal-upload + vlagent) |
| `services/beszel/agent.nix` | 모든 호스트의 Beszel 메트릭 에이전트 |

## 스토리지

디스크 레이아웃은 `disko`로 선언하며 모든 호스트가 단일 디스크 GPT
레이아웃을 사용합니다.

```text
GPT 파티션 테이블
512M EFI 시스템 파티션  -> /boot, vfat
나머지 디스크           -> /, ext4
```

## 사용자 환경

Home Manager는 NixOS 모듈로 활성화되어 호스트 switch 시 함께 적용되며
`poby` 운영자 환경 전용입니다. 장기 실행 서비스에는 사용하지 않습니다.
공유 프로필(`home/poby/base.nix`, `ops.nix`)에는 셸/Git/tmux 설정과
`age`·`sops`·`just` 같은 운영 도구가 들어가고, 호스트별 프로필이 각 호스트에
맞는 별칭을 더합니다.
