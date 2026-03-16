---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify documentation → Verify tests → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 0: Verify Documentation

**Before anything else, check documentation requirements:**

1. If this branch includes a bug fix: verify a `docs/bugs/YYYY-MM-DD-*.md` entry exists
2. If this branch involved investigating how something works: verify a `docs/investigations/YYYY-MM-DD-*.md` entry exists
3. If documentation is missing, create it before proceeding to Step 1

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main - is that correct?"

### Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** - keep options concise.

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
<test command>
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

**MANDATORY pre-push sanity check — do not skip, do not abbreviate:**

```bash
# 1. What is the base branch on origin?
git remote show origin | grep HEAD

# 2. How many commits will this PR include?
git log --oneline origin/<base-branch>..HEAD

# 3. What is the diff size?
git diff origin/<base-branch>...HEAD --stat
```

**Evaluate the output before proceeding:**
- Does the commit count match what you expect? If you made 1 change, you should see 1 commit — not 7, not 50.
- Does the diff stat (files, insertions, deletions) match what you expect? A small cleanup should be small.
- For stacked PRs: confirm `origin/<base-branch>` is at the exact commit you expect by running `git log --oneline origin/<base-branch> | head -3` and verifying those are the right commits.

**If the commit count or diff is larger than expected:**
- STOP. Do not push.
- Investigate: is the base branch out of sync on origin? Did the local base branch get extra commits that weren't pushed to origin?
- Fix the branch (rebase or cherry-pick) until `git log --oneline origin/<base-branch>..HEAD` shows exactly the commits that belong in this PR.

Only after confirming the diff is correct:

```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Problem
<What broke or what we're fixing, and why it matters>

## Changes
- <bullet of what you did>
- <bullet of what you did>

## Testing
<What you verified, conversationally — not formal test cases>

<issue reference>
EOF
)"
```

After creating the PR, immediately verify:
```bash
gh pr view <number> --json additions,deletions,commits \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Commits: {len(d[\"commits\"])}, +{d[\"additions\"]}/-{d[\"deletions\"]}')"
```

If the numbers are wrong, close the PR immediately with `gh pr close <number>` and investigate before re-opening.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation.

## Common Mistakes

**Skipping documentation verification**
- **Problem:** Ship work without bug journal or investigation entries
- **Fix:** Always check Step 0 before proceeding

**Skipping test verification**
- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Skipping the pre-push diff sanity check**
- **Problem:** PR includes dozens or hundreds of commits from a stacked/rebased base branch that wasn't in sync on origin — embarrassing, confusing for reviewers, must be force-closed
- **Fix:** Always run `git log --oneline origin/<base>..HEAD` BEFORE pushing. If the count is wrong, stop and fix the branch. Stacked PRs are especially vulnerable: the local base branch may have commits that were never pushed to origin, so `origin/<base>` is behind the local version, making GitHub show all the extra commits
- **The signal:** You expect 1-3 commits; the command shows 10+. STOP.

**No confirmation for discard**
- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation
