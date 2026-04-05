# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Homebrew Python (version-independent)
_brew_python=$(ls -d /opt/homebrew/opt/python@*/libexec/bin 2>/dev/null | sort -V | tail -1)
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

# Aliases
alias yolo='claude --dangerously-skip-permissions'
