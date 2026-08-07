#!/usr/bin/env bash
set -ue -o pipefail

DRY_RUN=false

helpmsg() {
  command echo "Usage: $0 [--help | -h] [--dry-run | -n] [--debug | -d]" 1>&2
  command echo "" 1>&2
  command echo "  -n, --dry-run  Print the actions without changing anything" 1>&2
  command echo "  -d, --debug    Run with 'set -x' tracing enabled" 1>&2
  command echo "  -h, --help     Show this help" 1>&2
}

# Run or print a command depending on DRY_RUN
run() {
  if $DRY_RUN; then
    command echo "[dry-run] $*"
  else
    "$@"
  fi
}

# Symlink $1 into place at $2, backing up any existing real file first.
# Existing symlinks are removed; existing regular files/dirs are moved to
# ~/.dotbackup/ under a flattened name so entries from different apps
# (e.g. .claude/settings.json vs .gemini/settings.json) never collide.
link_file() {
  local src=$1 dest=$2
  if [[ -L "$dest" ]]; then
    run rm -f "$dest"
  elif [[ -e "$dest" ]]; then
    local rel=${dest#"$HOME"/}
    run mv "$dest" "$HOME/.dotbackup/${rel//\//_}"
  fi
  run ln -snf "$src" "$dest"
}

link_to_homedir() {
  command echo "backup old dotfiles..."
  if [ ! -d "$HOME/.dotbackup" ];then
    command echo "$HOME/.dotbackup not found. Auto Make it"
    run mkdir "$HOME/.dotbackup"
  fi

  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  local dotdir
  dotdir=$(dirname "${script_dir}")
  if [[ "$HOME" != "$dotdir" ]];then
    for f in "$dotdir"/.??*; do
      local name
      name=$(basename "$f")
      [[ "$name" == ".git" ]] && continue
      [[ "$name" == ".claude" ]] && continue  # managed via .config/claude/
      # .config/ はサブディレクトリ単位でリンクする
      # (ディレクトリごとリンクするとセッションデータ等が消えるため)
      if [[ "$name" == ".config" ]]; then
        for app in "$f"/*/; do
          [[ -d "$app" ]] || continue
          local appname
          appname=$(basename "$app")
          # Claude Code: .config/claude/ → ~/.claude/ にリンク
          if [[ "$appname" == "claude" ]]; then
            run mkdir -p "$HOME/.claude"
            for cf in "$app"/*; do
              [[ -f "$cf" ]] || continue
              local cfname
              cfname=$(basename "$cf")
              link_file "$cf" "$HOME/.claude/$cfname"
            done
            if [[ -d "$app/skills" ]]; then
              run mkdir -p "$HOME/.claude/skills"
              for skill in "$app/skills"/*/; do
                [[ -d "$skill" ]] || continue
                local skillname
                skillname=$(basename "$skill")
                link_file "$skill" "$HOME/.claude/skills/$skillname"
              done
            fi

            # npm 同梱スキルをリンク（vendor しない）: 供給源は npm パッケージ本体
            # （Brewfile でインストール済み）。パッケージ更新に自動追従する。
            local npm_root
            npm_root="$(npm root -g 2>/dev/null || true)"
            if [[ -n "$npm_root" && -d "$npm_root/agent-browser/skills/agent-browser" ]]; then
              run mkdir -p "$HOME/.claude/skills"
              link_file "$npm_root/agent-browser/skills/agent-browser" "$HOME/.claude/skills/agent-browser"
            fi

            # ホスト固有の上書き: .config/claude/hosts/<hostname>/ が現在の
            # ホストと一致する場合のみ、その中のファイルを ~/.claude/ へリンク
            # する。共有ファイル (上の for ループ) の後に実行するので、同名なら
            # ホスト版が優先される (例: p-team-17 の GPU 運用ノート付き CLAUDE.md
            # が共有スタブを上書き。@RTK.md は共有 ~/.claude/RTK.md を解決する)。
            # 他ホスト (macOS 等) では一致ディレクトリが無いため何もしない。
            # hostname コマンドが無い環境でも落ちないよう $HOSTNAME を優先し
            # uname -n をフォールバックにする。
            local host_name="${HOSTNAME:-}"
            [[ -n "$host_name" ]] || host_name="$(uname -n 2>/dev/null || echo unknown)"
            local host_dir="$app/hosts/${host_name%%.*}"
            if [[ -d "$host_dir" ]]; then
              for hf in "$host_dir"/*; do
                [[ -f "$hf" ]] || continue
                local hfname
                hfname=$(basename "$hf")
                link_file "$hf" "$HOME/.claude/$hfname"
              done
            fi
          fi
          # Gemini CLI / OpenAI Codex: .config/<app>/ → ~/.<app>/ にファイル単位でリンク
          if [[ "$appname" == "gemini" ]] || [[ "$appname" == "codex" ]]; then
            run mkdir -p "$HOME/.$appname"
            for cf in "$app"/*; do
              [[ -f "$cf" ]] || continue
              local cfname
              cfname=$(basename "$cf")
              link_file "$cf" "$HOME/.$appname/$cfname"
            done
            if [[ "$appname" == "codex" ]] && [[ -d "$app/skills" ]]; then
              run mkdir -p "$HOME/.codex/skills"
              for skill in "$app/skills"/*/; do
                [[ -d "$skill" ]] || continue
                local skillname
                skillname=$(basename "$skill")
                link_file "$skill" "$HOME/.codex/skills/$skillname"
              done
            fi
          fi
        done
        continue
      fi
      link_file "$f" "$HOME/$name"
    done
  else
    command echo "same install src dest"
  fi
}

while [ $# -gt 0 ];do
  case ${1} in
    --debug|-d)
      set -uex
      ;;
    --dry-run|-n)
      DRY_RUN=true
      ;;
    --help|-h)
      helpmsg
      exit 0
      ;;
    *)
      command echo "Unknown option: ${1}" 1>&2
      helpmsg
      exit 1
      ;;
  esac
  shift
done

link_to_homedir
if $DRY_RUN; then
  command echo -e "\e[1;36m [dry-run] Install preview completed \e[m"
else
  command echo -e "\e[1;36m Install completed!!!! \e[m"
fi
