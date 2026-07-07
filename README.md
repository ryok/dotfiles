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

### アンインストール

```bash
~/dotfiles/.bin/uninstall.sh          # --dry-run で事前確認も可
```

このリポジトリを指すシンボリックリンクだけを削除し、`~/.dotbackup/` にバックアップがあれば復元します。他のツールが作ったリンクや実ファイルには触れません。

## 管理方針

`.gitignore` はホワイトリスト方式です。新しいファイルを追加する場合は `.gitignore` に `!/ファイル名` を追記してください。
