# Brewfile — reproducible CLI toolchain for this dotfiles setup.
#
# Install everything with:
#   brew bundle --file=./Brewfile
# Check what is missing without installing:
#   brew bundle check --file=./Brewfile
#
# Scope: the command-line tools and casks these dotfiles assume, plus the
# global npm/uv packages that the shell config and AI-tool configs rely on.
# Intentionally omitted (machine-specific or a separate concern):
#   - VSCode extensions (dump separately with `brew bundle dump --file=-`)
#   - Go tools and any `file://` local packages (not portable)

# Taps
tap "arto-app/tap"
tap "k1low/tap", "https://github.com/k1LoW/homebrew-tap"
tap "steipete/tap"

# Core CLI tools
brew "awscli"          # AWS CLI
brew "azure-cli"       # Azure CLI
brew "ffmpeg"          # media transcoding
brew "gh"              # GitHub CLI (used by review/PR skills)
brew "git-lfs"         # referenced by ~/.gitconfig filter.lfs
brew "gogcli"          # GOG CLI
brew "jq"              # JSON processor
brew "libomp"          # OpenMP runtime (referenced in .zshrc for ML libs)
brew "node"            # Node.js runtime
brew "pipx"            # isolated Python app installer
brew "poppler"         # PDF utilities
brew "ripgrep"         # fast grep (rg)
brew "rtk"             # LLM token-reduction CLI proxy (see ~/.claude/RTK.md)
brew "terraform"       # infrastructure as code
brew "tmux"            # terminal multiplexer (see .tmux.conf)
brew "uv"              # fast Python package/venv manager (completion in .zshrc)
brew "yt-dlp"          # audio/video downloader

# Interactive shell experience (configured in .zshrc)
brew "starship"        # cross-shell prompt
brew "zoxide"          # history-aware smart cd (`z`)
brew "fzf"             # fuzzy finder (Ctrl-R / Ctrl-T)
brew "eza"             # modern ls replacement
brew "bat"             # modern cat with syntax highlighting

# Casks
cask "arto-app/tap/arto"  # Markdown reader
cask "gcloud-cli"         # Google Cloud SDK (sourced in .zshrc)
cask "libreoffice"        # office suite

# Global CLI packages that the dotfiles / AI-tool configs depend on
npm "@openai/codex"        # Codex CLI (configured via .config/codex/)
npm "@google/gemini-cli"   # Gemini CLI (configured via .config/gemini/)
npm "@googleworkspace/cli" # Google Workspace CLI
npm "@github/copilot"      # GitHub Copilot CLI
npm "agent-browser"        # browser-automation CLI (used by agent-browser skill)
npm "vercel"               # Vercel CLI

uv "awsume"  # AWS session switcher (alias + completion wired in .zshrc/.zshenv)
uv "kaggle"  # Kaggle CLI
