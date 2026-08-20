---
icon: fontawesome/solid/filter-circle-xmark
---

# DNS

AdGuard Home은 `yggdrasil`에서 실행하며 사설 홈 LAN의 DNS를 필터링합니다.
DHCP는 계속 ipTIME 공유기가 담당하고 클라이언트에 DNS 서버를 알립니다.
AdGuard Home의 DHCP 서버는 사용하지 않습니다.

## 네트워크 계약

| 항목 | 값 |
| --- | --- |
| 공유기 모드와 게이트웨이 | ipTIME NAT, `192.168.0.1/24` |
| LAN | `192.168.0.0/24` |
| yggdrasil 예약 주소 | `enp2s0`의 `192.168.0.53` |
| DNS 리스너 | TCP/UDP `192.168.0.53:53` |
| 관리 UI | `:3000`, tailnet 또는 SSH 터널로 접근 |

방화벽은 LAN 출발지 대역과 예약 목적지 주소를 동시에 검사합니다.
yggdrasil이 다른 주소를 받으면 LAN DNS는 닫힌 상태로 실패합니다. ipTIME
공유기도 포트 포워딩을 추가하지 않는 한 WAN에서 시작된 트래픽을 차단합니다.
DNS나 관리 UI 포트 포워딩을 만들지 마세요.

!!! warning "DHCP 고정 할당 필요"
    배포 전에 `192.168.0.53`을 고정 할당하세요. 임시 DHCP 임대 주소에 맞춰
    모듈을 바꾸지 마세요. 목적지 주소 검사는 주소 변경에 대비한 의도적인
    안전장치입니다.

## 네트워크 변경 후 사전 점검

이사, 공유기 교체, 서브넷 변경 뒤에는 이 모듈을 배포하기 전에 실제
네트워크를 다시 확인합니다:

```bash
ssh yggdrasil 'ip -brief address show dev enp2s0; ip -4 route show default'
ssh yggdrasil 'nmcli -f GENERAL.DEVICE,IP4.ADDRESS,IP4.GATEWAY,DHCP4.OPTION device show enp2s0'
```

인터페이스는 `enp2s0`, LAN은 `192.168.0.0/24`, 게이트웨이는
`192.168.0.1`이어야 합니다. 하나라도 다르면 네트워크 계약과 방화벽을 함께
수정하세요. 호스트 주소만 다르면 공유기의 고정 할당이 빠졌거나 잘못된
상태입니다.

## ipTIME 설정

1. `http://192.168.0.1`에서 관리도구를 엽니다.
2. 인터넷 회선이 WAN 포트에 연결되어 있고 공유기 LAN이
   `192.168.0.1/24`이며 DHCP 서버가 켜져 있는지 확인합니다.
3. yggdrasil의 `enp2s0` MAC 주소에 `192.168.0.53`을 예약합니다. 현재 MAC은
   `ssh yggdrasil 'cat /sys/class/net/enp2s0/address'`로 확인합니다.
4. yggdrasil의 연결을 다시 맺거나 임대를 갱신한 뒤 확인합니다:

    ```bash
    ssh yggdrasil 'ip -4 address show dev enp2s0'
    ```

이 명령에 `192.168.0.53/24`가 표시되기 전에는 서비스를 배포하지 마세요.
TCP/UDP `:53`이나 관리 UI를 WAN으로 포트 포워딩하지 마세요.

## 최초 설정

NixOS 모듈은 의도적으로 AdGuard Home의 최초 설정 화면을 남겨 둡니다.
관리자 비밀번호가 Git이나 Nix 스토어에 들어가지 않게 하기 위해서입니다.

1. 일반 PR 및 CI/CD 흐름으로 배포합니다.
2. SSH로 설정 UI를 포워딩합니다:

    ```bash
    ssh -L 3005:127.0.0.1:3000 yggdrasil
    ```

3. `http://127.0.0.1:3005`를 엽니다.
4. 관리 UI는 모든 인터페이스와 포트 `3000`을 선택합니다.
5. DNS는 모든 인터페이스와 포트 `53`을 선택합니다.
6. 고유한 비밀번호로 관리자 계정을 만듭니다.

생성된 설정, 인증 정보, 질의 통계, 필터 상태는
`/var/lib/AdGuardHome`에 저장됩니다. 배포 후에도 유지되지만 현재는 백업되지
않습니다.

## DHCP로 DNS 배포

ipTIME DHCP 서버 설정에서 기본 DNS 서버로 `192.168.0.53`을 배포합니다.
보조 DNS는 비워 둡니다. 공개 보조 리졸버를 넣으면 클라이언트가 예측할 수
없는 방식으로 AdGuard Home을 우회합니다.

일부 ipTIME 펌웨어는 공유기 자체의 업스트림 DNS 설정만 제공합니다. 이
경우 공유기의 기본 DNS를 `192.168.0.53`으로 설정합니다. 필터링은 동작하지만
AdGuard Home에는 개별 클라이언트 대신 공유기만 표시됩니다.

DHCP를 바꾼 뒤에는 클라이언트의 임대를 갱신합니다. 기존 임대는 갱신될
때까지 이전 DNS 설정을 유지합니다.

## 점검

LAN 클라이언트에서 실행합니다:

```bash
nslookup example.com 192.168.0.53
dig @192.168.0.53 example.com
```

SSH 터널로 AdGuard Home 질의 로그를 열어 요청이 보이는지 확인합니다. 활성화한
필터 목록의 도메인 하나도 시험해 단순 전달뿐 아니라 필터링까지 확인합니다.

yggdrasil에서 실행합니다:

```bash
systemctl is-active adguardhome
sudo ss -luntp 'sport = :53 or sport = :3000'
sudo journalctl -u adguardhome -n 100 --no-pager
```

## 장애 시 동작

AdGuard Home은 가정 내 단일 리졸버입니다. yggdrasil이 중단되면 복구되거나
공유기 DNS 설정을 바꿀 때까지 클라이언트의 DNS도 중단됩니다. 공개 보조
리졸버를 숨은 우회 경로로 추가하지 마세요. 올바른 이중화 방법은 두 번째
AdGuard Home 인스턴스를 두는 것입니다.
