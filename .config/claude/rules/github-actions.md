---
paths:
  - ".github/workflows/*.yml"
  - ".github/workflows/*.yaml"
---

# GitHub Actions のワークフローを編集したら actionlint を通す

編集したファイルに対して `actionlint <path>` を実行し、エラーが無いことを確認
してから完了とする。

式の構文ミス、存在しない `needs` の参照、`run` 内のシェルの誤りなど、**push して
実行させないと分からない失敗**をローカルで潰せる。ワークフローは修正のたびに
push が必要なぶん、往復のコストが特に高い。

- actionlint が未インストールなら、その旨を報告して完了扱いにしない
  (macOS: `brew install actionlint`)
- actionlint は `run` 内のシェルを shellcheck に渡すので、シェル側の指摘も同時に出る
