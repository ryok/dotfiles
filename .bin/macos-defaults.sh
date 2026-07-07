#!/usr/bin/env bash
set -ue -o pipefail

# Opinionated macOS system defaults (keyboard / Finder / screenshots).
# Not run by install.sh — invoke manually and review first:
#   .bin/macos-defaults.sh --dry-run   # preview
#   .bin/macos-defaults.sh             # apply
# `defaults write` is idempotent, so re-running is safe.

DRY_RUN=false

helpmsg() {
  command echo "Usage: $0 [--help | -h] [--dry-run | -n] [--debug | -d]" 1>&2
  command echo "" 1>&2
  command echo "  -n, --dry-run  Print the actions without changing anything" 1>&2
  command echo "  -d, --debug    Run with 'set -x' tracing enabled" 1>&2
  command echo "  -h, --help     Show this help" 1>&2
}

run() {
  if $DRY_RUN; then
    command echo "[dry-run] $*"
  else
    "$@"
  fi
}

while [ $# -gt 0 ]; do
  case ${1} in
    --debug|-d)  set -uex ;;
    --dry-run|-n) DRY_RUN=true ;;
    --help|-h)   helpmsg; exit 0 ;;
    *)           command echo "Unknown option: ${1}" 1>&2; helpmsg; exit 1 ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" ]]; then
  command echo "macos-defaults.sh: not macOS, nothing to do." 1>&2
  exit 0
fi

command echo "Applying macOS defaults..."

# ── Keyboard ────────────────────────────────────────────────────────
# Fast key repeat, short delay, and disable press-and-hold accent popup
# so holding a key repeats it (better for vim-style editing).
run defaults write NSGlobalDomain KeyRepeat -int 2
run defaults write NSGlobalDomain InitialKeyRepeat -int 15
run defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# ── Finder ──────────────────────────────────────────────────────────
run defaults write NSGlobalDomain AppleShowAllExtensions -bool true
run defaults write com.apple.finder AppleShowAllFiles -bool true
run defaults write com.apple.finder ShowPathbar -bool true
run defaults write com.apple.finder ShowStatusBar -bool true
run defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"  # list view
# Do not create .DS_Store on network or USB volumes
run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
run defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ── Screenshots ─────────────────────────────────────────────────────
run mkdir -p "$HOME/Screenshots"
run defaults write com.apple.screencapture location -string "$HOME/Screenshots"
run defaults write com.apple.screencapture disable-shadow -bool true
run defaults write com.apple.screencapture type -string png

# Apply changes by restarting the affected UI agents
run killall Finder || true
run killall SystemUIServer || true

if $DRY_RUN; then
  command echo -e "\e[1;36m [dry-run] macOS defaults preview completed \e[m"
else
  command echo -e "\e[1;36m macOS defaults applied. Some changes need a re-login. \e[m"
fi
