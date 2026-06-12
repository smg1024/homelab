---
icon: lucide/server
---

# alfheim

실험용 Oracle Cloud Infrastructure ARM VM입니다 (`aarch64-linux`).

## 책임

- OCI 위에서의 NixOS 동작 검증
- 영구 서비스로 승격하기 전 클라우드 호스팅 패턴 테스트
- 공유 운영자 베이스라인을 갖춘 소형 원격 노드 제공

현재는 공유 모듈만 로드하며 애플리케이션 서비스는 없습니다.

## 접근

SSH는 의도적으로 **tailnet을 통해서만** 노출됩니다. OCI 공인 주소로는 SSH가
열려 있지 않습니다.

```bash
ssh poby@alfheim.tail6fc192.ts.net
```

!!! note "배포 시 SSH 키"
    `Justfile`이 alfheim 배포 시
    `~/.config/sops-nix/secrets/github_ssh_key`를 SSH 키로 사용합니다.
    다른 호스트와 달리 대상 주소도 MagicDNS 전체 이름을 사용합니다.
