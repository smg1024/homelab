# 호스트 부트스트랩

새(또는 죽은) 머신에 이 저장소를 기반으로 NixOS를 설치하는 절차입니다.
installer USB 위에서 `nixos-anywhere`를 사용합니다. 모든 주의사항이 담긴
전체 가이드는 저장소 루트의 `INSTALL.md`에 있고, 이 페이지는 운영 요약본입니다.

!!! danger "대상 디스크가 지워집니다"
    `disko`는 지정된 디스크를 재파티션하고 포맷합니다. 실행 전에 디스크
    ID를 반드시 거듭 확인하세요.

## 준비

- [ ] 대상 머신을 NixOS installer USB로 부팅
- [ ] 콘솔에서 `sudo passwd root`(임시) + `sudo systemctl start sshd`,
      LAN IP 기록
- [ ] 안정적인 디스크 경로 확인: `ls -l /dev/disk/by-id/` —
      `/dev/sda`류 이름은 사용 금지
- [ ] 저장소의 `hosts/<host>/disko.nix`에 디스크 설정
- [ ] 대상 머신에서 하드웨어 설정 생성:

    ```bash
    ssh root@<INSTALLER_IP> 'nixos-generate-config --show-hardware-config' \
      > hosts/<host>/hardware-configuration.nix
    ```

    `fileSystems`/`swapDevices` 항목은 제거 — `/`와 `/boot`는 disko가,
    스왑은 zram이 담당합니다.

- [ ] `hosts/<host>/default.nix`의 `imports` 활성화 후 `git diff`로 검토

## 설치

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#<host> \
  --build-on-remote \
  root@<INSTALLER_IP>
```

## 첫 부팅 후

- [ ] `ssh poby@<host>` 성공, `ssh root@<host>`와 패스워드 로그인은
      **실패해야 정상**
- [ ] tailnet 합류: `sudo tailscale up`, `tailscale status`로 확인
- [ ] 첫 원격 리빌드: `just test <host>` → `just switch <host>`
- [ ] 호스트가 sops 수신자라면: 호스트 키가 바뀐 경우 시크릿 재암호화
      ([절차](secrets.md))
- [ ] `hosts/<host>/` 변경과 `flake.lock` 커밋

## 검증

```bash
hostname && whoami && sudo -n true
systemctl is-active sshd tailscaled
zramctl && df -h && bootctl status
```

기대값: `poby` + passwordless sudo, 두 서비스 active, zram 스왑 존재,
vfat `/boot`, ext4 `/`.
