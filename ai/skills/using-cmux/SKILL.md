---
name: using-cmux
description: Use when starting feature work, spinning up a parallel agent session, or managing multiple concurrent worktrees with cmux. Replaces using-git-worktrees when cmux is available.
allowed-tools: Bash, Read, Grep, Glob
---

# Using CMUX

## Overview

This skill manages isolated git worktrees for parallel Claude Code sessions. It combines native `git worktree` commands with the **cmux.dev terminal app CLI** to programmatically create worktrees AND spawn Claude sessions — no manual copy-pasting required.

**Core principle:** Claude handles everything — worktree creation, setup hooks, and spawning a new Claude session in a new cmux workspace tab. The user doesn't need to leave the conversation.

**Announce at start:** "I'm using the using-cmux skill to set up an isolated workspace."

## When to Use This Skill

- Starting feature work that needs branch isolation
- Spinning up a **parallel agent session** for independent work (called from `executing-plans` or `subagent-driven-development`)
- Resuming work in an existing worktree
- Managing the lifecycle of active worktrees (list, merge, remove)

## Detection: Is the cmux.dev app available?

```bash
cmux ping 2>/dev/null && echo "cmux app running" || echo "cmux app not running"
```

**If cmux app is not running:** Fall back to manual instructions — tell the user to open the cmux app, or fall back to the `using-git-worktrees` skill.

## Architecture

This skill uses two layers:

1. **git worktree** — creates isolated checkouts that share the same `.git` database
2. **cmux.dev CLI** (`cmux new-workspace`) — programmatically opens a new terminal tab in the worktree directory and launches Claude

These are independent tools that happen to work perfectly together. The cmux.dev app is the terminal; git worktree provides the isolation.

## Commands Quick Reference

### Worktree Management (git)

| Goal | Command |
|------|---------|
| List worktrees | `git worktree list` |
| Create worktree + branch | `git worktree add .worktrees/<branch> -b <branch>` |
| Remove worktree | `git worktree remove .worktrees/<branch>` |
| Prune stale worktrees | `git worktree prune` |

### Session Management (cmux.dev CLI)

| Goal | Command |
|------|---------|
| Spawn new workspace tab | `cmux new-workspace --cwd <path> --command "<cmd>"` |
| List workspaces | `cmux list-workspaces` |
| Send text to a workspace | `cmux send --workspace <id> "<text>"` |
| Read workspace screen | `cmux read-screen --workspace <id>` |
| Rename workspace tab | `cmux rename-workspace --workspace <id> "<title>"` |
| Close workspace | `cmux close-workspace --workspace <id>` |

### Merging (git)

| Goal | Command |
|------|---------|
| Merge branch to main | `git merge <branch>` (from main checkout) |
| Squash merge | `git merge --squash <branch>` (from main checkout) |
| Delete branch after merge | `git branch -d <branch>` |

## Workflow: Starting New Feature Work

### Step 1: Choose a branch name

Branch names become directory names. Use kebab-case:

```
feature/shop-system   → .worktrees/feature-shop-system
fix-ace-high-bug      → .worktrees/fix-ace-high-bug
```

### Step 2: Verify .worktrees/ is gitignored

```bash
git check-ignore -q .worktrees 2>/dev/null && echo "ignored" || echo "NOT ignored"
```

**If not ignored:** Add `.worktrees/` to `.gitignore` before proceeding.

### Step 3: Check for existing worktree

```bash
git worktree list
```

If a worktree for this branch already exists, skip to "Resuming Existing Work."

### Step 4: Create the worktree

```bash
git worktree add .worktrees/<branch> -b <branch>
```

### Step 5: Run setup hook (if it exists)

```bash
if [ -f .cmux/setup ]; then
  cd .worktrees/<branch> && bash "$(git rev-parse --git-common-dir | xargs dirname)/.cmux/setup"
fi
```

For projects without a setup hook (like Godot projects with no build step), skip this.

### Step 6: Spawn a Claude session and send it a prompt

Always spawn Claude AND send it an initial prompt so the agent starts working immediately. The user should never have to manually type into a spawned session.

```bash
# Spawn the workspace
cmux new-workspace --cwd .worktrees/<branch> --command "claude --dangerously-skip-permissions"
```

Then wait a few seconds for Claude to initialize, rename the tab, and send the prompt:

```bash
# Rename for easy identification (use the workspace ID returned by new-workspace)
cmux rename-workspace --workspace <workspace-id> "<branch>"

# Wait for Claude to be ready, then send the initial prompt
sleep 3
cmux send --workspace <workspace-id> "<initial prompt describing the task>\n"
```

The `\n` at the end submits the prompt. The prompt should be specific enough for the agent to work autonomously — include the task description, relevant file paths, and which skills to use.

