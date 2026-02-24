# dotfiles

[![CI](https://github.com/ryok/dotfiles/actions/workflows/check.yml/badge.svg)](https://github.com/ryok/dotfiles/actions/workflows/check.yml)

macOS (Apple Silicon) 向けの dotfiles です。

## 含まれるファイル

- `.zshrc` / `.zshenv` / `.zprofile` — Zsh 設定 (oh-my-zsh)
- `.vimrc` — Vim 設定
- `.tmux.conf` — tmux 設定
- `.gitconfig` / `.gitignore_global` — Git 設定

## インストール

```bash
git clone https://github.com/ryok/dotfiles.git ~/dotfiles
~/dotfiles/.bin/install.sh
```

リポジトリ内の dotfiles が `$HOME` にシンボリックリンクされます。既存のファイルは `~/.dotbackup/` にバックアップされます。

## 管理方針

`.gitignore` はホワイトリスト方式です。新しいファイルを追加する場合は `.gitignore` に `!/ファイル名` を追記してください。
