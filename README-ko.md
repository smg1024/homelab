# Homelab

[English](README.md) | 한국어

이 repo는 두 대의 NixOS 머신으로 구성된 homelab의 source of truth다. 호스트
설정, 디스크 레이아웃, 공통 시스템 모듈, 서비스, 사용자 설정, 암호화된 secret을
모두 Nix flake 안에서 선언한다.

## 전체 아키텍처

구성은 edge/infra 노드와 application 노드로 나뉜다.

```mermaid
flowchart TD
    internet["Internet users"]
    cloudflare["Cloudflare<br/>DNS / Tunnel edge"]

    subgraph yggdrasil["yggdrasil: edge / infra node"]
        cloudflared["cloudflared<br/>Cloudflare Tunnel client"]
        caddy["Caddy<br/>HTTPS ingress / reverse proxy"]
        kuma["Uptime Kuma<br/>127.0.0.1:3001"]
    end

    subgraph tailnet["Tailscale tailnet"]
        midgardDns["midgard.tail6fc192.ts.net"]

        subgraph midgard["midgard: application host"]
            homepage["Homepage dashboard<br/>:8082"]
            forgejo["Forgejo<br/>:3000"]
            vaultwarden["Vaultwarden<br/>:8222"]
        end
    end

    internet --> cloudflare
    cloudflare --> cloudflared
    cloudflared -->|"home/git/vault/status.ridewithmin.com<br/>https://localhost:443"| caddy

    caddy -->|"status.ridewithmin.com"| kuma
    caddy -->|"home.ridewithmin.com"| homepage
    caddy -->|"git.ridewithmin.com"| forgejo
    caddy -->|"vault.ridewithmin.com"| vaultwarden

    caddy -.->|backend access over Tailscale| midgardDns
    midgardDns -.-> homepage
    midgardDns -.-> forgejo
    midgardDns -.-> vaultwarden
```

`flake.nix`는 NixOS 25.11을 pinning하고, 두 NixOS configuration을 노출한다.

- `yggdrasil`
- `midgard`

공통 시스템 설정은 `modules/`에서 로드되고, 각 호스트는
`hosts/<host>/default.nix`에서 하드웨어, 디스크, 서비스 모듈을 추가로
import한다.

## 호스트 역할

### yggdrasil

`yggdrasil`은 외부 진입점이자 경량 인프라 노드다.

주요 역할:

- Cloudflare Tunnel 유지
- Caddy reverse proxy 운영
- 공개 도메인을 내부 서비스로 라우팅
- Uptime Kuma 상태 페이지 제공

로드하는 서비스:

- `services/ingress.nix`
- `services/cloudflared.nix`
- `services/uptime-kuma.nix`

### midgard

`midgard`는 실제 application host다.

주요 역할:

- Homelab dashboard 운영
- Forgejo 운영
- Vaultwarden 운영
- 향후 container 기반 application service를 위한 Podman runtime 제공

로드하는 서비스:

- `services/homepage.nix`
- `services/forgejo.nix`
- `services/vaultwarden.nix`

로드하는 호스트 전용 모듈:

- `modules/podman.nix`

## 공통 시스템 설정

모든 호스트는 `flake.nix`를 통해 같은 공통 모듈을 공유한다.

- `modules/base.nix`
- `modules/gc.nix`
- `modules/swap.nix`
- `modules/users.nix`
- `modules/ssh.nix`
- `modules/tailscale.nix`
- `modules/secrets.nix`

공통 baseline:

- Nix flakes와 `nix-command` 활성화
- systemd-boot 사용
- NetworkManager 사용
- NixOS firewall 활성화
- OpenSSH 활성화
- SSH password login 비활성화
- SSH root login 비활성화
- Tailscale 활성화
- zram swap 활성화
- weekly Nix garbage collection
- automatic Nix store optimisation

관리 사용자는 `poby`다. `poby`는 `wheel`, `networkmanager` 그룹에 속하고,
`wheel`에는 passwordless sudo가 허용된다.

## 사용자 환경

Home Manager는 NixOS module로 활성화되어 있고, 각 호스트의 switch 과정에 함께
적용된다. 용도는 장기 실행 application service가 아니라 `poby` 운영자 계정의
환경 관리다.

공통 Home Manager profile:

- `home/poby/base.nix`
  - `home.stateVersion`을 설정한다.
  - 기본 Bash, Git, tmux 설정을 관리한다.
  - 공통 editor와 pager 환경 변수를 설정한다.

- `home/poby/ops.nix`
  - `age`, `sops`, `just` 같은 운영자 전용 도구를 설치한다.
  - `journalctl`, `systemctl`, Tailscale 관련 공통 운영 alias를 정의한다.

호스트별 Home Manager profile:

