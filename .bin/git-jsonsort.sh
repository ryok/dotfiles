#!/usr/bin/env bash
# git の clean filter: Claude Code が settings.json を書き戻す際に生じる
# 「キー順の入れ替え」「配列のインライン⇔複数行の揺れ」を index 側で正規化し、
# 意味のない差分が git diff に出続けるのを防ぐ。
#
# 配線: .gitattributes の filter=jsonsort + .gitconfig の [filter "jsonsort"]
# 入出力: 作業ツリーのファイルを stdin で受け取り、正規形を stdout に書く。
#
# ソートするのはオブジェクトのキー (jq -S) と permissions の allow/deny/ask 配列だけ。
# 他の配列は順序に意味があるため、意図的にそのまま残す:
#   - hooks              … 実行順
#   - autoMode.environment … 見出しから始まる散文で、行順が情報
set -uo pipefail

# jq が無い環境ではフィルタを素通しにする (git add を失敗させない)
if ! command -v jq >/dev/null 2>&1; then
  exec cat
fi

# インフラ起因の失敗は握り潰さず非ゼロで終了する。
# clean filter が exit 0 を返すと git は出力をそのまま index に書くため、
# ここで素通しにすると空ファイルや切り詰められた JSON が無警告で staged される。
tmp=$(mktemp) || { echo "git-jsonsort: mktemp に失敗しました" >&2; exit 1; }
trap 'rm -f "$tmp"' EXIT
cat >"$tmp" || { echo "git-jsonsort: 標準入力の読み込みに失敗しました" >&2; exit 1; }

# 全部読めたうえで JSON が壊れている場合は素通しにする (整形の失敗で内容を失わない)
if ! jq empty "$tmp" >/dev/null 2>&1; then
  cat "$tmp"
  exit 0
fi

jq -S '
  if (.permissions | type) == "object" then
    .permissions |= with_entries(
      if (.key | test("^(allow|deny|ask)$")) and ((.value | type) == "array")
      then .value |= sort
      else .
      end
    )
  else . end
' "$tmp"
