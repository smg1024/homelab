# NixOS Homelab Install Guide

이 문서는 `yggdrasil`, `midgard`를 NixOS installer USB에서 부팅한 뒤 이 repo를
source of truth로 사용해 최초 설치하는 절차를 설명한다.

기본 원칙:

- 최초 설치는 NixOS installer USB 환경에 `root`로 SSH 접속해서 진행한다.
- 설치 후 운영은 `poby` 사용자와 SSH key로 접속한다.
- 대상 머신에서 설정 파일을 직접 고치지 않는다.
- 대상 머신은 디스크 ID와 하드웨어 정보를 조회하는 용도로만 사용한다.
- 실제 설정 변경은 항상 이 Git repo에서 한다.
- `disko`는 대상 디스크를 재파티션/포맷한다. 디스크 선택을 반드시 확인한다.

## 현재 repo 상태

이 repo는 두 호스트를 가진 flake로 구성된다.

```text
yggdrasil
midgard
```

공통 설정은 `modules/`에 있고, 호스트별 설정은 `hosts/<host>/`에 있다.

설치 전에 반드시 채워야 하는 파일:

```text
hosts/yggdrasil/disko.nix
hosts/yggdrasil/hardware-configuration.nix
hosts/yggdrasil/default.nix

hosts/midgard/disko.nix
hosts/midgard/hardware-configuration.nix
hosts/midgard/default.nix
```

현재 `hosts/<host>/default.nix`의 imports는 의도적으로 주석 처리되어 있다.

```nix
# imports = [
#   ./hardware-configuration.nix
#   ./disko.nix
# ];
```

각 호스트의 disk by-id와 hardware configuration을 채운 뒤에만 이 imports를
활성화한다.

## 설치 전 준비

워크스테이션에서 확인한다.

```bash
cd /Users/kmeatai/Developer/homelab
git status -sb
```

작업트리가 깨끗한 상태에서 시작하는 것을 권장한다.

필요한 것:

- Nix가 설치된 워크스테이션
- 이 repo
- NixOS installer USB
- 대상 머신의 유선 또는 안정적인 무선 네트워크
- `poby`로 접속할 SSH private key
- 대상 머신의 기존 데이터 백업

주의:

- 이 절차는 대상 머신 디스크를 지운다.
- yggdrasil을 먼저 설치하고 검증한 뒤 midgard를 설치한다.
- 동시에 두 머신을 진행하지 않는다.

## 1. 대상 머신을 installer USB로 부팅

먼저 `yggdrasil`부터 진행한다.

대상 머신에 NixOS installer USB를 꽂고 부팅한다.

installer shell이 뜨면 대상 머신 콘솔에서 root 비밀번호를 임시로 설정한다.

```bash
sudo passwd root
```

이 비밀번호는 installer live environment에서만 쓰는 임시 비밀번호다. 설치 후
재부팅하면 최종 NixOS 설정이 적용되고 root SSH login은 비활성화된다.

SSH 서버를 시작한다.

```bash
sudo systemctl start sshd
```

대상 머신의 IP 주소를 확인한다.

```bash
ip addr
```

LAN IP를 기록한다.

```text
<YGGDRASIL_INSTALLER_IP>
```

## 2. 워크스테이션에서 installer에 SSH 접속 확인

워크스테이션에서 접속한다.

```bash
ssh root@<YGGDRASIL_INSTALLER_IP>
```

접속되면 installer 환경 안에 들어온 것이다.

프롬프트가 헷갈리면 다음 명령으로 현재 머신을 확인한다.

```bash
hostname
cat /etc/os-release
```

확인 후 SSH 세션은 열어둬도 되고, 필요한 명령만 실행한 뒤 나와도 된다.

```bash
exit
```

## 3. disk by-id 확인

대상 머신 installer shell에서 실행한다.

```bash
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE
ls -l /dev/disk/by-id/
```

또는 워크스테이션에서 SSH로 직접 실행해도 된다.

```bash
ssh root@<YGGDRASIL_INSTALLER_IP> 'lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE; ls -l /dev/disk/by-id/'
```

