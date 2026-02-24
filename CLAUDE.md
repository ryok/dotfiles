# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a dotfiles repository for macOS/Linux. Dotfiles are symlinked into `$HOME` via the install script. The repo uses a whitelist-based `.gitignore` — everything is ignored by default, and tracked files are explicitly un-ignored.

## Key Commands

- **Install dotfiles:** `.bin/install.sh` — backs up existing dotfiles to `~/.dotbackup/`, then symlinks all `.*` entries (except `.git`) into `$HOME`. Also sets `git config --global include.path ~/.gitconfig_shared`.
- **Install with debug:** `.bin/install.sh --debug`
- **CI:** GitHub Actions runs install tests on Ubuntu, CentOS, Alpine, and Arch, plus shellcheck linting on zsh/shell configs.

## Architecture

- **`.gitignore` uses a whitelist pattern:** The top of `.gitignore` ignores everything (`/*`, `/.**`), then specific files/directories are un-ignored with `!` prefixes. When adding new dotfiles, you must add a corresponding `!` entry in `.gitignore`.
- **Shell:** oh-my-zsh with `robbyrussell` theme. Plugins: git, zsh-syntax-highlighting, zsh-completions, zsh-autosuggestions, zsh-history-substring-search.
- **Install mechanism:** `.bin/install.sh` iterates over all `.*` items in the repo root, skipping `.git`, and creates symlinks in `$HOME`. Existing files are moved to `~/.dotbackup/`.
