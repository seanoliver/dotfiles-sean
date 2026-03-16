---
name: using-cmux
description: Use when starting feature work, spinning up a parallel agent session, or managing multiple concurrent worktrees with cmux. Replaces using-git-worktrees when cmux is available.
allowed-tools: Bash, Read, Grep, Glob
---

# Using CMUX

## Overview

cmux is a worktree lifecycle manager for Claude Code. It wraps `git worktree` with one-command setup, a project setup hook (`.cmux/setup`), and a consistent layout — so each feature gets a fully isolated checkout without any manual plumbing.

**Core principle:** One command to create an isolated workspace with a running Claude session. No manual `git worktree add`, no manual `npm install`, no manual branch tracking.

**Announce at start:** "I'm using the using-cmux skill to set up an isolated workspace."

## When to Use This Skill

- Starting feature work that needs branch isolation
- Spinning up a **parallel agent session** for independent work (called from `executing-plans` or `subagent-driven-development`)
- Resuming work in an existing worktree
- Managing the lifecycle of active worktrees (list, merge, remove)

## Detection: Is cmux available?

```bash
command -v cmux &>/dev/null && echo "cmux available" || echo "cmux not found"
```

**If cmux is not available:** Fall back to the `using-git-worktrees` skill.

## Commands Quick Reference

| Goal | Command |
|------|---------|
| New feature / new agent session | `cmux new <branch-name>` |
| New with initial prompt | `cmux new <branch-name> -p "your prompt"` |
| Resume existing worktree | `cmux start <branch-name>` |
| Resume with prompt | `cmux start <branch-name> -p "your prompt"` |
| List active worktrees | `cmux ls` |
| cd into a worktree | `cmux cd <branch-name>` |
| Merge worktree → main checkout | `cmux merge <branch-name> [--squash]` |
| Remove worktree + branch | `cmux rm <branch-name>` |
| Remove all worktrees | `cmux rm --all` |
| Generate setup hook | `cmux init` |
| View worktree layout config | `cmux config` |

## Workflow: Starting New Feature Work

### Step 1: Choose a branch name

Branch names become directory names. Use kebab-case. Slashes are automatically converted to hyphens.

```
feature/auth-flow     → .worktrees/feature-auth-flow
fix-payments-bug      → .worktrees/fix-payments-bug
```

### Step 2: Output the cmux command to run

Provide the command to the user to run in their terminal:

```
To start work in an isolated worktree, run this in your terminal:

  cmux new <branch-name>

This will:
  1. Create .worktrees/<branch-name>/ with a new git branch
  2. Run .cmux/setup (symlinks .env, installs deps, runs codegen)
  3. Launch a new Claude Code session in that directory
```

**For parallel work:** If this is being called from `executing-plans` to set up a parallel session, use `-p` to pass in the initial task:

```
  cmux new <branch-name> -p "<initial task description>"
```

### Step 3: Verify .cmux/setup exists

Before telling the user to run `cmux new`, check:

```bash
test -f .cmux/setup && echo "setup exists" || echo "no setup hook"
```

**If no setup hook:** Warn the user and suggest running `cmux init` first to generate one, OR proceed with a note that dependencies must be installed manually after the worktree is created.

### Step 4: Verify .worktrees/ is gitignored

```bash
git check-ignore -q .worktrees 2>/dev/null && echo "ignored" || echo "NOT ignored"
```

**If not ignored:** Add `.worktrees/` to `.gitignore` before proceeding. Commit the change.

## Workflow: Resuming Existing Work

When the user wants to continue work in an existing worktree:

```bash
# Check what worktrees exist
cmux ls
```

Then output:

```
To resume work on <branch-name>, run:

  cmux start <branch-name>

This will resume from where you left off with --continue.
```

## Workflow: Parallel Sessions (called from executing-plans)

When `executing-plans` or another skill needs a parallel session:

1. Determine a branch name from the plan name (e.g., `plan-name` → `exec-plan-name`)
2. Check if that worktree already exists (`cmux ls`)
3. If it exists: provide `cmux start <branch>` command
4. If new: provide `cmux new <branch> -p "..."` command with the plan context as the prompt

Provide the exact command to paste into a terminal, along with the plan file path so the new session picks it up:

```
Spawn a parallel Claude session to execute this plan:

  cmux new exec-<plan-slug> -p "Execute the implementation plan at docs/plans/YYYY-MM-DD-<name>.md using the executing-plans skill."

Once the new Claude session opens in that worktree, it will pick up the plan and start executing.
```

## Setup Hook: .cmux/setup

The `.cmux/setup` script runs automatically when `cmux new` creates a worktree. It handles:
- Symlinking gitignored secrets (`.env`, `.dev.vars`)
- Installing dependencies (`npm ci`, `pip install`, etc.)
- Running codegen (`prisma generate`, etc.)

**To generate one for this project:**
```bash
cmux init
```

**Minimal example:**
```bash
#!/bin/bash
REPO_ROOT="$(git rev-parse --git-common-dir | xargs dirname)"
ln -sf "$REPO_ROOT/.env" .env
npm ci
```

## Lifecycle: Merging and Cleanup

When work in a worktree is complete:

```bash
# From repo root or from inside the worktree
cmux merge <branch-name> [--squash]   # merge into current branch
cmux rm <branch-name>                  # remove worktree + delete branch
```

Or from inside the worktree:
```bash
cmux merge    # auto-detects current branch
cmux rm       # auto-detects current branch (after merging)
```

## Worktree Layout

Default layout: `<repo-root>/.worktrees/<branch>/`

Other layouts available via `cmux config set layout <preset>`:
- `nested` (default): `.worktrees/` inside repo
- `outer-nested`: `<repo-name>.worktrees/` next to repo
- `sibling`: `<repo-name>-<branch>/` next to repo

## Red Flags

**Never:**
- Tell the user to run `git worktree add` directly — always use `cmux new`
- Skip checking for `.cmux/setup` — missing setup causes broken worktrees
- Skip checking `.worktrees/` is gitignored — prevents tracking worktree contents
- Attempt to programmatically spawn a new Claude session — provide the command for the user to run

**Always:**
- Provide the exact `cmux` command to paste, not a description
- Check `cmux ls` before creating a new worktree for the same branch
- Include the full branch name in the `cmux` command (no ambiguity)

## Integration

**Called by:**
- **brainstorming** (Phase 4) — REQUIRED when design approved and implementation follows
- **executing-plans** — REQUIRED before executing any tasks in a parallel session
- **subagent-driven-development** — REQUIRED before executing any tasks

**Replaces:**
- **using-git-worktrees** — use this skill instead when cmux is available

**Pairs with:**
- **finishing-a-development-branch** — REQUIRED for cleanup after work complete

## Example Output

```
I'm using the using-cmux skill to set up an isolated workspace.

[Checked: cmux is available]
[Checked: .cmux/setup exists]
[Checked: .worktrees/ is gitignored ✓]

To start work on this feature, run in your terminal:

  cmux new feature-auth-flow

This creates an isolated worktree at .worktrees/feature-auth-flow/ on branch
feature-auth-flow, runs .cmux/setup to install dependencies and symlink secrets,
then opens a new Claude Code session in that directory.
```