목표는 설치할 내부 디스크의 안정적인 by-id 경로를 찾는 것이다.

예시:

```text
/dev/disk/by-id/ata-Samsung_SSD_860_EVO_250GB_S3Z...
/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_...
```

사용하지 말아야 할 값:

```text
/dev/sda
/dev/nvme0n1
```

이 이름들은 부팅 순서나 USB 장치에 따라 바뀔 수 있다.

주의:

- USB installer 자체를 대상 디스크로 고르면 안 된다.
- 크기, 모델명, serial을 보고 내부 디스크인지 확인한다.
- 확신이 없으면 여기서 멈추고 다시 확인한다.

## 4. disko.nix의 placeholder 교체

워크스테이션의 repo에서 `hosts/yggdrasil/disko.nix`를 연다.

현재는 이런 placeholder가 있다.

```nix
device = "/dev/disk/by-id/REPLACE_WITH_YGGDRASIL_DISK_ID";
```

installer에서 확인한 실제 by-id 경로로 교체한다.

예시:

```nix
device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_250GB_S3Z...";
```

이 파일은 다음 레이아웃을 만든다.

```text
GPT partition table
512M EFI System Partition  -> /boot, vfat
remaining disk             -> /, ext4
```

이 단계는 아직 설치를 실행하지 않는다. 파일만 수정한다.

## 5. hardware-configuration.nix 생성

대상 머신 installer shell에서 실행한다.

```bash
nixos-generate-config --show-hardware-config
```

출력 전체를 복사해서 워크스테이션 repo의 파일에 붙여 넣는다.

```text
hosts/yggdrasil/hardware-configuration.nix
```

기존 placeholder 전체를 생성된 내용으로 교체한다.

워크스테이션에서 바로 파일로 저장하려면 다음처럼 해도 된다.

```bash
ssh root@<YGGDRASIL_INSTALLER_IP> \
  'nixos-generate-config --show-hardware-config' \
  > hosts/yggdrasil/hardware-configuration.nix
```

주의:

- `hardware-configuration.nix`는 대상 머신에서 생성한 값을 사용한다.
- yggdrasil에서 생성한 파일을 midgard에 재사용하지 않는다.
- disko가 `/`와 `/boot` 파일시스템을 선언하므로 생성된 hardware config를 그대로
  믿지 말고 검토한다.

`hardware-configuration.nix`에는 보통 이런 내용이 남으면 된다.

```nix
imports = [
  (modulesPath + "/installer/scan/not-detected.nix")
];

boot.initrd.availableKernelModules = [ ... ];
boot.initrd.kernelModules = [ ... ];
boot.kernelModules = [ ... ];
boot.extraModulePackages = [ ... ];

nixpkgs.hostPlatform = "x86_64-linux";
hardware.cpu.intel.updateMicrocode = ...;
hardware.cpu.amd.updateMicrocode = ...;
```

다음 항목은 `disko.nix`와 중복되거나 installer/live 환경의 값일 수 있으므로 특히
확인한다.

```nix
fileSystems."/"
fileSystems."/boot"
swapDevices
```

이 repo에서는 `/`와 `/boot`는 `disko.nix`가 담당한다. swap은
`modules/swap.nix`의 zram swap이 담당한다. 따라서 hardware config에 위 항목이
들어 있다면 왜 필요한지 확실할 때만 남긴다.

## 6. host default.nix imports 활성화

워크스테이션 repo에서 `hosts/yggdrasil/default.nix`를 연다.

주석 처리된 imports를 활성화한다.

변경 전:

```nix
# imports = [
#   ./hardware-configuration.nix
#   ./disko.nix
# ];
```

변경 후:

```nix
imports = [
  ./hardware-configuration.nix
  ./disko.nix
];
```

이제 `yggdrasil` flake config가 실제 하드웨어 설정과 디스크 레이아웃을 포함한다.

## 7. 설치 전 로컬 검토

워크스테이션에서 변경 사항을 확인한다.

```bash
git diff -- hosts/yggdrasil
```

특히 다음을 확인한다.

