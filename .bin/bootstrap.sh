#!/usr/bin/env bash
# bootstrap.sh — クリーンインストール環境を一括で再現するためのセットアップ。
#
#   1. oh-my-zsh                     (未導入なら unattended install)
#   2. 依存ツール:
#        - Homebrew があれば  ->  brew bundle (Brewfile: rtk / agent-browser / node ...)
#        - Homebrew が無ければ ->  GitHub release から rtk / agent-browser を直接 DL
#          (brew/node の無い制約ホスト = 共有 GPU サーバ等を想定)
#   3. Chrome for Testing            (agent-browser install)
#   4. install.sh                    (dotfiles を $HOME へシンボリックリンク)
#
# macOS / Linux (x86_64, arm64) 対応。ホスト固有の処理はガードして
# macOS でのインストール時に副作用が出ないようにしている。
#
# 環境変数で挙動を上書き可能:
#   RTK_VERSION / AGENT_BROWSER_VERSION  brewless 経路のピン留めバージョン
#   BOOTSTRAP_SKIP_BROWSER=true          Chrome for Testing (~177MB) の導入を省略
#   BOOTSTRAP_FORCE=true                 既存でも再インストール
#   BOOTSTRAP_NO_BREW=true               Homebrew があっても brewless 経路を使う
#   BIN_DIR                              brewless 経路のバイナリ配置先 (既定: ~/.local/bin)
set -ueo pipefail

RTK_VERSION="${RTK_VERSION:-0.43.0}"
AGENT_BROWSER_VERSION="${AGENT_BROWSER_VERSION:-0.31.1}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
SKIP_BROWSER="${BOOTSTRAP_SKIP_BROWSER:-false}"
FORCE="${BOOTSTRAP_FORCE:-false}"
NO_BREW="${BOOTSTRAP_NO_BREW:-false}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

log()  { command printf '\033[1;36m[bootstrap]\033[m %s\n' "$*"; }
warn() { command printf '\033[1;33m[bootstrap]\033[m %s\n' "$*" >&2; }
die()  { command printf '\033[1;31m[bootstrap]\033[m %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }

usage() {
  command cat >&2 <<'EOF'
Usage: bootstrap.sh [--skip-browser] [--force] [--no-brew] [--help]

  --skip-browser   Chrome for Testing (~177MB) の導入をスキップ
  --force          既存バイナリ / oh-my-zsh でも再インストール
  --no-brew        Homebrew があっても GitHub-release 経路を使う
  --help           このヘルプを表示
EOF
}

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os" in
    Linux)  OS=linux ;;
    Darwin) OS=darwin ;;
    *) die "unsupported OS: $os" ;;
  esac
  case "$arch" in
    x86_64|amd64)  ARCH=x86_64 ;;
    arm64|aarch64) ARCH=arm64 ;;
    *) die "unsupported arch: $arch" ;;
  esac
}

sha_check() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum -c "$1"
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 -c "$1"
  else
    die "no sha256 tool (sha256sum/shasum) available"
  fi
}

rtk_asset() {
  case "$OS-$ARCH" in
    linux-x86_64)  echo "rtk-x86_64-unknown-linux-musl.tar.gz" ;;
    linux-arm64)   echo "rtk-aarch64-unknown-linux-gnu.tar.gz" ;;
    darwin-x86_64) echo "rtk-x86_64-apple-darwin.tar.gz" ;;
    darwin-arm64)  echo "rtk-aarch64-apple-darwin.tar.gz" ;;
    *) die "no rtk asset for $OS-$ARCH" ;;
  esac
}

agent_browser_asset() {
  case "$OS-$ARCH" in
    linux-x86_64)  echo "agent-browser-linux-x64" ;;
    linux-arm64)   echo "agent-browser-linux-arm64" ;;
    darwin-x86_64) echo "agent-browser-darwin-x64" ;;
    darwin-arm64)  echo "agent-browser-darwin-arm64" ;;
    *) die "no agent-browser asset for $OS-$ARCH" ;;
  esac
}

# ---- 1. oh-my-zsh (brew では入らないので常にここで面倒を見る) ----
install_oh_my_zsh() {
  if [[ "$FORCE" != true && -d "$HOME/.oh-my-zsh" ]]; then
    log "oh-my-zsh already installed — skip"
    return
  fi
  log "installing oh-my-zsh (unattended)"
  # RUNZSH=no: 完了後に zsh を起動しない / CHSH=no: ログインシェルを変更しない
  # KEEP_ZSHRC=yes: 後で install.sh がリンクする .zshrc を上書きさせない
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
    || warn "oh-my-zsh install に失敗 (後で手動実行可)"
}

# ---- 2a. brew 経路 ----
install_via_brew() {
  log "Homebrew detected → brew bundle (--file=$REPO_DIR/Brewfile)"
  brew bundle --file="$REPO_DIR/Brewfile" || warn "brew bundle に一部失敗 (ログ参照)"
}

