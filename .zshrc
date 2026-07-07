# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
# テーマは空にして oh-my-zsh のプロンプトを無効化 (プロンプトは starship が担う)。
# git プラグインのエイリアス等は引き続き利用する。
ZSH_THEME=""
plugins=(git)

# AWSume 補完関数 (compinit を走らせる oh-my-zsh の source より前に fpath へ追加する)
fpath=(~/.awsume/zsh-autocomplete/ $fpath)

source $ZSH/oh-my-zsh.sh

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

# starship: クロスシェルプロンプト (最後に初期化してプロンプトを確定させる)
command -v starship &>/dev/null && eval "$(starship init zsh)"

# 未インストールのツールをガードした際の終了ステータスが、最初のプロンプトに
# エラーとして漏れないようにする。
true
