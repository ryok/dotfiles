# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository for macOS/Linux. Dotfiles are symlinked into `$HOME` via the install script. The repo uses a whitelist-based `.gitignore` — everything is ignored by default, and tracked files are explicitly un-ignored.

## Key Commands

- **Install dotfiles:** `.bin/install.sh` — backs up existing dotfiles to `~/.dotbackup/`, then symlinks tracked entries into `$HOME`.
- **Preview without changes:** `.bin/install.sh --dry-run` (`-n`) — prints every action without touching the filesystem.
- **Install with debug:** `.bin/install.sh --debug` (`-d`) — runs with `set -x` tracing.
- **CI:** GitHub Actions (`.github/workflows/check.yml`) runs the installer on `ubuntu:latest` and runs `shellcheck` on `.bin/install.sh`.

## Architecture

- **`.gitignore` uses a whitelist pattern:** The top of `.gitignore` ignores everything (`/*`, `/.**`), then specific files/directories are un-ignored with `!` prefixes. When adding new dotfiles, you must add a corresponding `!` entry in `.gitignore`.
- **Shell:** oh-my-zsh with `robbyrussell` theme. Plugin: git.
- **Install mechanism:** `.bin/install.sh` iterates over the repo's `.*` entries, skipping `.git` and `.claude` (the latter is managed via `.config/claude/`), and symlinks each into `$HOME`. All linking goes through the `link_file` helper: an existing symlink at the destination is removed, an existing real file/dir is moved to `~/.dotbackup/` under a slash-flattened name (so e.g. `.claude/settings.json` and `.gemini/settings.json` never collide), then the symlink is created.
- **`.config/` is linked per-app, at file granularity:** rather than symlinking `~/.config/<app>` as a whole (which would swallow app-managed session data), the installer links individual files: `.config/claude/*` → `~/.claude/`, `.config/{codex,gemini}/*` → `~/.{codex,gemini}/`. The `skills/` subdirectories of claude and codex are linked directory-by-directory into `~/.claude/skills/` and `~/.codex/skills/`. This means `.config/claude/CLAUDE.md` and `.config/claude/RTK.md` are the user's **global** agent instructions (linked to `~/.claude/`), distinct from this repo's root `CLAUDE.md`, which documents the repo itself.
- **Claude and Codex skills are intentionally separate, not duplicates:** `.config/claude/skills/` and `.config/codex/skills/` hold same-named skills (`code-review`, `address-review`, …) whose contents deliberately differ per tool — Claude skills carry `aliases:`/`allowed-tools:` frontmatter (Claude Code format), while Codex skills omit those and use a prose form Codex understands. Do **not** try to reconcile them into a single shared source; edit each tool's copy independently.
