---
icon: fontawesome/solid/file-lines
---

# ADR-001: 문서 사이트에 Zensical 채택

**상태**: 채택 · **날짜**: 2026-06-12

## 배경

이 문서 사이트는 처음에 MkDocs Material로 만들어졌습니다. 2026년 2월
Material 팀이 **MkDocs 2.0은 Material for MkDocs와 호환되지 않는다**고
발표했습니다: 플러그인 시스템 제거, 테마 시스템 전면 개편, 그리고 MkDocs
1.x는 사실상 유지보수 종료. Material 9.x가 `mkdocs <2`로 핀을 걸어 빌드는
계속 동작하지만 토대가 수명을 다한 상태입니다.

## 검토한 선택지

| 선택지 | 평가 |
| --- | --- |
| mkdocs-material 유지 (핀 고정) | flake 핀 덕에 당장은 동작하지만 유지보수가 끝난 토대 위에서 계속 운영해야 함 |
| Astro Starlight / MDX 계열 | 외형은 가장 좋지만 npm 툴체인 → 업데이트마다 `buildNpmPackage` 해시 갱신 |
| mdBook | nixpkgs에 있고 매우 안정적이지만 i18n이 없고 외형이 소박함 |
| **Zensical** | Material 팀의 후속작; MkDocs 형식 설정을 읽음; nixpkgs 최상위 패키지 |

## 결정

**Zensical**로 이전하고 설정은 공식 형식인 `zensical.toml`을 사용합니다
(언어당 한 파일; TOML에는 상속이 없음).

## 결과

- 콘텐츠와 구조는 그대로 이전됨; 2개 언어 분리 빌드(`/` + `/ko/`) 구조도
  동일하게 동작.
- 빌드는 순수 Nix 유지: nixpkgs의 `pkgs.zensical`, 추가 툴체인 없음.
- 감수한 리스크: Zensical은 0.0.x. 완화책: 산출물이 정적 HTML이라 실패가
  호스트에는 영향을 주지 않고, flake 핀이 검증된 버전을 고정하며, 문서화된
  대안인 mkdocs-material로 되돌리는 것도 여전히 가능.
- 알려진 특이점: 일부 설정이 문서와 구현이 다름 (예: generator 표기
  토글은 `project`가 아니라 `extra` 아래).
