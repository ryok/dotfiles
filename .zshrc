# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Ensure Apple Silicon Homebrew wins
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Homebrew Python 3.13
export PATH="/opt/homebrew/opt/python@3.13/libexec/bin:$PATH"

# Google Cloud SDK (Homebrew)
if [ -f '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc' ]; then . '/opt/homebrew/share/google-cloud-sdk/completion.zsh.inc'; fi

# LM Studio CLI
export PATH="$PATH:/Users/ryookada/.lmstudio/bin"

# libomp (for ML libraries)
export DYLD_LIBRARY_PATH="/opt/homebrew/opt/libomp/lib:$DYLD_LIBRARY_PATH"

# uv shell completion
eval "$(uv generate-shell-completion zsh)"

# Aliases
alias claude="/Users/ryookada/.claude/local/claude"
alias yolo='claude --dangerously-skip-permissions'
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
