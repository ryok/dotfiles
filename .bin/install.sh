#!/usr/bin/env bash
set -ue -o pipefail

DRY_RUN=false

helpmsg() {
  command echo "Usage: $0 [--help | -h] [--dry-run | -n]" 0>&2
  command echo ""
}

# Run or print a command depending on DRY_RUN
run() {
  if $DRY_RUN; then
    command echo "[dry-run] $*"
  else
    "$@"
  fi
}

link_to_homedir() {
  command echo "backup old dotfiles..."
  if [ ! -d "$HOME/.dotbackup" ];then
    command echo "$HOME/.dotbackup not found. Auto Make it"
    run command mkdir "$HOME/.dotbackup"
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
            run command mkdir -p "$HOME/.claude"
            for cf in "$app"/*; do
              [[ -f "$cf" ]] || continue
              local cfname
              cfname=$(basename "$cf")
              run command ln -snf "$cf" "$HOME/.claude/$cfname"
            done
            if [[ -d "$app/skills" ]]; then
              run command mkdir -p "$HOME/.claude/skills"
              for skill in "$app/skills"/*/; do
                [[ -d "$skill" ]] || continue
                local skillname
                skillname=$(basename "$skill")
                run command ln -snf "$skill" "$HOME/.claude/skills/$skillname"
              done
            fi
          fi
          # Gemini CLI / OpenAI Codex: .config/<app>/ → ~/.<app>/ にファイル単位でリンク
          if [[ "$appname" == "gemini" ]] || [[ "$appname" == "codex" ]]; then
            run command mkdir -p "$HOME/.$appname"
            for cf in "$app"/*; do
              [[ -f "$cf" ]] || continue
              local cfname
              cfname=$(basename "$cf")
              run command ln -snf "$cf" "$HOME/.$appname/$cfname"
            done
          fi
        done
        continue
      fi
      if [[ -L "$HOME/$name" ]];then
        run command rm -f "$HOME/$name"
      fi
      if [[ -e "$HOME/$name" ]];then
        run command mv "$HOME/$name" "$HOME/.dotbackup"
      fi
      run command ln -snf "$f" "$HOME"
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
      exit 1
      ;;
    *)
      ;;
  esac
  shift
done

link_to_homedir
command echo -e "\e[1;36m Install completed!!!! \e[m"
