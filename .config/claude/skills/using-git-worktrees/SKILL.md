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

- `name` (optional): Worktree name. A random name is generated if omitted. Allowed characters: alphanumeric, `.`, `_`, `-`, `/` (max 64 chars)
- Worktrees are created inside `.claude/worktrees/` (fixed location)
- A new branch based on HEAD is automatically created
- The session's working directory is automatically switched to the worktree

**Manual fallback** (when EnterWorktree is unavailable):

Directory selection is required for manual creation. Priority order:

1. Check existing directories: `.worktrees/` > `worktrees/`
2. Follow CLAUDE.md preference if specified
3. Ask user if neither exists

```bash
# For project-local directories, verify gitignore first
git check-ignore -q .worktrees 2>/dev/null
# If not ignored, add to .gitignore and commit before proceeding

git worktree add .worktrees/feature-auth -b feature-auth
cd .worktrees/feature-auth
```

### 2. Run Project Setup

**Priority order:**

1. **Project-specific script** — If `.claude/skills/setup-worktree/setup-worktree.sh` exists in the project, run it. This script should also handle copying environment files (`.env`, certificates, etc.). The main worktree path can be obtained with:
   ```bash
   MAIN_DIR="$(git worktree list --porcelain | head -1 | sed 's/^worktree //')"
   ```
2. **Auto-detect from project files** — Fallback when no project-specific script exists:

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
| EnterWorktree available | Use it (creates in `.claude/worktrees/`) |
| Manual: `.worktrees/` exists | Use it (verify ignored) |
| Manual: Neither exists | Check CLAUDE.md → Ask user |
| Manual: Directory not ignored | Add to .gitignore + commit |
| `setup-worktree.sh` exists | Run it (handles env files too) |
| No `setup-worktree.sh` | Auto-detect from project files |
| Tests fail during baseline | Report failures + ask |

## Common Mistakes

### Skipping ignore verification (manual fallback)

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
- Manual: create project-local worktree without verifying gitignore

**Always:**
- Prefer `EnterWorktree`/`ExitWorktree` when available
- Check for project-specific `setup-worktree.sh` before auto-detecting
- Verify clean test baseline

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
- **executing-plans** or **subagent-driven-development** - Work happens in this worktree
