---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
allowed-tools: Bash, Read, Grep, Glob, Edit, Write, Skill
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## Setting Up a Parallel Session (Before You Start)

This skill is designed to run in a **separate session** from the planning session. Before executing a plan, set up an isolated worktree:

**Step 1 — Create the worktree:**
Use the `using-git-worktrees` skill (or run `git worktree add` directly).

**Step 2 — Open the worktree in a new terminal session:**
Tell the user to open the worktree path in a new terminal and run `claude` there with this initial task:

```
Execute the plan at <plan-file-path> using the executing-plans skill.
```

Once the new session is running in its worktree, proceed with the steps below.

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically — look for: ambiguous file paths, missing dependencies, steps that assume context not provided, test commands that reference non-existent scripts, or architecture decisions that seem questionable
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create TodoWrite and proceed

### Step 2: Execute Batch
**Default: First 3 tasks**

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed

### Step 3: Report
When batch complete:
- Show what was implemented
- Show verification output
- Say: "Ready for feedback."

### Step 4: Continue
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Between batches: just report and wait
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent
