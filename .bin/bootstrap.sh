#!/usr/bin/env bash
# bootstrap.sh — クリーンインストール環境を一括で再現するためのセットアップ。
#
#   1. oh-my-zsh                     (未導入なら unattended install)
#   2. 依存ツール:
#        - Homebrew があれば  ->  brew bundle (Brewfile: rtk / agent-browser / node ...)
#        - Homebrew が無ければ ->  GitHub release から rtk / agent-browser / herdr を
#          直接 DL (brew/node の無い制約ホスト = 共有 GPU サーバ等を想定)
#   3. Chrome for Testing            (agent-browser install)
#   4. install.sh                    (dotfiles を $HOME へシンボリックリンク)
#
# macOS / Linux (x86_64, arm64) 対応。ホスト固有の処理はガードして
# macOS でのインストール時に副作用が出ないようにしている。
#
# 環境変数で挙動を上書き可能:
#   RTK_VERSION / AGENT_BROWSER_VERSION / HERDR_VERSION
#                                        brewless 経路のピン留めバージョン
#   BOOTSTRAP_SKIP_BROWSER=true          Chrome for Testing (~177MB) の導入を省略
#   BOOTSTRAP_FORCE=true                 既存でも再インストール
#   BOOTSTRAP_NO_BREW=true               Homebrew があっても brewless 経路を使う
#   BIN_DIR                              brewless 経路のバイナリ配置先 (既定: ~/.local/bin)
set -ueo pipefail

RTK_VERSION="${RTK_VERSION:-0.43.0}"
AGENT_BROWSER_VERSION="${AGENT_BROWSER_VERSION:-0.31.1}"
HERDR_VERSION="${HERDR_VERSION:-0.8.0}"
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

# $1 の URL を取得し SHA-256 ($2) を検証してから $3 へ実行可能ファイルとして
# 配置する ($4 は一時ファイル名とログに使う表示名)。
#
# 一時ファイルを宛先と同じディレクトリに作るのが要点。curl の出力先を宛先に
# 直接指定すると転送開始時に既存ファイルが切り詰められ、途中で失敗すると壊れた
# 実行ファイルが残る — 次回の実行では command -v がそれを拾って「導入済み」と
# 誤判定してしまう。同一ディレクトリなら mv がアトミックになり、検証を通った
# ものだけが宛先に現れる。
install_verified_binary() {
  local url=$1 want=$2 dest=$3 name=$4
  local dir tmp sumfile
  dir="$(dirname "$dest")"
  mkdir -p "$dir"
  tmp="$(mktemp "$dir/.${name}.XXXXXX")"
  if ! curl -fsSL "$url" -o "$tmp"; then
    rm -f "$tmp"
    die "failed to download $name: $url"
  fi
  log "verifying checksum"
  sumfile="$tmp.sha256"
  command printf '%s  %s\n' "$want" "$(basename "$tmp")" > "$sumfile"
  if ! ( cd "$dir" && sha_check "$(basename "$sumfile")" ); then
    rm -f "$tmp" "$sumfile"
    die "$name checksum verification failed"
  fi
  rm -f "$sumfile"
  chmod 0755 "$tmp"
  mv -f "$tmp" "$dest"
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

herdr_asset() {
  case "$OS-$ARCH" in
    linux-x86_64)  echo "herdr-linux-x86_64" ;;
    linux-arm64)   echo "herdr-linux-aarch64" ;;
    darwin-x86_64) echo "herdr-macos-x86_64" ;;
    darwin-arm64)  echo "herdr-macos-aarch64" ;;
    *) die "no herdr asset for $OS-$ARCH" ;;
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

# ---- 2b. brewless 経路: agent-browser ----
# herdr と同様、checksums.txt が配布されていないためレビュー済みの SHA-256 を
# ピン留めして検証する。AGENT_BROWSER_VERSION を上げるときは以下も併せて更新:
#   gh api repos/vercel-labs/agent-browser/releases/tags/v<ver> \
#     --jq '.assets[] | [.name, .digest] | @tsv'
agent_browser_sha256() {
  case "${AGENT_BROWSER_VERSION}:$1" in
    0.31.1:agent-browser-linux-x64)    echo "72c13bcfd2fd6b188325bdd23c646d06ca69a1a964a9cdaab37e4ff8f47aa5c6" ;;
    0.31.1:agent-browser-linux-arm64)  echo "5f80bff26b25e9a9f712be64dda1f8ea2b22213a1a07c0f97ea8f9f226c2894b" ;;
    0.31.1:agent-browser-darwin-x64)   echo "05aa3e2ed3550e06fb3eb7423a1cef0d9d6031c4d6a8835b9dbe033baf83ef6d" ;;
    0.31.1:agent-browser-darwin-arm64) echo "fd7acd17b3071ff7f75a03c1ecd30501959d9c2d063bdaa05adb6f77abf2a7bf" ;;
    *) echo "" ;;
  esac
}

