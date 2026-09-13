#!/usr/bin/env bash
# tmux プラグインをコミット単位で固定して取得し、読み込む。.tmux.conf の末尾から run-shell -b で呼ばれる。
#
# TPM を使わない理由: TPM の `@plugin 'owner/repo#ref'` は `git clone -b` に渡るため、
# ブランチかタグしか指定できずコミットで固定できない。しかも tmux-continuum の最新タグ (v3.1.0) は
# 2015 年のもので、HEAD より 82 コミット古い。
#
# 固定したコミットを更新するときは PLUGINS の SHA を書き換える。既存の clone も次の tmux 起動時に
# fetch して切り替わる。
set -uo pipefail

PLUGIN_DIR="${TMUX_PLUGIN_DIR:-$HOME/.tmux/plugins}"

# "owner/repo commit" 。continuum は resurrect が設定する @resurrect-*-script-path を使うので、resurrect を先に置く
PLUGINS=(
  "tmux-plugins/tmux-resurrect cff343cf9e81983d3da0c8562b01616f12e8d548"
  "tmux-plugins/tmux-continuum 0698e8f4b17d6454c71bf5212895ec055c578da0"
)

warn() {
  # run-shell -b の標準エラーは表示されないので、tmux のメッセージとして出す
  tmux display-message "tmux-plugins.sh: $*" 2>/dev/null || echo "tmux-plugins.sh: $*" >&2
}

# $1 のディレクトリが $2 のコミットを指していれば成功
at_commit() {
  [ "$(git -C "$1" rev-parse -q --verify HEAD 2>/dev/null)" = "$2" ]
}

# $1=owner/repo を $2 のコミットで $PLUGIN_DIR に用意する
ensure_plugin() {
  local repo="$1" commit="$2"
  local dest="$PLUGIN_DIR/${repo#*/}"

  if [ -d "$dest" ]; then
    at_commit "$dest" "$commit" && return 0
    if [ ! -d "$dest/.git" ]; then
      warn "$dest は git の clone ではないため固定コミットに切り替えられません"
      return 1
    fi
    # 固定コミットが更新された: 既存の clone を切り替える
    git -C "$dest" fetch -q origin \
      && git -C "$dest" -c advice.detachedHead=false checkout -q "$commit" \
      && at_commit "$dest" "$commit" && return 0
    warn "$repo を $commit に切り替えられませんでした"
    return 1
  fi

  # 途中で失敗しても半端なディレクトリを残さないよう、同じディレクトリ内の一時名で作ってから mv する
  local tmp
  mkdir -p "$PLUGIN_DIR" || return 1
  tmp="$(mktemp -d "$PLUGIN_DIR/.${repo#*/}.XXXXXX")" || return 1
  if git clone -q --no-checkout "https://github.com/$repo" "$tmp" \
    && git -C "$tmp" -c advice.detachedHead=false checkout -q "$commit" \
    && at_commit "$tmp" "$commit" \
    && [ ! -e "$dest" ] && mv "$tmp" "$dest"; then
    return 0
  fi
  rm -rf -- "$tmp"
  warn "$repo の取得に失敗しました ($commit)"
  return 1
}

main() {
  if ! command -v git >/dev/null 2>&1; then
    warn "git が無いためプラグインを読み込みません"
    return 0
  fi

  local entry repo commit tmux_file
  for entry in "${PLUGINS[@]}"; do
    read -r repo commit <<<"$entry"
    ensure_plugin "$repo" "$commit" || continue
    # TPM と同じく、プラグイン直下の *.tmux を実行して読み込む
    for tmux_file in "$PLUGIN_DIR/${repo#*/}"/*.tmux; do
      [ -f "$tmux_file" ] || continue
      "$tmux_file" >/dev/null 2>&1 || warn "$tmux_file の読み込みに失敗しました"
    done
  done
}

main "$@"
