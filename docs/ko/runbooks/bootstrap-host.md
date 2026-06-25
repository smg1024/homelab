---
icon: fontawesome/solid/hard-drive
---

# 호스트 부트스트랩

새(또는 죽은) 머신에 이 저장소로 NixOS를 설치하는 절차입니다. installer USB
환경에서 `nixos-anywhere`를 사용합니다. 이 페이지는 generic 호스트 절차입니다.
한 번에 한 호스트씩, 다음 호스트로 넘어가기 전에 검증하세요. 두 머신을 동시에
설치하지 않습니다.

절차 자체는 간단합니다. **최초** 설치는 항상 `nixos-anywhere`로 합니다. 호스트가
접속 가능하고 배포 키를 신뢰하게 된 뒤의 일반 변경은 GitHub Actions CI/CD로
흘립니다. 로컬 `just test` / `just switch`는 명시적인 부트스트랩 또는 비상
요청이 있을 때만 사용합니다.

!!! danger "대상 디스크가 지워집니다"
    `disko`는 지정된 디스크를 재파티션하고 포맷합니다. 설치 전에 디스크 ID를
    반드시 거듭 확인하고, USB installer 자체 디스크를 가리키지 않도록 합니다.

## 준비

- [ ] 대상 머신을 NixOS installer USB로 부팅합니다.
- [ ] 콘솔에서 임시 root 비밀번호를 설정하고 SSH를 시작한 뒤 LAN IP를
      기록합니다. 이 비밀번호는 installer 환경에서만 쓰이며, 설치된 시스템은
      root·패스워드 로그인을 비활성화합니다.

    ```bash
    sudo passwd root
    sudo systemctl start sshd
    ip addr
    ```

- [ ] 워크스테이션에서 올바른 머신에 접속했는지 확인합니다.

    ```bash
    ssh root@<INSTALLER_IP> 'hostname; cat /etc/os-release'
    ```

- [ ] 내부 디스크의 안정적인 `by-id` 경로를 찾습니다. `/dev/sda`류 이름이 아니라
      크기·모델·serial로 식별합니다(그런 이름은 부팅 순서나 USB 장치에 따라
      바뀝니다). 어떤 디스크가 내부 디스크인지 확신이 없으면 멈추고 다시
      확인합니다.

    ```bash
    ssh root@<INSTALLER_IP> 'lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE; ls -l /dev/disk/by-id/'
    ```

    `/dev/sda`나 `/dev/nvme0n1`이 아니라 `ata-Samsung_SSD_860_EVO_...`,
    `nvme-...` 같은 경로를 사용합니다.

- [ ] 그 경로를 `hosts/<host>/disko.nix`의 `device`에 설정합니다. 이 파일은
      단일 디스크 GPT 레이아웃을 만듭니다. 512M EFI 파티션이 `/boot`(vfat),
      나머지가 `/`(ext4)입니다.

- [ ] 대상 머신에서 하드웨어 설정을 생성하고, 그대로 믿지 말고 검토합니다.

    ```bash
    ssh root@<INSTALLER_IP> 'nixos-generate-config --show-hardware-config' \
      > hosts/<host>/hardware-configuration.nix
    ```

    `not-detected.nix` import, 커널 모듈 항목, `nixpkgs.hostPlatform`, CPU
    microcode 항목은 남깁니다. `fileSystems."/"`, `fileSystems."/boot"`,
    `swapDevices`는 제거합니다. `/`와 `/boot`는 `disko`가, 스왑은
    `modules/swap.nix`의 zram이 담당합니다. 이 항목들은 보통 `disko`와 충돌하는
    live 환경 값입니다.

- [ ] `hosts/<host>/default.nix`의 `imports`를 활성화(주석 해제)합니다.

    ```nix
    imports = [
      ./hardware-configuration.nix
      ./disko.nix
    ];
    ```

- [ ] 설치 전에 변경 사항을 검토합니다. 파싱 검사로 문법 오류를 미리 잡습니다.

    ```bash
    git diff -- hosts/<host>
    nix-instantiate --parse hosts/<host>/default.nix >/dev/null
    nix-instantiate --parse hosts/<host>/disko.nix >/dev/null
    nix-instantiate --parse hosts/<host>/hardware-configuration.nix >/dev/null
    ```

## 설치

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#<host> \
  --build-on-remote \
  root@<INSTALLER_IP>
```

이 명령은 `disko`로 파티션을 나눠 포맷한 뒤 시스템 클로저를 복사·설치하고,
부트로더를 올린 다음 초기 설정을 적용합니다. 이 단계에서 디스크가 지워지므로
디스크 ID를 마지막으로 한 번 더 확인합니다.

!!! tip "워크스테이션에서 flakes가 꺼져 있다면"
    같은 명령에 experimental features를 추가합니다.

    ```bash
    nix --extra-experimental-features "nix-command flakes" \
      run github:nix-community/nixos-anywhere -- \
      --flake .#<host> --build-on-remote root@<INSTALLER_IP>
    ```

## 첫 부팅 후

USB를 제거하고 내부 디스크로 부팅한 뒤:

- [ ] `ssh poby@<host>` 성공, `ssh root@<host>`와 패스워드 로그인은
      **실패해야 정상**
- [ ] tailnet 합류: `sudo tailscale up`, `tailscale status`로 확인
- [ ] 이후부터는 평범한 배포 모델로: 호스트 변경을 커밋하고 PR을 열어 CI/CD에
      맡깁니다 ([배포와 롤백](deploy.md) 참고)
- [ ] 호스트가 sops 수신자라면: 호스트 키가 바뀐 경우 비밀 재암호화
      ([비밀 관리](secrets.md))
- [ ] `hosts/<host>/` 변경과 `flake.lock` 커밋

## 검증

```bash
hostname && whoami && sudo -n true
systemctl is-active sshd tailscaled
zramctl && df -h && bootctl status
```

기대값: `poby` + passwordless sudo, 두 서비스 active, zram 스왑 존재,
vfat `/boot`, ext4 `/`.

## 베이스 설치 이후

호스트가 부팅되고 접속이 되면, 한 번에 하나씩 구성을 늘려 갑니다.

- sops-nix로 비밀을 구성합니다([비밀 관리](secrets.md)).
- 서비스를 추가하고 노출합니다([새 서비스 추가](add-service.md)).
- 모든 변경은 같은 흐름을 거칩니다. 저장소를 수정하고 PR을 열어 CI가 빌드하게
  한 뒤, 초록색이면 병합하고 CD가 배포하게 둡니다.