**Example prompt for feature work:**
```
Read the project's CLAUDE.md, then read docs/upgrade-system.md for context. Implement the reward shop system using the brainstorming skill first, then the writing-plans skill, then implement with TDD.
```

## Workflow: Resuming Existing Work

```bash
# Check what worktrees exist
git worktree list
```

Then spawn a new Claude session in the existing worktree and send it a resume prompt:

```bash
cmux new-workspace --cwd .worktrees/<branch> --command "claude --dangerously-skip-permissions --continue"
# Rename and send prompt
cmux rename-workspace --workspace <workspace-id> "<branch>"
sleep 3
cmux send --workspace <workspace-id> "Continue where you left off on <task description>.\n"
```

## Workflow: Parallel Sessions (called from executing-plans)

When `executing-plans` or another skill needs a parallel session:

1. Determine a branch name from the plan name (e.g., `plan-name` → `exec-plan-name`)
2. Check if the worktree already exists (`git worktree list`)
3. If it exists: spawn Claude with `--continue` in that worktree
4. If new: create worktree, spawn Claude, and send the plan prompt

```bash
# Create worktree
git worktree add .worktrees/exec-<plan-slug> -b exec-<plan-slug>

# Spawn Claude
cmux new-workspace --cwd .worktrees/exec-<plan-slug> --command "claude --dangerously-skip-permissions"

# Rename and send the plan prompt
cmux rename-workspace --workspace <workspace-id> "exec-<plan-slug>"
sleep 3
cmux send --workspace <workspace-id> "Execute the implementation plan at docs/plans/YYYY-MM-DD-<name>.md using the executing-plans skill.\n"
```

## Lifecycle: Merging and Cleanup

When work in a worktree is complete:

```bash
# From the main checkout (repo root)
git merge <branch>                          # or: git merge --squash <branch>
git worktree remove .worktrees/<branch>     # remove the worktree
git branch -d <branch>                      # delete the branch
git worktree prune                          # clean up stale refs
```

## Setup Hook: .cmux/setup

The `.cmux/setup` script can be run after creating a worktree. It handles:
- Symlinking gitignored secrets (`.env`, `.dev.vars`)
- Installing dependencies (`npm ci`, `pip install`, etc.)
- Running codegen (`prisma generate`, etc.)

**Minimal example:**
```bash
#!/bin/bash
REPO_ROOT="$(git rev-parse --git-common-dir | xargs dirname)"
ln -sf "$REPO_ROOT/.env" .env
npm ci
```

For projects with no build step (like Godot), no setup hook is needed.

## Monitoring Spawned Sessions

Use cmux.dev CLI to check on spawned sessions:

```bash
# Read what's on screen in a workspace
cmux read-screen --workspace <id>

# Send a command to a workspace
cmux send --workspace <id> "your text here"

# List all workspaces to find IDs
cmux list-workspaces
```

## Red Flags

**Never:**
- Use `cmux new`, `cmux start`, `cmux ls`, `cmux merge`, `cmux rm` — these are from craigsc/cmux, NOT cmux.dev
- Skip checking `.worktrees/` is gitignored
- Create a worktree for a branch that already has one
- Force-remove a worktree with uncommitted changes without asking

**Always:**
- Check `git worktree list` before creating a new worktree
- Use `cmux new-workspace` to spawn sessions (don't tell the user to copy-paste)
- Send an initial prompt via `cmux send` so the agent starts working immediately
- Include the full branch name in commands (no ambiguity)
- Verify the cmux app is running before attempting to spawn workspaces

## Integration

**Called by:**
- **brainstorming** — after design approved, before implementation
- **executing-plans** — for parallel execution sessions
- **subagent-driven-development** — for isolated task execution

**Replaces:**
- **using-git-worktrees** — use this skill instead when cmux is available

**Pairs with:**
- **finishing-a-development-branch** — REQUIRED for cleanup after work is complete

## Example Output

```
I'm using the using-cmux skill to set up an isolated workspace.

[Checked: cmux app is running ✓]
[Checked: .worktrees/ is gitignored ✓]
[Checked: no existing worktree for this branch ✓]

Creating worktree, spawning Claude session, and sending initial prompt...

  git worktree add .worktrees/feature-shop-system -b feature-shop-system
  cmux new-workspace --cwd .worktrees/feature-shop-system --command "claude --dangerously-skip-permissions"
  cmux rename-workspace --workspace workspace:5 "feature-shop-system"
  sleep 3
  cmux send --workspace workspace:5 "Read CLAUDE.md, then implement the shop system..."

✓ New workspace opened in cmux. Claude is working on the task in .worktrees/feature-shop-system/
```