- `home/poby/yggdrasil.nix`
  - Caddy, Cloudflare Tunnel, Uptime Kuma 확인을 위한 ingress 중심 alias를
    추가한다.

- `home/poby/midgard.nix`
  - Forgejo, Homepage, Vaultwarden, Podman 확인을 위한 application host alias를
    추가한다.
  - 운영자 관점의 점검 작업을 위해 `sqlite`를 설치한다.

## 스토리지

디스크 레이아웃은 `disko`로 선언한다.

두 호스트 모두 단일 디스크의 단순한 GPT 레이아웃을 사용한다.

```text
GPT partition table
512M EFI System Partition  -> /boot, vfat
remaining disk             -> /, ext4
```

호스트별 디스크 설정:

- `hosts/yggdrasil/disko.nix`
- `hosts/midgard/disko.nix`

호스트별 hardware configuration:

- `hosts/yggdrasil/hardware-configuration.nix`
- `hosts/midgard/hardware-configuration.nix`

별도 swap partition은 없고, `modules/swap.nix`에서 zram swap을 사용한다.

## 서비스 라우팅

### Cloudflare Tunnel

`cloudflared`는 `yggdrasil`에서 실행된다.

Cloudflare Tunnel은 다음 public hostname을 `yggdrasil`의 local Caddy로 보낸다.

- `home.ridewithmin.com`
- `git.ridewithmin.com`
- `vault.ridewithmin.com`
- `status.ridewithmin.com`

각 hostname은 다음 origin으로 전달된다.

```text
https://localhost:443
```

요청별 `Host` header와 TLS origin server name은 각 public hostname에 맞춰진다.

### Caddy Ingress

Caddy는 `yggdrasil`에서 실행되며, public hostname별로 내부 backend를 선택한다.

```text
home.ridewithmin.com   -> http://midgard.tail6fc192.ts.net:8082
git.ridewithmin.com    -> http://midgard.tail6fc192.ts.net:3000
vault.ridewithmin.com  -> http://midgard.tail6fc192.ts.net:8222
status.ridewithmin.com -> http://127.0.0.1:3001
```

Caddy는 Cloudflare DNS plugin을 사용해 ACME DNS challenge로 인증서를 발급받는다.

`status.ridewithmin.com`은 Uptime Kuma의 status page 관련 path만 proxy하고, 그
외 path는 `404`를 반환한다.

### Application Services

`midgard`에서 실행되는 application service:

- Homepage dashboard: `8082`
- Forgejo: `3000`
- Vaultwarden: `8222`

공개 URL:

- `https://home.ridewithmin.com`
- `https://git.ridewithmin.com`
- `https://vault.ridewithmin.com`

Forgejo는 registration과 Forgejo SSH가 비활성화되어 있다. Vaultwarden은 SQLite를
사용하고, public signup은 비활성화되어 있으며 invitation은 허용되어 있다.

## Container Runtime

Podman은 `modules/podman.nix`를 통해 `midgard`에서만 활성화된다. `yggdrasil`은
Podman 모듈을 import하지 않는다.

현재 Podman 설정:

- `virtualisation.podman.enable = true`
- `virtualisation.oci-containers.backend = "podman"`
- `podman-prune.timer`를 통한 weekly Podman auto-prune
- registry search path는 `docker.io`, `ghcr.io`로 제한
- system profile에 `podman-compose` 설치

`virtualisation.podman.extraPackages`는 의도적으로 비워둔다. `podman-compose`
CLI는 `environment.systemPackages`를 통해 노출하고, Podman wrapper 환경에는
추가하지 않는다. 이렇게 하면 container runtime 설정은 작게 유지하면서도
`midgard`에서 `podman-compose`와 `podman compose`를 모두 사용할 수 있다.

장기 실행 container service는 임의의 compose 명령보다
`virtualisation.oci-containers.containers`로 선언하는 것을 기본 원칙으로 한다.
Compose는 임시 테스트, upstream compose file 확인, 수동 운영 workflow를 위해
사용 가능하게 둔다.

## Secret 관리

Secret은 `sops-nix`로 관리한다.

암호화된 secret 파일:

- `secrets/ingress.yaml`
- `secrets/vaultwarden.yaml`

암호화 정책은 `.sops.yaml`에 있다. `secrets/[^/]+\.yaml`에 매칭되는 파일은 다음
age recipient들로 암호화된다.

- `poby`
- `yggdrasil`
- `midgard`

각 NixOS 호스트는 런타임에 자신의 SSH host key를 SOPS age identity로 사용한다.

```text
/etc/ssh/ssh_host_ed25519_key
```

즉, 호스트의 SSH host private key가 `.sops.yaml`에 등록된 recipient와 맞아야
해당 호스트가 repo의 secret을 복호화할 수 있다.

