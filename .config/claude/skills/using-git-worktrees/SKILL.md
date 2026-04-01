---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
---

# Using Git Worktrees

## Overview

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

**Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."

## Directory Selection Process

Follow this priority order:

### 1. Check Existing Directories

```bash
# Check in priority order
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```

**If found:** Use that directory. If both exist, `.worktrees` wins.

### 2. Check CLAUDE.md

```bash
grep -i "worktree.*director" CLAUDE.md 2>/dev/null
```

**If preference specified:** Use it without asking.

### 3. Ask User

If no directory exists and no CLAUDE.md preference:

```
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (project-local, hidden)
2. ~/.config/superpowers/worktrees/<project-name>/ (global location)

Which would you prefer?
```

## Safety Verification

### For Project-Local Directories (.worktrees or worktrees)

**MUST verify directory is ignored before creating worktree:**

```bash
# Check if directory is ignored (respects local, global, and system gitignore)
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**If NOT ignored:**

Per Jesse's rule "Fix broken things immediately":
1. Add appropriate line to .gitignore
2. Commit the change
3. Proceed with worktree creation

**Why critical:** Prevents accidentally committing worktree contents to repository.

### For Global Directory (~/.config/superpowers/worktrees)

No .gitignore verification needed - outside project entirely.

## Creation Steps

### 1. Create Worktree with EnterWorktree

**Use Claude Code's built-in `EnterWorktree` tool** instead of manual git commands. It handles worktree creation and session context switching automatically.

```
EnterWorktree(branch: "feature/auth", path: ".worktrees/feature-auth")
```

This automatically:
- Creates the worktree and branch
- Switches the session's working directory to the worktree
- Records the main repository path for later return

**Fallback** (if EnterWorktree is unavailable):

```bash
project=$(basename "$(git rev-parse --show-toplevel)")

case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  ~/.config/superpowers/worktrees/*)
    path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
    ;;
esac

git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

### 2. Copy Environment Files

Copy files that are not tracked in git but required for the project to run:

```bash
MAIN_DIR="$(git rev-parse --show-toplevel)/../$(basename "$(git rev-parse --show-toplevel)")"

# Common environment files
for f in .env .env.local .env.development.local; do
  [ -f "$MAIN_DIR/$f" ] && cp "$MAIN_DIR/$f" .
done

# SSL certificates, local config, etc.
[ -d "$MAIN_DIR/certs" ] && cp -r "$MAIN_DIR/certs" .
```

**What to copy** depends on the project — check `.gitignore` for hints on what untracked files exist.

### 3. Run Project Setup

**Priority order:**

1. **Project-specific script** — If `.claude/skills/setup-worktree/setup-worktree.sh` exists in the project, run it. This allows each project to define its own setup steps.
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
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → Ask user |
| Directory not ignored | Add to .gitignore + commit |
| Tests fail during baseline | Report failures + ask |
| No package.json/Cargo.toml | Skip dependency install |
| `.claude/skills/setup-worktree/setup-worktree.sh` exists | Run it instead of auto-detect |
| `.env` or certs in main dir | Copy to worktree |

## Common Mistakes

### Skipping ignore verification

- **Problem:** Worktree contents get tracked, pollute git status
- **Fix:** Always use `git check-ignore` before creating project-local worktree

### Assuming directory location

- **Problem:** Creates inconsistency, violates project conventions
- **Fix:** Follow priority: existing > CLAUDE.md > ask

### Proceeding with failing tests

- **Problem:** Can't distinguish new bugs from pre-existing issues
- **Fix:** Report failures, get explicit permission to proceed

### Hardcoding setup commands

- **Problem:** Breaks on projects using different tools
- **Fix:** Use project-specific `setup-worktree.sh` if available, otherwise auto-detect from project files

### Forgetting environment files

- **Problem:** Worktree builds/runs fail due to missing .env, certificates, etc.
- **Fix:** Copy untracked environment files from main worktree before running setup

### Not using ExitWorktree for cleanup

- **Problem:** Orphaned worktrees accumulate, wasting disk space
- **Fix:** Always use `ExitWorktree` to return and clean up

## Example Workflow

```
You: I'm using the using-git-worktrees skill to set up an isolated workspace.

[Check .worktrees/ - exists]
[Verify ignored - git check-ignore confirms .worktrees/ is ignored]
[EnterWorktree(branch: "feature/auth", path: ".worktrees/feature-auth")]
[Copy .env from main worktree]
[Run .claude/skills/setup-worktree/setup-worktree.sh (or npm install)]
[Run npm test - 47 passing]

Worktree ready at /Users/user/myproject/.worktrees/feature-auth
Tests passing (47 tests, 0 failures)
Ready to implement auth feature

... (implementation work) ...

[ExitWorktree() - returns to main directory and cleans up]
```

## Red Flags

**Never:**
- Create worktree without verifying it's ignored (project-local)
- Skip baseline test verification
- Proceed with failing tests without asking
- Assume directory location when ambiguous
- Skip CLAUDE.md check
- Leave worktrees without cleaning up via `ExitWorktree`

**Always:**
- Use `EnterWorktree`/`ExitWorktree` when available
- Follow directory priority: existing > CLAUDE.md > ask
- Verify directory is ignored for project-local
- Copy environment files (.env, certs) from main worktree
- Check for project-specific `setup-worktree.sh` before auto-detecting
- Verify clean test baseline

## Integration

**Called by:**
- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
- Any skill needing isolated workspace

**Pairs with:**
- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
- **executing-plans** or **subagent-driven-development** - Work happens in this worktree
