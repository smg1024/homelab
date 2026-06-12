# 문서 사이트

이 사이트 자체도 flake로 선언되어 있습니다. 콘텐츠는 `docs/docs/` 아래
Markdown 파일이고, [MkDocs Material](https://squidfunk.github.io/mkdocs-material/)로
빌드되어 yggdrasil의 Caddy가 정적 파일로 서빙합니다 (tailnet 전용).

## 구조

```text
docs/
├── mkdocs.yml   # 사이트 설정, 네비게이션
└── docs/        # Markdown 콘텐츠
```

- flake output: `packages.<system>.docs` — `mkdocs build --strict` 결과물
- 서빙 모듈: `services/docs-site.nix` — Caddy `file_server`, tailnet 전용

## 문서 수정 워크플로

1. `docs/docs/` 아래 Markdown을 수정합니다. 새 페이지는 `docs/mkdocs.yml`의
   `nav`에도 추가합니다.
2. 로컬에서 빌드를 검증합니다.

    ```bash
    nix build .#docs
    ```

    `--strict` 모드라서 깨진 내부 링크는 빌드 실패가 됩니다.

3. 실시간 미리보기가 필요하면 devShell을 사용합니다.

    ```bash
    nix develop .#docs
    cd docs && mkdocs serve
    # http://127.0.0.1:8000 접속
    ```

4. 커밋 후 배포하면 문서가 시스템 클로저에 포함되어 함께 갱신됩니다.

    ```bash
    just switch yggdrasil
    ```

!!! note "flake와 git"
    flake 빌드는 git에 추적되는 파일만 봅니다. 새로 만든 파일은 `git add`
    해야 `nix build .#docs`에 반영됩니다.
