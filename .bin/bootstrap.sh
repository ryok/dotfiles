#!/usr/bin/env bash
# bootstrap.sh — クリーンインストール環境を一括で再現するためのセットアップ。
#
#   1. oh-my-zsh                     (未導入なら unattended install)
#   2. 依存ツール:
#        - Homebrew があれば  ->  brew bundle (Brewfile)
#        - Homebrew が無い Linux ->  Nix: flake.nix の dotfiles-cli を nix profile に導入
#          (共有 GPU サーバ等を想定。バージョンとハッシュは flake.lock が固定する)
#   3. Chrome for Testing            (agent-browser install)
#   4. install.sh                    (dotfiles を $HOME へシンボリックリンク)
#
# macOS / Linux (x86_64, arm64) 対応。ホスト固有の処理はガードして
# macOS でのインストール時に副作用が出ないようにしている。
#
# 環境変数で挙動を上書き可能:
#   BOOTSTRAP_SKIP_BROWSER=true          Chrome for Testing (~177MB) の導入を省略
#   BOOTSTRAP_FORCE=true                 oh-my-zsh / Chrome for Testing を再インストール
#   BOOTSTRAP_NO_BREW=true               Homebrew があっても Nix 経路を使う (Linux のみ)
set -ueo pipefail

SKIP_BROWSER="${BOOTSTRAP_SKIP_BROWSER:-false}"
FORCE="${BOOTSTRAP_FORCE:-false}"
NO_BREW="${BOOTSTRAP_NO_BREW:-false}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# nix profile の要素名。flake.nix の packages.<system>.dotfiles-cli と一致させる。
NIX_PROFILE_ELEMENT="dotfiles-cli"
NIX_PROFILE_BIN="$HOME/.nix-profile/bin"

log()  { command printf '\033[1;36m[bootstrap]\033[m %s\n' "$*"; }
warn() { command printf '\033[1;33m[bootstrap]\033[m %s\n' "$*" >&2; }
die()  { command printf '\033[1;31m[bootstrap]\033[m %s\n' "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"; }

usage() {
  command cat >&2 <<'EOF'
Usage: bootstrap.sh [--skip-browser] [--force] [--no-brew] [--help]

  --skip-browser   Chrome for Testing (~177MB) の導入をスキップ
  --force          oh-my-zsh / Chrome for Testing を再インストール
  --no-brew        Homebrew があっても Nix 経路を使う (Linux のみ)
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

# ---- 1. oh-my-zsh (brew / Nix のどちらでも入らないので常にここで面倒を見る) ----
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

# ---- 2b. Nix 経路 (Homebrew の無い Linux ホスト) ----
# nix-command / flakes は公式インストーラの既定では無効なので、呼び出しごとに有効化する。
nix_cmd() {
  nix --extra-experimental-features 'nix-command flakes' "$@"
}

# この bootstrap を対話シェル以外から呼ぶと、/etc/profile.d の Nix 設定が読まれて
# おらず nix が PATH に無いことがある。インストーラが置く既知の場所から読み込む。
load_nix_env() {
  command -v nix >/dev/null 2>&1 && return 0
  local f
  for f in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
           "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
    [[ -r "$f" ]] || continue
    # 外部スクリプトは未定義変数を参照しうるので、読み込む間だけ -u を外す
    set +u
    # shellcheck disable=SC1090  # Nix インストーラが配置するファイルで、パスは実行時に決まる
    . "$f"
    set -u
    command -v nix >/dev/null 2>&1 && return 0
  done
  return 1
}

install_via_nix() {
  local flake="$REPO_DIR#$NIX_PROFILE_ELEMENT" list
  # 導入済みかは要素名で判定する。flake.nix で属性名を固定しているので、repo の
  # 置き場所 (= flake のディレクトリ名) に左右されない。
  # `nix ... | grep -q` にしないのは、grep が一致した時点で閉じると nix が SIGPIPE
  # で落ち、pipefail 下では「未導入」と誤判定するため。先に全部受け取ってから見る。
  list="$(nix_cmd profile list --json 2>/dev/null || true)"
  if [[ "$list" == *"\"$NIX_PROFILE_ELEMENT\""* ]]; then
    # 再度 add しても "already added" で何も起きないので、flake.lock の更新を
    # 反映するには upgrade が要る。
    log "Nix: $NIX_PROFILE_ELEMENT は導入済み → upgrade (flake.lock の内容に揃える)"
    nix_cmd profile upgrade "$NIX_PROFILE_ELEMENT" || die "nix profile upgrade に失敗"
  else
    log "Nix: $flake を nix profile に追加"
    # 新しい Nix では install が add に改名された (install は非推奨の別名)。
    # 古い Nix には add が無いので、使えるほうを選ぶ。
    if nix_cmd profile add --help >/dev/null 2>&1; then
      nix_cmd profile add "$flake" || die "nix profile add に失敗"
    else
      nix_cmd profile install "$flake" || die "nix profile install に失敗"
    fi
  fi
  # 後続の agent-browser install が、同じプロセス内で新しいバイナリを見つけられるように。
  # 新しいシェルでは .zshenv が Nix の設定を読み込むので、この PATH 変更は不要。
  export PATH="$NIX_PROFILE_BIN:$PATH"
}

# ---- 3. Chrome for Testing + ホスト固有設定 (agent-browser が居れば) ----
setup_agent_browser_runtime() {
  local ab
  ab="$(command -v agent-browser 2>/dev/null || true)"
  [[ -z "$ab" && -x "$NIX_PROFILE_BIN/agent-browser" ]] && ab="$NIX_PROFILE_BIN/agent-browser"
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
  detect_platform
  log "platform: ${OS}-${ARCH}  host: ${HOSTNAME:-$(uname -n 2>/dev/null || echo unknown)}"

  install_oh_my_zsh

  if [[ "$NO_BREW" != true ]] && command -v brew >/dev/null 2>&1; then
    install_via_brew
  elif [[ "$OS" == linux ]] && load_nix_env; then
    install_via_nix
  elif [[ "$OS" == linux ]]; then
    die "Homebrew も Nix も見つからない。Nix を入れてから再実行すること:
    sh <(curl -L https://nixos.org/nix/install) --daemon
  (共有ホストでは /nix・nixbld ユーザー・nix-daemon がシステム全体に入るので、
   他の利用者に一言伝えてから入れること)"
  else
    die "macOS では Homebrew が必要 (https://brew.sh)"
  fi

  setup_agent_browser_runtime

  log "linking dotfiles via install.sh"
  "$SCRIPT_DIR/install.sh"

  log "bootstrap complete 🎉  (settings.json のフック反映には Claude Code の再起動が必要)"
}

main "$@"
