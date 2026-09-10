#!/usr/bin/env bash
# delta を使う git のフックポイントを、delta が無い環境でも壊れないようにする
# ラッパー。
#
# なぜ必要か: .gitconfig は core.pager / interactive.diffFilter から delta を
# 呼ぶが、delta は Brewfile 経由でしか入らない。.bin/bootstrap.sh の brew-less
# 経路が入れるのは rtk / agent-browser / herdr の 3 つだけなので、共有 GPU
# サーバのような brew の無いホストでは delta が存在しない。
#
# 使い方 (.gitconfig から):
#   core.pager             = ~/.bin/git-delta.sh pager
#   interactive.diffFilter = ~/.bin/git-delta.sh diff-filter
set -uo pipefail

role="${1:-pager}"

if command -v delta >/dev/null 2>&1; then
  case "$role" in
    pager)       exec delta --line-numbers ;;
    diff-filter) exec delta --color-only ;;
  esac
fi

# --- delta が無い場合のフォールバック ---
case "$role" in
  pager)
    # git 自身の最終的な既定と同じく less を使う。$PAGER は見ない:
    # git の優先順位は GIT_PAGER > core.pager > PAGER なので、core.pager が
    # 設定されている時点で $PAGER は無視されるのが本来の挙動。
    if command -v less >/dev/null 2>&1; then
      # git は LESS 未設定時に FRX を与える。既存の値は尊重する。
      export LESS="${LESS:-FRX}"
      exec less
    fi
    exec cat
    ;;
  diff-filter)
    # diffFilter は色付けするだけの役割なので、無ければ素通しでよい。
    # git は色付き diff を渡してくるため、cat でも表示は壊れない。
    exec cat
    ;;
esac

echo "git-delta.sh: unknown role '$role' (expected 'pager' or 'diff-filter')" >&2
exit 1
