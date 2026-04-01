---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Creation Steps

### 1. Create Worktree with EnterWorktree

**Use Claude Code's built-in `EnterWorktree` tool.** It handles worktree creation and session context switching automatically.

```
EnterWorktree(name: "feature-auth")
```

- `name` (optional): worktree名。省略するとランダム名が生成される。使用可能文字: 英数字, `.`, `_`, `-`, `/`（最大64文字）
- worktreeは `.claude/worktrees/` 内に作成される（固定）
- HEADベースで新しいブランチが自動作成される
- セッションの作業ディレクトリが自動的にworktreeに切り替わる

**手動フォールバック** (EnterWorktree が利用できない場合):

手動で作成する場合はディレクトリ選択が必要。以下の優先順で決定する:

1. 既存ディレクトリを確認: `.worktrees/` > `worktrees/`
2. CLAUDE.md に指定があればそれに従う
3. いずれもなければユーザーに確認

```bash
# プロジェクトローカルの場合、gitignoreされているか必ず確認
git check-ignore -q .worktrees 2>/dev/null
# ignored でなければ .gitignore に追加してコミットしてから進める

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

### 2. Run Project Setup

**Priority order:**

1. **Project-specific script** — `.claude/skills/setup-worktree/setup-worktree.sh` がプロジェクトに存在すれば実行する。環境ファイル（`.env`, 証明書等）のコピーもこのスクリプト内で行う。メインworktreeのパスは以下で取得可能:
   ```bash
   MAIN_DIR="$(git worktree list --porcelain | head -1 | sed 's/^worktree //')"
   ```
2. **Auto-detect from project files** — プロジェクト固有スクリプトがない場合のフォールバック:

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 4. Verify Clean Baseline

Run tests to ensure worktree starts clean:

```bash
# Examples - use project-appropriate command
npm test
cargo test
pytest
go test ./...
```

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

### 5. Report Location

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Cleanup

**Use `ExitWorktree` tool** to return to the main repository and clean up the worktree:

```
ExitWorktree()
```

This automatically:
- Returns the session to the original working directory
- Removes the worktree directory
- Prevents orphaned worktrees from accumulating

## Quick Reference

| Situation | Action |
|-----------|--------|
| EnterWorktree available | Use it (`.claude/worktrees/` に作成) |
| 手動: `.worktrees/` exists | Use it (verify ignored) |
| 手動: Neither exists | Check CLAUDE.md → Ask user |
| 手動: Directory not ignored | Add to .gitignore + commit |
| `setup-worktree.sh` exists | Run it (env files含む) |
| `setup-worktree.sh` なし | Auto-detect from project files |
| Tests fail during baseline | Report failures + ask |

## Common Mistakes

### Skipping ignore verification (手動フォールバック時)

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

### Hardcoding setup commands

- **Problem:** Breaks on projects using different tools
- **Fix:** Use project-specific `setup-worktree.sh` if available, otherwise auto-detect from project files

### Not using ExitWorktree for cleanup

- **Problem:** Orphaned worktrees accumulate, wasting disk space
- **Fix:** Always use `ExitWorktree` to return and clean up

## Example Workflow

```
You: I'm using the using-git-worktrees skill to set up an isolated workspace.

[EnterWorktree(name: "feature-auth")]
[Run .claude/skills/setup-worktree/setup-worktree.sh (or npm install)]
[Run npm test - 47 passing]

Worktree ready at .claude/worktrees/feature-auth
Tests passing (47 tests, 0 failures)
Ready to implement auth feature

... (implementation work) ...

[ExitWorktree() - returns to main directory and cleans up]
```

## Red Flags

**Never:**
- Skip baseline test verification
- Proceed with failing tests without asking
- Leave worktrees without cleaning up via `ExitWorktree`
- 手動時: ignore確認なしでproject-local worktreeを作成

**Always:**
- `EnterWorktree`/`ExitWorktree` を優先使用
- `setup-worktree.sh` の有無を確認してからセットアップ
- Verify clean test baseline

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
- **executing-plans** or **subagent-driven-development** - Work happens in this worktree