install_agent_browser_release() {
  if [[ "$FORCE" != true ]] && command -v agent-browser >/dev/null 2>&1; then
    log "agent-browser already installed — skip binary"
    return
  fi
  local asset url want
  asset="$(agent_browser_asset)"
  want="$(agent_browser_sha256 "$asset")"
  [[ -n "$want" ]] \
    || die "no pinned sha256 for agent-browser v${AGENT_BROWSER_VERSION} ($asset) — bootstrap.sh の agent_browser_sha256() を更新すること"
  url="https://github.com/vercel-labs/agent-browser/releases/download/v${AGENT_BROWSER_VERSION}/$asset"
  log "downloading agent-browser v${AGENT_BROWSER_VERSION} ($asset)"
  install_verified_binary "$url" "$want" "$BIN_DIR/agent-browser" agent-browser
  log "agent-browser installed → $BIN_DIR/agent-browser"
}

# ---- 2b. brewless 経路: herdr ----
# herdr は rtk と違い checksums.txt を配布していないため、レビュー済みの
# SHA-256 をここにピン留めして検証する。実行時に GitHub API から digest を
# 取れはするが、バイナリと同じ供給元なので改ざん検知にはならない (差し替え
# られれば digest も一緒に変わる) — ピン留めして初めて意味を持つ。
# HERDR_VERSION を上げるときは以下も併せて更新すること:
#   gh api repos/herdrdev/herdr/releases/tags/v<ver> \
#     --jq '.assets[] | [.name, .digest] | @tsv'
herdr_sha256() {
  case "${HERDR_VERSION}:$1" in
    0.8.0:herdr-linux-x86_64)  echo "b872ea7e40fa2cb17e857ac9b62b1bf26db7b403c622f5d2f3f5b35f6e9acd28" ;;
    0.8.0:herdr-linux-aarch64) echo "f647ac66468d9efbc642fe534fb284468f0aea60641606fc008dfc0d82a3ca87" ;;
    0.8.0:herdr-macos-x86_64)  echo "77cb5afd6c8fcaaaf3bc28e474ec01c209331ad08094e20d7f8aa9b0bb78d649" ;;
    0.8.0:herdr-macos-aarch64) echo "d53a9f93fccfdfcc55632927bf51002f5add0aa7990bcdf508ffbd84ac658178" ;;
    *) echo "" ;;
  esac
}

install_herdr_release() {
  if [[ "$FORCE" != true ]] && command -v herdr >/dev/null 2>&1; then
    log "herdr already installed ($(herdr --version 2>/dev/null || echo unknown)) — skip"
    return
  fi
  local asset url want
  asset="$(herdr_asset)"
  want="$(herdr_sha256 "$asset")"
  [[ -n "$want" ]] \
    || die "no pinned sha256 for herdr v${HERDR_VERSION} ($asset) — bootstrap.sh の herdr_sha256() を更新すること"
  url="https://github.com/herdrdev/herdr/releases/download/v${HERDR_VERSION}/$asset"
  log "downloading herdr v${HERDR_VERSION} ($asset)"
  install_verified_binary "$url" "$want" "$BIN_DIR/herdr" herdr
  log "herdr installed → $BIN_DIR/herdr"
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
    log "no Homebrew (or --no-brew) → GitHub-release install for rtk / agent-browser / herdr"
    install_rtk_release
    install_agent_browser_release
    install_herdr_release
  fi

  setup_agent_browser_runtime

  log "linking dotfiles via install.sh"
  "$SCRIPT_DIR/install.sh"

  case ":$PATH:" in
    *":$BIN_DIR:"*) : ;;
    *) warn "$BIN_DIR が PATH に無い — ~/.zprofile 等に追加すると rtk/agent-browser/herdr が解決される" ;;
  esac

  log "bootstrap complete 🎉  (settings.json のフック反映には Claude Code の再起動が必要)"
}

main "$@"
