---
name: codex-review
description: Use when the user wants OpenAI Codex to review code — "have Codex review this", "get a Codex review of this PR", "ask Codex what it thinks", "run Codex on this branch/diff". Drives the Codex CLI headlessly; do not launch the interactive `codex` TUI.
---

# Codex Review

## Overview

Drive the Codex CLI headlessly via `codex exec review` to get an independent second-opinion review, iterate with follow-up questions via `codex exec resume`, then apply the vetted findings yourself. Never launch bare `codex` (interactive TUI — it will hang the shell).

## Step 1: Preflight (run before every review)

```bash
codex login status   # exit 0 = authenticated
brew outdated --cask codex   # empty output = up to date
```

- **Outdated?** Run `brew upgrade --cask codex` (it is a brew **cask** named `codex`; `brew update codex` is wrong — `brew update` only refreshes Homebrew itself). ~200MB download. Re-run `codex login status` after upgrading — auth normally persists across upgrades (verified 0.134→0.138), but if it fails, see next bullet.
- **Login check fails?** STOP. Login is an interactive browser flow you cannot automate. Tell the user to run `! codex login` in this session (or `codex login` in another terminal), relay any first-run/migration instructions Codex prints, and wait for them before continuing.

## Step 2: Run the review

Run from the **repo root** of the repo under review. Capture the final review with `-o` — stdout is noisy (thinking, exec events, duplicated text); the `-o` file contains only the clean final review.

```bash
# PR / branch review (most common — diff vs base branch):
codex exec review --base <base-branch> -o /tmp/codex-review.md "<optional focus instructions>"

# Working-tree review (staged + unstaged + untracked):
codex exec review --uncommitted -o /tmp/codex-review.md

# Single commit:
codex exec review --commit <sha> -o /tmp/codex-review.md
```

- Get the base branch from `gh pr view --json baseRefName -q .baseRefName`, or the repo default branch if no PR exists. Use `origin/<base>` semantics — fetch first if stale.
- **Wait for it.** Reviews take 1–10 min depending on diff size. Set Bash timeout to 600000; for large diffs use `run_in_background: true` and wait for completion. Do not kill a run that is still producing output.
- `codex exec review` does NOT accept `-s/--sandbox` — it errors with "unexpected argument". The review subcommand manages its own sandbox and does not modify files.

## Step 3: Back and forth (optional, 1–3 turns max)

Resume the same session from the **same directory** (resume is cwd-scoped; `--all` disables the filter):

```bash
codex exec resume --last "<follow-up>" -o /tmp/codex-followup.md
```

Use follow-ups to: challenge a finding you believe is wrong, ask for severity/fix guidance on an ambiguous finding, or ask "anything else?" once. Don't loop endlessly.

## Step 4: Incorporate findings

Codex tags findings with priorities (`[P1]`, `[P2]`, …) and file:line references.

1. **Vet each finding before applying** — use the receiving-code-review skill. Codex is sometimes wrong; verify against the actual code.
2. Apply accepted fixes yourself with normal edits. Codex does not modify files in review mode.
3. For substantial fixes, optionally re-run Step 2 to confirm they land clean.

## Step 5: Shutdown and cleanup

`codex exec` exits on its own — there is no daemon or server to shut down. Cleanup is only:

- Kill the process if a background run hangs with no new output for ~10 min.
- Delete `/tmp/codex-review*.md` temp files.

## Output format (report to user)

1. **Verdict** — one line: clean / N findings, highest priority.
2. **Findings table** — priority, file:line, one-line issue, action taken (applied / rejected + why).
3. **Follow-up exchanges** — only if they changed a conclusion.

## Gotchas

| Symptom | Cause / fix |
|---|---|
| Shell hangs after running `codex` | You launched the interactive TUI. Kill it; use `codex exec review`. |
| "unexpected argument '-s'" | `review` subcommand doesn't take `--sandbox`. Drop the flag. |
| `resume --last` picks the wrong session | Resume filters by cwd. Run from the same directory as the review, or pass the session UUID. |
| Stale/old Codex behavior, missing flags | Check `brew outdated --cask codex`; upgrade via `brew upgrade --cask codex`. |
| "Not logged in" after upgrade | Token/auth migration. Hand off to user: `! codex login`. |
| Review output full of exec/thinking noise | Read the `-o` file, not stdout. |

## Out of Scope

- Does NOT post review comments to GitHub (use pr-review / share-pr-for-review for that).
- Does NOT automate `codex login` — always hand off to the user.
- Does NOT use Codex to write or apply fixes — Codex reviews; Claude edits.
- Does NOT manage ChatGPT account, plan, or rate limits.
