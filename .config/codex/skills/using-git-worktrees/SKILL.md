---
name: using-git-worktrees
description: "Use when starting feature work that needs isolation from the current workspace or before executing an implementation plan. Creates isolated git worktrees with directory selection, ignore verification, setup, and baseline checks."
---

# Using Git Worktrees

作業開始時に隔離された worktree を作る必要がある場合に使う。

開始時に次の一文を出す: `I'm using the using-git-worktrees skill to set up an isolated workspace.`

## 優先順位

1. 既存の `.worktrees/`
2. 既存の `worktrees/`
3. `CLAUDE.md` または `AGENTS.md` に書かれた方針
4. どれもなければユーザーに確認

```bash
ls -d .worktrees 2>/dev/null
ls -d worktrees 2>/dev/null
rg -i "worktree.*director|\\.worktrees|worktrees" CLAUDE.md AGENTS.md 2>/dev/null
```

## 安全確認

プロジェクト配下に worktree を作る場合は、作成前に ignore されていることを確認する。

```bash
git check-ignore -q .worktrees || git check-ignore -q worktrees
```

ignore されていなければ:

1. `.gitignore` に追加する
2. 必要ならその変更をコミットする
3. その後に worktree を作る

## 作成

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
git worktree add <path> -b <branch-name>
cd <path>
```

## セットアップ

```bash
if [ -f package.json ]; then npm install; fi
if [ -f Cargo.toml ]; then cargo build; fi
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi
if [ -f go.mod ]; then go mod download; fi
```

## ベースライン確認

プロジェクトに応じたテストを先に実行する。

```bash
npm test
cargo test
pytest
go test ./...
```

失敗したら、その時点でベースラインが壊れていることを報告して止める。

## 報告内容

- worktree のフルパス
- ブランチ名
- 実行したセットアップ
- テスト結果