```text
hosts/yggdrasil/disko.nix
  device가 실제 내부 디스크 by-id인지

hosts/yggdrasil/hardware-configuration.nix
  yggdrasil installer에서 생성한 내용인지

hosts/yggdrasil/default.nix
  imports가 활성화되었는지
```

Nix 문법만 가볍게 확인할 수 있다.

```bash
nix-instantiate --parse hosts/yggdrasil/default.nix >/dev/null
nix-instantiate --parse hosts/yggdrasil/disko.nix >/dev/null
nix-instantiate --parse hosts/yggdrasil/hardware-configuration.nix >/dev/null
```

`flake.lock`이 아직 없다면 이후 flake 평가 또는 설치 과정에서 생성될 수 있다.
생성되면 설치 성공 후 함께 커밋한다.

## 8. nixos-anywhere 실행

워크스테이션에서 실행한다.

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#yggdrasil \
  --build-on-remote \
  root@<YGGDRASIL_INSTALLER_IP>
```

워크스테이션의 Nix에서 flakes가 꺼져 있다는 에러가 나면 같은 명령에 experimental
features를 명시한다.

```bash
nix --extra-experimental-features "nix-command flakes" \
  run github:nix-community/nixos-anywhere -- \
  --flake .#yggdrasil \
  --build-on-remote \
  root@<YGGDRASIL_INSTALLER_IP>
```

이 명령은 대상 머신에 SSH로 접속해서 다음을 수행한다.

```text
disko 기반 파티션/포맷
NixOS system closure 복사/설치
bootloader 설치
초기 NixOS 설정 적용
```

중요:

- 이 단계에서 대상 디스크의 기존 데이터는 삭제된다.
- 실행 전 disk by-id를 다시 확인한다.
- 설치 중 에러가 나면 출력 내용을 저장하고 다음 단계로 진행하지 않는다.

## 9. 설치 후 재부팅과 SSH 확인

설치가 끝나면 대상 머신을 재부팅한다.

USB installer를 제거하고 내부 디스크로 부팅한다.

부팅 후 워크스테이션에서 SSH 접속을 확인한다.

LAN IP 또는 hostname이 잡혀 있으면:

```bash
ssh yggdrasil
```

IP로 먼저 확인해도 된다.

```bash
ssh poby@<YGGDRASIL_LAN_IP>
```

root SSH 접속은 실패해야 정상이다.

```bash
ssh root@yggdrasil
```

password SSH login도 실패해야 정상이다.

접속 후 기본 상태를 확인한다.

```bash
hostname
sudo systemctl status sshd
sudo systemctl status tailscaled
zramctl
free -h
df -h
```

## 10. Tailscale 로그인

설치 후 `poby`로 접속한 상태에서 Tailscale을 tailnet에 붙인다.

```bash
sudo tailscale up
```

브라우저 인증 URL이 나오면 인증한다.

인증 후 상태를 확인한다.

```bash
tailscale status
tailscale ip
```

이후에는 Tailscale IP 또는 MagicDNS 이름으로 SSH 접속할 수 있다.

```bash
ssh yggdrasil
```

## 11. 첫 remote rebuild 테스트

워크스테이션에서 실행한다.

워크스테이션이 macOS일 수 있으므로 build도 Linux 대상 머신에서 수행하도록
`--build-host`를 명시한다. macOS에서 target config의 Linux용 `nixos-rebuild`를
재실행하지 않도록 `--fast`도 함께 사용한다. `poby`는 `wheel`이고 Nix trusted
user에 포함되므로 remote build와 remote switch에 사용할 수 있다.

```bash
nix run github:NixOS/nixpkgs/nixos-25.11#nixos-rebuild -- \
  test \
  --fast \
  --flake .#yggdrasil \
  --build-host yggdrasil \
  --target-host yggdrasil \
  --use-remote-sudo
```

문제가 없으면 switch를 실행한다.

```bash
nix run github:NixOS/nixpkgs/nixos-25.11#nixos-rebuild -- \
  switch \
  --fast \
  --flake .#yggdrasil \
  --build-host yggdrasil \
  --target-host yggdrasil \
  --use-remote-sudo
