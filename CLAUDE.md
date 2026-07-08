# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository for macOS/Linux. Dotfiles are symlinked into `$HOME` via the install script. The repo uses a whitelist-based `.gitignore` — everything is ignored by default, and tracked files are explicitly un-ignored.

## Key Commands

- **Install dotfiles:** `.bin/install.sh` — backs up existing dotfiles to `~/.dotbackup/`, then symlinks tracked entries into `$HOME`.
- **Uninstall dotfiles:** `.bin/uninstall.sh` — removes only the symlinks that point into this repo and restores any matching `~/.dotbackup/` backup. Both scripts accept `--dry-run` (`-n`) and `--debug` (`-d`).
- **Preview without changes:** `.bin/install.sh --dry-run` (`-n`) — prints every action without touching the filesystem.
- **Install with debug:** `.bin/install.sh --debug` (`-d`) — runs with `set -x` tracing.
- **Install dependencies:** `brew bundle --file=./Brewfile` — installs the CLI toolchain (`Brewfile` is curated; VSCode/Go/local packages are intentionally excluded).
- **Apply macOS system defaults:** `.bin/macos-defaults.sh` — keyboard/Finder/screenshot settings. Opt-in (not run by install.sh), macOS-only, supports `--dry-run`/`--debug`.
- **CI:** GitHub Actions (`.github/workflows/check.yml`) runs three jobs: `ubuntu` (install/uninstall smoke tests incl. dry-run no-op and idempotency), `lint` (`shellcheck` on all `.bin/*.sh`), and `secrets` (gitleaks scan).

## Architecture

- **`.gitignore` uses a whitelist pattern:** The top of `.gitignore` ignores everything (`/*`, `/.**`), then specific files/directories are un-ignored with `!` prefixes. When adding new dotfiles, you must add a corresponding `!` entry in `.gitignore`.
- **Shell:** oh-my-zsh (git plugin) with its theme disabled (`ZSH_THEME=""`); the prompt is provided by **starship**, initialized last in `.zshrc`. Modern CLI tools (zoxide, fzf, eza, bat) are wired up in `.zshrc`, each guarded by `command -v` so a missing tool never breaks shell startup.
- **Install mechanism:** `.bin/install.sh` iterates over the repo's `.*` entries, skipping `.git` and `.claude` (the latter is managed via `.config/claude/`), and symlinks each into `$HOME`. All linking goes through the `link_file` helper: an existing symlink at the destination is removed, an existing real file/dir is moved to `~/.dotbackup/` under a slash-flattened name (so e.g. `.claude/settings.json` and `.gemini/settings.json` never collide), then the symlink is created.
- **Uninstall mirrors install:** `.bin/uninstall.sh` walks the same set of destinations as `install.sh` but in reverse. Its `unlink_file` helper removes a destination **only if** it is a symlink whose target is inside this repo (`readlink` prefix check), then restores the matching `~/.dotbackup/` backup if one exists — so foreign symlinks and real files are never touched.
- **`.config/` is linked per-app, at file granularity:** rather than symlinking `~/.config/<app>` as a whole (which would swallow app-managed session data), the installer links individual files: `.config/claude/*` → `~/.claude/`, `.config/{codex,gemini}/*` → `~/.{codex,gemini}/`. The `skills/` subdirectories of claude and codex are linked directory-by-directory into `~/.claude/skills/` and `~/.codex/skills/`. This means `.config/claude/CLAUDE.md` and `.config/claude/RTK.md` are the user's **global** agent instructions (linked to `~/.claude/`), distinct from this repo's root `CLAUDE.md`, which documents the repo itself.
- **Claude and Codex skills are intentionally separate, not duplicates:** `.config/claude/skills/` and `.config/codex/skills/` hold same-named skills (`code-review`, `address-review`, …) whose contents deliberately differ per tool — Claude skills carry `aliases:`/`allowed-tools:` frontmatter (Claude Code format), while Codex skills omit those and use a prose form Codex understands. Do **not** try to reconcile them into a single shared source; edit each tool's copy independently.
- **Third-party skills are reproduced at install time, not vendored — with one exception:** skills that are pristine copies of public upstreams are *not* committed here (a committed copy silently goes stale). `agent-browser` ships inside its npm package (`Brewfile`), so `install.sh` symlinks `~/.claude/skills/agent-browser` straight to the package's bundled copy, which tracks the installed version automatically. The exception is `skill-creator` (Anthropic official, Apache-2.0): it has no package distribution, so a pinned copy is vendored under `.config/claude/skills/skill-creator/` with `SOURCE.md` recording the upstream commit — update it by re-copying, not by editing in place.
