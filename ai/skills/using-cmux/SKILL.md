---
name: using-cmux
description: Use when opening a worktree or directory in a new isolated Claude Code session via cmux terminal workspace
allowed-tools: Bash, Read, Grep, Glob
---

# Using CMUX

## Overview

cmux (manaflow-ai/cmux) is a macOS terminal app for running multiple AI coding agents in parallel workspaces. It manages terminal workspaces, panes, notifications, and browser integration — but does **NOT** manage git worktrees.

**Core principle:** cmux opens isolated terminal workspaces. Git worktree creation is handled separately by `using-git-worktrees` or `git worktree add`. cmux and git worktrees complement each other — they are not alternatives.

**Announce at start:** "I'm using the using-cmux skill to open this workspace in cmux."

## When to Use This Skill

- Opening a git worktree in a new cmux workspace for a parallel Claude session
- After `using-git-worktrees` has created the worktree and you need to open it

## Detection: Is cmux available?

```bash
command -v cmux &>/dev/null && echo "cmux available" || echo "cmux not found"
```

**If not available:** Provide the worktree path and tell the user to open it manually in their terminal.

## Commands Quick Reference

| Goal | Command |
|------|---------|
| Open directory in new workspace | `cmux <path>` |
| Open workspace and run a command | `cmux new-workspace --cwd <path> --command "<cmd>"` |
| Open workspace and start Claude | `cmux new-workspace --cwd <path> --command "yolo"` |
| List workspaces | `cmux list-workspaces` |
| Close a workspace | `cmux close-workspace --workspace <id>` |
| Rename a workspace | `cmux rename-workspace <title>` |

## Workflow: Opening a Worktree

After `using-git-worktrees` (or `git worktree add`) creates the worktree:

### Step 1: Confirm the worktree path

Verify the worktree was created and you know the full path.

### Step 2: Provide the cmux command to the user

```
To open this worktree in a new Claude session, run in your terminal:

  cmux new-workspace --cwd <worktree-path> --command "yolo"

This opens a new cmux workspace at that directory and starts Claude Code.
```

### Step 3: Provide the task to paste

cmux does not pass prompts to Claude automatically. Provide the task text separately so the user can paste it once Claude opens:

```
Once Claude opens, paste this task:

  <full task description>
```

## Workflow: Parallel Sessions (called from executing-plans)

When a parallel session is needed:

1. **Claude creates the worktree** (via Bash — `git worktree add`)
2. **Claude provides two things:** the `cmux new-workspace` command + the task text to paste
3. **User runs the command** → new cmux workspace opens with Claude
4. **User pastes the task** → parallel session begins

Always provide both steps together:

```
Step 1 — Run in your terminal:

  cmux new-workspace --cwd <worktree-path> --command "yolo"

Step 2 — Once Claude opens, paste this task:

  Execute the implementation plan at docs/plans/YYYY-MM-DD-<name>.md using the executing-plans skill.
```

## Red Flags

**Never:**
- Use `cmux new`, `cmux start`, `cmux ls`, `cmux merge`, `cmux rm` — these do NOT exist in manaflow-ai/cmux
- Assume cmux handles git worktrees — it does not; always use `git worktree add` or `using-git-worktrees` first
- Attempt to programmatically spawn a new Claude session — provide the command for the user to run

**Always:**
- Create the git worktree BEFORE providing the cmux command
- Provide both the cmux command AND the task text to paste in one message
- Use `cmux new-workspace --cwd <path> --command "yolo"` for Claude sessions

## Integration

**Works alongside (not a replacement for):**
- **using-git-worktrees** — creates the worktree that cmux then opens

**Called by:**
- **brainstorming** — after design approved, before implementation
- **executing-plans** — for parallel execution sessions
- **subagent-driven-development** — for isolated task execution

**Pairs with:**
- **finishing-a-development-branch** — REQUIRED for cleanup after work is complete

## Example Output

```
I'm using the using-cmux skill to open this workspace in cmux.

[Worktree created at: ~/supabase/supabase/.worktrees/fix-enabled-gate]

Step 1 — Run in your terminal:

  cmux new-workspace --cwd ~/supabase/supabase/.worktrees/fix-enabled-gate --command "yolo"

Step 2 — Once Claude opens, paste this task:

  Fix the unresolved CodeRabbit issue in packages/common/telemetry.tsx around
  lines 343-351: handlePageTelemetry() bypasses the enabled gate. Wrap it with
  the same enabled condition used elsewhere. Branch: sean/growth-656-enabled-gate-fix.
```
