# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
# テーマは空にして oh-my-zsh のプロンプトを無効化 (プロンプトは starship が担う)。
# git プラグインのエイリアス等は引き続き利用する。
ZSH_THEME=""
plugins=(git)

# AWSume 補完関数 (compinit を走らせる oh-my-zsh の source より前に fpath へ追加する)
fpath=(~/.awsume/zsh-autocomplete/ $fpath)

source $ZSH/oh-my-zsh.sh

# ─── zsh オプション / 履歴 ──────────────────────────────────────────
# oh-my-zsh が設定しないものだけを上書きする。interactive_comments /
# hist_ignore_space / share_history / hist_verify / auto_cd / complete_in_word
# は oh-my-zsh が既に有効にしているので、ここでは触らない。
setopt glob_dots            # 補完候補にドットファイルを含める (dotfiles を触るので必須)
setopt print_eight_bit      # 日本語のファイル名をそのまま表示する
setopt hist_ignore_all_dups # 同じコマンドは履歴に 1 つだけ残す
setopt hist_save_no_dups    # 書き出し時にも重複を落とす
setopt hist_reduce_blanks   # 余分な空白を詰めてから記録する

# HISTSIZE (メモリ上) が SAVEHIST (ファイル) より大きいと、シェルを閉じた時点で
# 履歴が切り詰められる。揃えておく。
SAVEHIST=$HISTSIZE

# Homebrew Python (version-independent)
_brew_python=$(ls -d /opt/homebrew/opt/python@*/libexec/bin 2>/dev/null | tail -1)
[[ -n "$_brew_python" ]] && export PATH="$_brew_python:$PATH"
unset _brew_python

# Google Cloud SDK (Homebrew)
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'; fi

# LM Studio CLI
export PATH="$PATH:$HOME/.lmstudio/bin"

# macOS-specific settings
if [[ "$OSTYPE" == darwin* ]]; then
  # libomp (for ML libraries)
  export DYLD_LIBRARY_PATH="/opt/homebrew/opt/libomp/lib:$DYLD_LIBRARY_PATH"
  # Tailscale CLI
  alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
fi

# uv shell completion
command -v uv &>/dev/null && eval "$(uv generate-shell-completion zsh)"

# AWSume (source the AWSume script into the current shell)
alias awsume="source \$(command which awsume)"

# ─── 誤削除ガード ───────────────────────────────────────────────────
# rm は取り消せない。明らかに再生成できるものだけ許可し、それ以外は trash
# (macOS 標準の /usr/bin/trash) に誘導する。
# 抜け道は zsh 標準の `command rm` なので、意図した削除は妨げない。
_rm_deny() {
  print -u2 "rm は取り消せません。ゴミ箱へ送る trash を使ってください。"
  print -u2 "  シンボリックリンク: unlink / 空ディレクトリ: rmdir"
  print -u2 "  意図して rm する場合のみ: command rm ..."
  return 1
}

rm() {
  # 再生成できるもの = 消えても困らないもの
  local -A _rm_safe
  _rm_safe=(
    .DS_Store     1
    node_modules  1
    .direnv       1
    __pycache__   1
    .pytest_cache 1
    .ruff_cache   1
    .mypy_cache   1
  )

  local -a targets
  local a
  for a in "$@"; do
    [[ "$a" == -* ]] || targets+=("$a")
  done

  (( ${#targets} )) || { _rm_deny; return 1; }

  for a in "${targets[@]}"; do
    # 一時領域とキャッシュ配下は無条件で許可する
    [[ "$a" == /tmp/* ]] && continue
    [[ -n "$TMPDIR" && "$a" == "$TMPDIR"* ]] && continue
    [[ "$a" == */.cache/* ]] && continue
    # ファイル名がホワイトリストにあれば許可する
    [[ -n "${_rm_safe[${a:t}]}" ]] && continue
    _rm_deny
    return 1
  done

  command rm "$@"
}

# Aliases
alias yolo='claude --dangerously-skip-permissions'

# ─── Modern CLI tools ───────────────────────────────────────────────
# 各ツールは存在する場合のみ有効化する (未インストールでも起動を壊さない)。

# eza: ls の置き換え (色分け・git 対応・ディレクトリ優先)
if command -v eza &>/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --git --group-directories-first'
  alias la='eza -la --git --group-directories-first'
  alias lt='eza --tree --level=2 --group-directories-first'
fi

# bat: cat の置き換え (シンタックスハイライト)
command -v bat &>/dev/null && alias cat='bat --style=plain --paging=never'

# zoxide: 履歴学習型の smart cd (`z <部分名>` で移動)
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"

# fzf: 曖昧検索 (Ctrl+R 履歴検索・Ctrl+T ファイル選択など)
command -v fzf &>/dev/null && source <(fzf --zsh) 2>/dev/null

# direnv: ディレクトリ単位の環境変数切り替え (.envrc)。
# Azure アカウント分離 (sidework/dele/somic の AZURE_CONFIG_DIR) などに使用。
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# ─── Azure CLI アカウント分離 ───────────────────────────────────────
# 雇用主ごとに設定ディレクトリ (AZURE_CONFIG_DIR) を分け、トークン/既定
# サブスクリプションの取り違えを防ぐ。詳細は ops-cockpit の
# .claude/skills/_shared/azure-accounts.md を参照。
if command -v az &>/dev/null; then
  # 松尾研: 既定の ~/.azure を使用
  az-matsuo() { AZURE_CONFIG_DIR="$HOME/.azure" command az "$@"; }
  # dele (兼業; somic 等の案件): 隔離した ~/.azure-dele を使用（アカウント: ryo.okada@dele.co.jp）
  az-dele()   { AZURE_CONFIG_DIR="$HOME/.azure-dele" command az "$@"; }
fi

# starship: クロスシェルプロンプト (最後に初期化してプロンプトを確定させる)
command -v starship &>/dev/null && eval "$(starship init zsh)"

# 未インストールのツールをガードした際の終了ステータスが、最初のプロンプトに
# エラーとして漏れないようにする。
true