평문 secret 값은 Nix store에 저장하지 않는다. `sops-nix`가 activation/runtime
시점에 `/run/secrets` 계열의 파일이나 service-specific template로
materialize하고, 각 파일에 owner, group, mode를 적용한다.

현재 secret 사용처:

- `cloudflare/caddy_env`
  - Caddy가 사용한다.
  - Cloudflare DNS challenge용 API token을 담는다.
  - Caddy user/group 소유다.
  - mode는 `0400`이다.

- `cloudflare/cloudflared_tunnel_credentials`
  - `cloudflared`가 사용한다.
  - Cloudflare Tunnel credential을 담는다.
  - mode는 `0400`이다.

- `vaultwarden/admin_token`
  - Vaultwarden admin token이다.
  - `vaultwarden.env` runtime template 안에 `ADMIN_TOKEN`으로 렌더링된다.
  - `vaultwarden:vaultwarden` 소유다.
  - mode는 `0400`이다.

## 외부 접근 통제

외부 인터넷 접근 경로는 직접 포트 노출이 아니라 Cloudflare Tunnel 중심이다.

```mermaid
flowchart LR
    public["Public Internet"]
    cf["Cloudflare<br/>DNS / Tunnel"]

    subgraph edge["yggdrasil"]
        tunnel["cloudflared<br/>outbound tunnel"]
        ingress["Caddy<br/>hostname-based routing"]
        status["Uptime Kuma<br/>localhost:3001"]
    end

    subgraph private["Tailscale tailnet"]
        mdns["midgard.tail6fc192.ts.net"]

        subgraph app["midgard"]
            home["Homepage<br/>:8082"]
            git["Forgejo<br/>:3000"]
            vault["Vaultwarden<br/>:8222"]
        end
    end

    public --> cf
    cf --> tunnel
    tunnel -->|"HTTPS origin<br/>localhost:443"| ingress

    ingress -->|"status.ridewithmin.com<br/>allowed status paths only"| status
    ingress -->|"home.ridewithmin.com"| home
    ingress -->|"git.ridewithmin.com"| git
    ingress -->|"vault.ridewithmin.com"| vault

    ingress -.->|private backend path| mdns
    mdns -.-> home
    mdns -.-> git
    mdns -.-> vault

    blocked["Application ports are not<br/>directly exposed to the public Internet"]
    public -.-> blocked
```

현재 구성에서 NixOS firewall은 모든 호스트에서 활성화되어 있고, 직접 허용되는
TCP 포트는 SSH `22`다. `3000`, `3001`, `8082`, `8222` 같은 application port는
일반 public firewall port로 열지 않는다.

`midgard`의 서비스들은 Caddy가 Tailscale MagicDNS 이름으로 접근한다.

```text
midgard.tail6fc192.ts.net
```

두 호스트 모두 `tailscale0` interface를 trusted interface로 둔다. 따라서
tailnet은 내부 네트워크 경계로 동작한다. public Internet 사용자는 Cloudflare에
연결된 hostname으로만 접근하고, tailnet에 들어온 기기는 Tailscale 정책에 따라
내부 서비스 포트에 더 직접적으로 접근할 수 있다.

이 repo에 선언된 접근 통제 범위:

- public hostname은 Cloudflare Tunnel로만 `yggdrasil`에 들어온다.
- Caddy가 hostname별 backend를 결정한다.
- Uptime Kuma public route는 status page path만 허용한다.
- application port는 일반 인터넷에 직접 열지 않는다.
- tailnet 내부 접근 제어는 이 repo가 아니라 Tailscale ACL과 tailnet 멤버십에
  의존한다.

Cloudflare Access 정책이 있다면 그것은 Cloudflare 쪽 설정이며, 현재 이 repo에는
선언되어 있지 않다.

## 운영

`Justfile`이 일반적인 배포 진입점이다.

새 설정을 boot default로 만들지 않고 적용 테스트:

```bash
just test yggdrasil
just test midgard
```

새 설정을 적용하고 boot default로 설정:

```bash
just switch yggdrasil
just switch midgard
```

내부적으로는 대상 호스트를 build host와 target host로 사용한다.

```text
nixos-rebuild <test|switch>
  --fast
  --flake .#<host>
  --build-host <host>
  --target-host <host>
  --use-remote-sudo
```

워크스테이션에서 명령을 실행하되, Linux system closure의 build와 activation은
대상 NixOS 호스트에서 수행하는 모델이다.

## 검증

로컬에서 flake 평가 확인:

```bash
nix flake show --all-systems
nix flake check --no-build
```

각 호스트에서 기본 상태 확인:

```bash
hostname
systemctl is-active sshd
systemctl is-active tailscaled
tailscale status
zramctl
df -h
bootctl status
```