```

이 방식이 설치 이후의 기본 운영 모델이다.

```text
repo 수정
nixos-rebuild test 또는 nix run ...#nixos-rebuild -- test
nixos-rebuild switch 또는 nix run ...#nixos-rebuild -- switch
git commit
```

## 12. yggdrasil 변경사항 커밋

설치가 성공하면 워크스테이션에서 변경사항을 확인한다.

```bash
git status -sb
git diff -- hosts/yggdrasil flake.lock
```

커밋한다.

```bash
git add hosts/yggdrasil
if [ -f flake.lock ]; then git add flake.lock; fi
git commit -m "configure yggdrasil hardware"
```

## 13. midgard 설치

yggdrasil 설치와 검증이 끝난 뒤 midgard를 같은 방식으로 진행한다.

반복할 파일:

```text
hosts/midgard/disko.nix
hosts/midgard/hardware-configuration.nix
hosts/midgard/default.nix
```

반복할 명령:

```bash
sudo passwd root
sudo systemctl start sshd
ip addr
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE
ls -l /dev/disk/by-id/
nixos-generate-config --show-hardware-config
```

워크스테이션에서 설치:

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#midgard \
  root@<MIDGARD_INSTALLER_IP>
```

설치 후 확인:

```bash
ssh poby@midgard
sudo tailscale up
tailscale status
zramctl
df -h
```

remote rebuild 테스트:

```bash
nix run github:NixOS/nixpkgs/nixos-25.11#nixos-rebuild -- \
  test \
  --fast \
  --flake .#midgard \
  --build-host poby@midgard \
  --target-host poby@midgard \
  --use-remote-sudo
```

성공하면:

```bash
nix run github:NixOS/nixpkgs/nixos-25.11#nixos-rebuild -- \
  switch \
  --fast \
  --flake .#midgard \
  --build-host poby@midgard \
  --target-host poby@midgard \
  --use-remote-sudo
```

커밋:

```bash
git add hosts/midgard
if [ -f flake.lock ]; then git add flake.lock; fi
git commit -m "configure midgard hardware"
```

## 14. 설치 후 기본 검증 체크리스트

각 호스트에서 확인한다.

```bash
hostname
whoami
groups
sudo -n true
systemctl is-active sshd
systemctl is-active tailscaled
tailscale status
zramctl
free -h
df -h
bootctl status
```

기대값:

```text
whoami -> poby
groups -> wheel, networkmanager 포함
sudo -n true -> 비밀번호 없이 성공
sshd -> active
tailscaled -> active
zramctl -> zram device 표시
/boot -> vfat EFI partition
/ -> ext4 root filesystem
```

워크스테이션에서 확인한다.

```bash
ssh yggdrasil
ssh poby@midgard
```

root SSH는 실패해야 한다.

```bash
ssh root@yggdrasil
ssh root@midgard
```

## 15. 롤백 기본

NixOS 설정 변경 후 문제가 생기면 대상 머신에서 이전 generation으로 되돌릴 수
있다.

```bash
sudo nixos-rebuild switch --rollback
```

부팅 자체가 실패하면 부팅 메뉴에서 이전 generation을 선택한다.

## 16. 다음 단계

두 머신의 base install이 끝난 뒤에만 다음을 진행한다.

```text
sops-nix 실제 secrets 구성
backup 구성
monitoring 구성
Podman 구성
Caddy / DNS / apps
```

서비스는 하나씩 추가하고, 각 단계마다 다음을 반복한다.

```bash
nix run github:NixOS/nixpkgs/nixos-25.11#nixos-rebuild -- \
  test \
  --fast \
  --flake .#<host> \
  --build-host <host> \
  --target-host <host> \
  --use-remote-sudo

nix run github:NixOS/nixpkgs/nixos-25.11#nixos-rebuild -- \
  switch \
  --fast \
  --flake .#<host> \
  --build-host <host> \
  --target-host <host> \
  --use-remote-sudo

git add .
git commit -m "<small focused change>"
```
