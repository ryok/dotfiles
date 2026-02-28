#!/usr/bin/env bash
set -ue

helpmsg() {
  command echo "Usage: $0 [--help | -h]" 0>&2
  command echo ""
}

link_to_homedir() {
  command echo "backup old dotfiles..."
  if [ ! -d "$HOME/.dotbackup" ];then
    command echo "$HOME/.dotbackup not found. Auto Make it"
    command mkdir "$HOME/.dotbackup"
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
      # ディレクトリ内の個別ファイルをリンクする対象
      # (ディレクトリごとリンクするとセッションデータ等が消えるため)
      if [[ "$name" == ".claude" ]]; then
        command mkdir -p "$HOME/.claude"
        # ファイルを個別にリンク
        for cf in "$f"/*; do
          [[ -f "$cf" ]] || continue
          local cfname
          cfname=$(basename "$cf")
          command ln -snf "$cf" "$HOME/.claude/$cfname"
        done
        # skills 内のディレクトリをリンク
        if [[ -d "$f/skills" ]]; then
          command mkdir -p "$HOME/.claude/skills"
          for skill in "$f/skills"/*/; do
            [[ -d "$skill" ]] || continue
            local skillname
            skillname=$(basename "$skill")
            command ln -snf "$skill" "$HOME/.claude/skills/$skillname"
          done
        fi
        continue
      fi
      if [[ -L "$HOME/$name" ]];then
        command rm -f "$HOME/$name"
      fi
      if [[ -e "$HOME/$name" ]];then
        command mv "$HOME/$name" "$HOME/.dotbackup"
      fi
      command ln -snf "$f" "$HOME"
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
