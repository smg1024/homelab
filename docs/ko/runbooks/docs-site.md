---
icon: lucide/book-open
---

# 문서 사이트

이 사이트 자체도 flake로 선언되어 있습니다. 콘텐츠는 `docs/` 아래 Markdown
파일이고, [Zensical](https://zensical.org/)(Material for MkDocs 팀이 만든
정적 사이트 생성기)로 빌드되어 yggdrasil의 Caddy가 정적 파일로 서빙합니다
(tailnet 전용). 설정은 Zensical 정식 형식인 `zensical.toml`을 사용합니다.

기본 언어는 영어이며, 한국어 번역본이 `/ko/` 아래 별도 서브사이트로
빌드됩니다. 헤더의 언어 선택기로 전환할 수 있습니다.

## 구조

```text
docs/
├── package.nix       # derivation 정의, flake.nix에서 callPackage로 연결
├── shell.nix         # `zensical serve`용 개발 셸, 패키지 의존성을 상속
├── Makefile          # 빌드(`make`)와 설치(`make install`) 타깃
├── zensical.toml     # 영어(기본) 사이트 설정
├── zensical.ko.toml  # 한국어 사이트 설정 (전체 복사본 — TOML에는 상속 없음)
├── en/               # 영어 콘텐츠 (원본)
└── ko/               # 한국어 번역, en/을 미러링
```

- flake output: `packages.<system>.docs` — 두 언어 모두 `zensical build
  --strict`로 빌드, 한국어는 `ko/` 하위 디렉토리에 생성
- 서빙 모듈: `services/docs-site.nix` — Caddy `file_server`, tailnet 전용

## 문서 수정 워크플로

1. 먼저 `docs/en/`의 영어 페이지를 수정하고, `docs/ko/`에 같은 변경을
   반영합니다. 새 페이지는 `zensical.toml`과 `zensical.ko.toml` **양쪽**
   `nav`에 추가해야 합니다.
2. 로컬에서 빌드를 검증합니다.

    ```bash
    nix build .#docs
    ```

    `--strict` 모드라서 깨진 내부 링크는 빌드 실패가 됩니다.

3. 실시간 미리보기가 필요하면 devShell을 사용합니다.

    ```bash
    nix develop .#docs
    cd docs && zensical serve                       # 영어
    cd docs && zensical serve -f zensical.ko.toml   # 한국어
    # http://127.0.0.1:8000 접속
    ```

4. 커밋 후 배포하면 문서가 시스템 클로저에 포함되어 함께 갱신됩니다.

    ```bash
    just switch yggdrasil
    ```

!!! note "flake와 git"
    flake 빌드는 git에 추적되는 파일만 봅니다. 새로 만든 파일은 `git add`
    해야 `nix build .#docs`에 반영됩니다.