# ---- 2b. brewless 経路: rtk (checksum 検証あり) ----
install_rtk_release() {
  if [[ "$FORCE" != true ]] && command -v rtk >/dev/null 2>&1; then
    log "rtk already installed ($(rtk --version 2>/dev/null || echo unknown)) — skip"
    return
  fi
  local asset base tmp bin
  asset="$(rtk_asset)"
  base="https://github.com/rtk-ai/rtk/releases/download/v${RTK_VERSION}"
  tmp="$(mktemp -d)"
  log "downloading rtk v${RTK_VERSION} ($asset)"
  curl -fsSL "$base/$asset" -o "$tmp/$asset"
  curl -fsSL "$base/checksums.txt" -o "$tmp/checksums.txt"
  log "verifying checksum"
  grep -F "$asset" "$tmp/checksums.txt" > "$tmp/checksum.line" \
    || die "asset '$asset' not found in checksums.txt"
  ( cd "$tmp" && sha_check "checksum.line" ) || die "rtk checksum verification failed"
  tar -xzf "$tmp/$asset" -C "$tmp"
  if [[ -f "$tmp/rtk" ]]; then
    bin="$tmp/rtk"
  else
    bin="$(find "$tmp" -type f -name rtk 2>/dev/null | head -n1 || true)"
  fi
  [[ -n "$bin" && -f "$bin" ]] || die "rtk binary not found in archive"
  mkdir -p "$BIN_DIR"
  install -m 0755 "$bin" "$BIN_DIR/rtk"
  log "rtk installed → $BIN_DIR/rtk"
}

# ---- 2b. brewless 経路: agent-browser (checksums 資産が無いため検証なし) ----
install_agent_browser_release() {
  if [[ "$FORCE" != true ]] && command -v agent-browser >/dev/null 2>&1; then
    log "agent-browser already installed — skip binary"
    return
  fi
  local asset url
  asset="$(agent_browser_asset)"
  url="https://github.com/vercel-labs/agent-browser/releases/download/v${AGENT_BROWSER_VERSION}/$asset"
  log "downloading agent-browser v${AGENT_BROWSER_VERSION} ($asset)"
  mkdir -p "$BIN_DIR"
  curl -fsSL "$url" -o "$BIN_DIR/agent-browser"
  chmod 0755 "$BIN_DIR/agent-browser"
  log "agent-browser installed → $BIN_DIR/agent-browser"
}

# ---- 3. Chrome for Testing + ホスト固有設定 (agent-browser が居れば) ----
setup_agent_browser_runtime() {
  local ab
  ab="$(command -v agent-browser 2>/dev/null || true)"
  [[ -z "$ab" && -x "$BIN_DIR/agent-browser" ]] && ab="$BIN_DIR/agent-browser"
  if [[ -z "$ab" ]]; then
    warn "agent-browser が見つからない — Chrome for Testing の導入をスキップ"
    return
  fi

  if [[ "$SKIP_BROWSER" == true ]]; then
    warn "Chrome for Testing の導入をスキップ (--skip-browser)"
  elif [[ "$FORCE" != true && -d "$HOME/.agent-browser/browsers" ]]; then
    log "Chrome for Testing already present — skip"
  else
    log "installing Chrome for Testing via agent-browser (~177MB)"
    "$ab" install || warn "agent-browser install に失敗 (後で手動実行可)"
  fi

  # ホスト固有: --no-sandbox / --disable-gpu は Linux GPU サーバの制約なので
  # Linux のときだけ書き込む (macOS には不要 & GPU 制約は当ホスト固有)。
  if [[ "$OS" == linux ]]; then
    mkdir -p "$HOME/.agent-browser"
    if [[ ! -f "$HOME/.agent-browser/config.json" || "$FORCE" == true ]]; then
      command printf '%s\n' '{"args": "--no-sandbox,--disable-gpu"}' \
        > "$HOME/.agent-browser/config.json"
      log "wrote ~/.agent-browser/config.json (--no-sandbox,--disable-gpu)"
    fi
  fi
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --skip-browser) SKIP_BROWSER=true ;;
      --force)        FORCE=true ;;
      --no-brew)      NO_BREW=true ;;
      --help|-h)      usage; exit 0 ;;
      *)              warn "unknown option: $1"; usage; exit 1 ;;
    esac
    shift
  done

  need curl
  need tar
  detect_platform
  log "platform: ${OS}-${ARCH}  host: ${HOSTNAME:-$(uname -n 2>/dev/null || echo unknown)}"

  install_oh_my_zsh

  if [[ "$NO_BREW" != true ]] && command -v brew >/dev/null 2>&1; then
    install_via_brew
  else
    log "no Homebrew (or --no-brew) → GitHub-release install for rtk / agent-browser"
    install_rtk_release
    install_agent_browser_release
  fi

  setup_agent_browser_runtime

  log "linking dotfiles via install.sh"
  "$SCRIPT_DIR/install.sh"

  case ":$PATH:" in
    *":$BIN_DIR:"*) : ;;
    *) warn "$BIN_DIR が PATH に無い — ~/.zprofile 等に追加すると rtk/agent-browser が解決される" ;;
  esac

  log "bootstrap complete 🎉  (settings.json のフック反映には Claude Code の再起動が必要)"
}

main "$@"
