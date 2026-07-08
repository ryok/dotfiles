# dotfiles

[![CI](https://github.com/ryok/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/ryok/dotfiles/actions/workflows/check.yml)

macOS (Apple Silicon) 向けの dotfiles です。

## 含まれるファイル

- `.zshrc` / `.zshenv` / `.zprofile` — Zsh 設定 (oh-my-zsh)
- `.vimrc` — Vim 設定
- `.tmux.conf` — tmux 設定
- `.gitconfig` / `.gitignore_global` — Git 設定
- `.config/{claude,codex,gemini}/` — AI CLI ツールの設定(`~/.claude/` 等へリンク)
- `Brewfile` — Homebrew で入れる CLI ツール一式
- `.bin/macos-defaults.sh` — macOS のシステム設定(キーボード・Finder・スクリーンショット)

プロンプトは [starship](https://starship.rs)、加えて zoxide(smart cd)・fzf(曖昧検索)・eza(モダン `ls`)・bat(モダン `cat`)を `.zshrc` で有効化しています。いずれも `command -v` でガードしているため、未インストールでもシェル起動は壊れません(`brew bundle` で導入)。

## インストール

```bash
git clone https://github.com/ryok/dotfiles.git ~/dotfiles
~/dotfiles/.bin/install.sh
```

リポジトリ内の dotfiles が `$HOME` にシンボリックリンクされます。既存のファイルは `~/.dotbackup/` にバックアップされます。
実行前に `--dry-run` (`-n`) を付けると、変更せずに実行内容だけを確認できます。

### 依存ツールの導入 (任意)

```bash
brew bundle --file=~/dotfiles/Brewfile          # インストール
brew bundle check --file=~/dotfiles/Brewfile    # 不足分の確認のみ
```

### クリーンインストールからの一括セットアップ

新しいマシンでは `bootstrap.sh` が oh-my-zsh・依存ツール・dotfiles のリンクまで一括で行います。

```bash
git clone https://github.com/ryok/dotfiles.git ~/dotfiles
~/dotfiles/.bin/bootstrap.sh
```

- **Homebrew があるマシン**: `brew bundle` で `Brewfile` の一式 (rtk / agent-browser / node …) を導入。
- **Homebrew も node も無い制約ホスト** (共有 GPU サーバ等): `rtk` / `agent-browser` を GitHub release から直接 DL (rtk は `checksums.txt` で検証)。

OS / アーキテクチャ (macOS・Linux / x86_64・arm64) は自動判定します。オプション: `--skip-browser` (Chrome for Testing ~177MB を省略) / `--force` (再インストール) / `--no-brew` (brew があっても release 経路)。`~/.local/bin` を PATH に入れておくこと。settings.json のフック (rtk) は Claude Code 再起動後に有効化されます。

### ホスト固有設定

マシン固有の Claude グローバル指示は `.config/claude/hosts/<hostname>/` に置きます。`install.sh` は
**現在の hostname と一致するディレクトリのみ** を `~/.claude/` へリンクし、同名の共有ファイルを上書きするため、
他マシン (macOS 等) には一切影響しません (例: `hosts/p-team-17/CLAUDE.md` = 共有 GPU サーバの運用ノート)。

### アンインストール

```bash
~/dotfiles/.bin/uninstall.sh          # --dry-run で事前確認も可
```

このリポジトリを指すシンボリックリンクだけを削除し、`~/.dotbackup/` にバックアップがあれば復元します。他のツールが作ったリンクや実ファイルには触れません。

### macOS システム設定 (任意)

```bash
~/dotfiles/.bin/macos-defaults.sh --dry-run   # 変更内容を確認
~/dotfiles/.bin/macos-defaults.sh             # 適用
```

キーボード(キーリピート高速化)、Finder(拡張子・隠しファイル・パスバー表示)、スクリーンショット(`~/Screenshots` 保存・影なし・png)を設定します。macOS 以外では何もしません。`install.sh` からは自動実行されないので、必要なときに手動で実行してください。

## 管理方針

`.gitignore` はホワイトリスト方式です。新しいファイルを追加する場合は `.gitignore` に `!/ファイル名` を追記してください。
