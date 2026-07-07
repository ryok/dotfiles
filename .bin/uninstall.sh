#!/usr/bin/env bash
set -ue -o pipefail

# Reverse of install.sh: remove the symlinks this repo created in $HOME and,
# where install.sh saved a backup, restore it from ~/.dotbackup/.
# Only symlinks that point *inside* this repo are touched — real files and
# symlinks created by anything else are left untouched.

DRY_RUN=false
DOTDIR=""

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

# Remove the symlink at $1 only if it points into this repo, then restore any
# backup install.sh left for it (matching link_file's flattened backup name).
unlink_file() {
  local dest=$1
  if [[ ! -L "$dest" ]]; then
    return 0  # not a symlink → we did not create it
  fi
  local target
  target=$(readlink "$dest")
  case "$target" in
    "$DOTDIR"/*) run rm -f "$dest" ;;
    *) return 0 ;;  # symlink to somewhere else → not ours, leave it
  esac
  local rel=${dest#"$HOME"/}
  local backup="$HOME/.dotbackup/${rel//\//_}"
  if [[ -e "$backup" ]]; then
    run mv "$backup" "$dest"
  fi
}

unlink_from_homedir() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  DOTDIR=$(dirname "${script_dir}")

  for f in "$DOTDIR"/.??*; do
    local name
    name=$(basename "$f")
    [[ "$name" == ".git" ]] && continue
    [[ "$name" == ".claude" ]] && continue  # managed via .config/claude/
    if [[ "$name" == ".config" ]]; then
      for app in "$f"/*/; do
        [[ -d "$app" ]] || continue
        local appname
        appname=$(basename "$app")
        if [[ "$appname" == "claude" ]]; then
          for cf in "$app"/*; do
            [[ -f "$cf" ]] || continue
            unlink_file "$HOME/.claude/$(basename "$cf")"
          done
          if [[ -d "$app/skills" ]]; then
            for skill in "$app/skills"/*/; do
              [[ -d "$skill" ]] || continue
              unlink_file "$HOME/.claude/skills/$(basename "$skill")"
            done
          fi
        fi
        if [[ "$appname" == "gemini" ]] || [[ "$appname" == "codex" ]]; then
          for cf in "$app"/*; do
            [[ -f "$cf" ]] || continue
            unlink_file "$HOME/.$appname/$(basename "$cf")"
          done
          if [[ "$appname" == "codex" ]] && [[ -d "$app/skills" ]]; then
            for skill in "$app/skills"/*/; do
              [[ -d "$skill" ]] || continue
              unlink_file "$HOME/.codex/skills/$(basename "$skill")"
            done
          fi
        fi
      done
      continue
    fi
    unlink_file "$HOME/$name"
  done
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

unlink_from_homedir
if $DRY_RUN; then
  command echo -e "\e[1;36m [dry-run] Uninstall preview completed \e[m"
else
  command echo -e "\e[1;36m Uninstall completed!!!! \e[m"
fi
