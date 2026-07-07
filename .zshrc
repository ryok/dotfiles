# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
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
