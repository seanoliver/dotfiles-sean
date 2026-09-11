---
name: cross-model-review
description: Use when a code review should come from more than one frontier model — "cross-model review", "review this with Claude and Codex", "get two independent reviews", "dual review this PR", "have both models look at it", "second opinion from Codex too". Also use when a diff is risky enough that one reviewer is not enough before merge.
---

# Cross-Model Review

## Overview

Two reviewers read the same diff with zero shared context: a fresh Claude process on the newest Fable, and Codex on its top model. Both at **medium** reasoning — best model, moderate effort, because top tiers cost several dollars and rarely find more. You then adjudicate their findings into one verified recommendation set.

**Core principle: the value is in the disagreement.** A finding both reviewers raise is high-confidence. A finding only one raised is the one to verify hardest. Never concatenate the two reports — adjudicate them.

## Step 0: Resolve the target (read first)

Know exactly what is under review before spawning anything.

| Target | Resolve it with |
|---|---|
| PR number/URL | `gh pr view <n> --json headRefName,baseRefName,url`, then check out the head branch |
| Current branch vs base | base = `gh pr view --json baseRefName -q .baseRefName`, else `git symbolic-ref --short refs/remotes/origin/HEAD` |
| Uncommitted work | working tree — use `--uncommitted` in Step 2 |
| Single commit | the sha — use `--commit <sha>` in Step 2 |

```bash
git -C <repo> fetch origin
git -C <repo> diff origin/<base>...HEAD --stat
```

Record the repo root. Both reviewers run from there. Empty diff → stop and say so.

### Step 0b: Sync gate — the reviewers must see the current remote branch

**Both reviewers read the local working tree.** A local checkout that is behind the remote produces a review of code that was already changed. This has happened repeatedly: findings come back on a stale branch describing work that had already landed.

`git fetch` alone does not fix this. Fetch updates `origin/<head>`; it does not move your local branch. Run the comparison explicitly:

```bash
git -C <repo> fetch origin --prune
git -C <repo> rev-parse HEAD
git -C <repo> rev-parse origin/<headRefName>        # PR target: gh pr view <n> --json headRefOid -q .headRefOid
git -C <repo> status --porcelain                    # uncommitted work?
git -C <repo> rev-list --left-right --count HEAD...origin/<headRefName>   # "<local-only>	<remote-only>"
```

Act on the result. Do not proceed on a mismatch:

| State | Action |
|---|---|
| `0	0` — HEAD == remote head | Proceed. |
| `0	N` — behind only | `git checkout <head>` then `git merge --ff-only origin/<head>`. Re-check. |
| `N	0` — local commits not pushed | **Stop.** The reviewers would read code the PR does not contain. Sean decides: push first, or review the working tree deliberately. |
| `N	M` — diverged | **Stop.** Report both counts. Never auto-reset or rebase. |
| Dirty working tree, target is not `--uncommitted` | **Stop.** Uncommitted edits leak into every reviewer's read. |

`--ff-only` is the whole point: it refuses when the histories diverged, so a sync can never silently discard local commits.

Report the resolved sha in one line before launching, and repeat it in the model receipt. A review whose receipt does not name the sha it read cannot be checked later.

### Step 0c: Sibling-repo sync — the one that produces false findings

Reviewers do not stop at the diff. They go looking in sibling repos to check integration assumptions — "who actually sets this cookie?", "is this endpoint called anywhere?" That behaviour is wanted; it is how a real integration gap gets caught. It is also how a stale checkout two directories over manufactures a confident P2.

**Measured failure:** on `platform#38289`, both reviewers independently reported "nothing sets `bfcid`, zero references in `~/supabase/supabase`." The setter had merged to `origin/master` that morning. The local checkout was behind (`7014cd2` vs `26585dd`), so the file was not in the tree they grepped. Two runs, two vendors, same wrong finding.

Before launching, name every sibling repo the change depends on — the other side of an API contract, a cookie or header writer, a shared package, the client of an endpoint. In the hub, that is usually the other of `~/supabase/supabase` and `~/supabase/platform`. Then fetch each and report its drift:

```bash
for r in ~/supabase/supabase ~/supabase/platform; do
  d=$(git -C "$r" symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||')
  git -C "$r" fetch origin --quiet
  echo "$r ($d): $(git -C "$r" rev-list --count HEAD..origin/$d) behind, $(git -C "$r" rev-list --count origin/$d..HEAD) ahead"
done
```

Surface the result to the user **before** spawning anything: `~/supabase/supabase (master): 2 behind, 0 ahead`. Nonzero behind is not a stop — the reviewers are told to query refs, not the tree (Step 2) — but it is the single fact that explains a bogus absence finding, and it must be on screen before the run, not after.

Do not `git pull` a sibling repo to fix this. It is not the repo under review, it may carry someone else's work, and Sean's fresh-branch rules govern it. Fetch and report.


## Step 1: Discover the models. Never hardcode.

Both vendors ship models newer than your training data. Read the live catalog from each CLI on every run.

**Best model, medium reasoning.** Discover the model; pin the effort. Measured head-to-head (see Step 2), the top tier cost 1.7x more and took 2–12x longer for the same findings. Escalate only when the user asks or a first pass comes back thin.

**Codex** — `priority` ascending is most-capable-first. Confirm `medium` is still an offered tier:

```bash
command codex debug models | jq -r '[.models[] | select(.visibility=="list" and .supported_in_api==true)]
  | sort_by(.priority) | .[0] | "MODEL=\(.slug) TIERS=\([.supported_reasoning_levels[].effort]|join(","))"'
```

**Claude** — the help text lists aliases most-capable-first. An alias always resolves to the newest model in that family, so it picks up a release you have never heard of:

```bash
claude --help | grep -A4 -- '--model '   # take the FIRST alias
claude --help | grep -A2 -- '--effort'   # confirm 'medium' is still a valid tier
```

Escalation knob, if the user asks for depth: take the **last** entry of `supported_reasoning_levels` for Codex and the last `--effort` tier for Claude. Tell the user the cost before you do.

Codex preflight: `command codex login status` (exit 0 = fine) and `brew outdated --cask codex`. Not logged in → STOP; login is an interactive browser flow. Tell the user to run `! codex login` and wait.

Report both resolved selections to the user in one line before launching.

## Step 2: Launch both reviewers in parallel

Both calls go out in a **single message** with `run_in_background: true`. Never sequential.

Measured twice on the same 85-line, 2-file diff:

| | Codex | Claude (Fable) |
|---|---|---|
| medium | **58 s** | **3m45s**, 15 turns, $2.83 |
| top tier (`ultra` / `max`) | 12 min | 7m19s, 36 turns, $4.86 |

Both tiers found the same P2 and the same substantive P3s; the top tier added one cosmetic nit. That is why medium is the default. Budget 1–5 min and do not kill a run that is still producing output.

Use identical review instructions for both so the outputs are comparable:

> Independent code review of `git diff origin/<base>...HEAD`. Read the full surrounding files, not just the diff hunks. Report every finding as: severity (P1 blocker / P2 should-fix / P3 minor), `file:line`, the defect in one sentence, and a concrete failure scenario (inputs or state → wrong output). Skip style preferences unless they cause a defect. End with a short table of the claims you checked and found *sound* — this is as useful as the findings. Read-only: do not modify any file.
>
> **Absence claims must be checked against a remote ref, never the working tree.** Any finding of the form "nothing sets X", "X is referenced nowhere", "this endpoint has no caller", "the flag is unused" — in this repo or any other — is invalid unless you queried the remote branch. Local checkouts go stale; a file that merged this morning is not on disk. Use:
>
> ```bash
> git -C <repo> fetch origin --quiet
> D=$(git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||')
> git -C <repo> grep -n '<symbol>' origin/$D        # searches the ref, not the tree
> git -C <repo> log --oneline -5 origin/$D -S '<symbol>'
> ```
>
> `git grep <pattern> origin/<default>` is the command. A bare `grep -r`, `rg`, or a file-search tool reads the working tree and will report a false absence. State in the finding which ref you checked and at which sha; an absence claim with no named ref is dropped.

**Reviewer A — Claude, fresh process:**

```bash
cd <repo-root> && claude --model <alias> --effort medium -p \
  --permission-mode bypassPermissions --output-format json \
  "<review instructions>" > /tmp/xmr-claude.json 2>/dev/null
```

Use a subprocess, **not** the Agent tool: the Agent tool cannot set reasoning effort, and `-p` guarantees an empty conversation history. Project `CLAUDE.md` and conventions still load, which is wanted — add `--bare` only if the user asks for a review with no project context at all.

**Reviewer B — Codex:**

```bash
cd <repo-root> && command codex exec review --base origin/<base> \
  -m <slug> -c model_reasoning_effort="medium" \
  -o /tmp/xmr-codex.md > /tmp/xmr-codex.log 2>&1
```

Swap in `--uncommitted` or `--commit <sha>` for those targets.

**Always invoke Codex as `command codex`.** Sean's `.zshrc` aliases `codex` to `codex --dangerously-bypass-approvals-and-sandbox`, and that alias is live in the agent's shell. It would silently unsandbox a reviewer that only needs to read. `command` bypasses it. Side effect: `command -v codex` returns the alias text, so it is useless for finding the binary path.

`--base` is **mutually exclusive with a prompt argument** in codex ≥0.153 (`error: the argument '--base <BRANCH>' cannot be used with '[PROMPT]'`). That makes plain `codex exec` the **default form, not the fallback** — `exec review` cannot carry the absence-claim rule above, and a Codex reviewer that never receives it is the one that produced the `bfcid` finding. Use:

```bash
cd <repo-root> && command codex exec -m <slug> -c model_reasoning_effort="medium" \
  -s read-only -o /tmp/xmr-codex.md "<review instructions>"
```

Reach for `exec review --base` only when the review instructions are the stock ones and no absence claim is plausible — a self-contained diff with no cross-repo contract. When in doubt, plain exec.

## Step 3: Check the receipts

- Claude: `jq -r '.modelUsage | keys[]' /tmp/xmr-claude.json` — confirm the intended model ran. An incidental `claude-haiku-*` entry is title generation; ignore it. Findings are in `.result`.
- Codex: read `/tmp/xmr-codex.md`, never stdout — stdout carries thinking and exec-event noise.
- One reviewer produced nothing? Report the failure plainly. Do not consolidate a single review and call it a cross-model review.

## Step 4: Adjudicate every finding

For each finding from either reviewer:

1. Open the cited file and surrounding code. Confirm or reject it **against the actual source** — both models produce confident wrong findings.
2. Tag agreement: `both` / `claude-only` / `codex-only`.
3. Assign a verdict: `CONFIRMED`, `REJECTED` (+ the reason), or `NEEDS-SEAN` (unverifiable without access you lack).

Rules:

- **Every absence claim gets re-verified against `origin/<default>` before it gets a verdict.** This is not optional and it is not satisfied by the reviewer having said it twice. Absence findings are the class most likely to be an artifact of checkout state, and they are the most persuasive class when wrong — "nothing calls this" reads as exactly the integration gap a second reviewer is for. Both reviewers agreeing is not evidence here: they read the same stale disk.

```bash
git -C <repo> fetch origin --quiet
D=$(git -C <repo> symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||')
git -C <repo> grep -n '<symbol>' origin/$D
git -C <repo> log --oneline -10 origin/$D -S '<symbol>'   # when did it land?
```

  Hits on the ref → `REJECTED — present at origin/<default> as of <sha>, local checkout was <N> behind`. Name the sha; that is what makes the rejection auditable. This is the check that caught the `bfcid` finding.

- **Never drop a finding silently.** Every finding from both reviewers appears in the output with a verdict.
- A finding outside the diff's scope is a follow-up note, not part of the recommendation.
- Style nitpicks not tied to a defect are `REJECTED — noise`, and still listed.
- Do not edit code in this skill. The deliverable is the recommendation.

## Output format

Exactly three sections, in this order.

**1. Consolidated findings** — one table, `CONFIRMED` P1s first:

| # | Sev | Raised by | file:line | Finding | Verdict |
|---|---|---|---|---|---|
| 1 | P1 | both | `src/a.ts:42` | Null deref when `rows` is empty | CONFIRMED |
| 2 | P2 | codex-only | `src/b.ts:17` | Claimed race on `cache` | REJECTED — writes are serialized by the queue |

**2. Recommendations**

- **Taking:** finding #, and why.
- **Not taking:** finding #, and why.
- **Follow-ups (out of scope for this diff):** one line each.

**3. Implement**

Ordered, concrete change list — file, what to change, one line of rationale each. Nothing vague ("improve error handling" is not an item).

Close with a one-line model receipt: which model and effort each reviewer actually ran at.

## Red flags — stop and restart the step

- Launching reviewers without running Step 0b, or after seeing a mismatch there
- Treating `git fetch` as having synced the branch — it updates `origin/<head>`, not HEAD
- Reporting findings without naming the sha that was reviewed
- Naming a model from memory instead of running Step 1 discovery
- Launching the two reviewers sequentially
- Accepting an absence claim ("nothing sets X", "no caller") without re-querying `origin/<default>` yourself
- Launching without fetching the sibling repos the change depends on, and reporting their drift
- Treating agreement between the reviewers as verification of an absence claim — they read the same disk
- Presenting both reports side by side instead of one adjudicated set
- Calling it done when one reviewer failed

## Gotchas

| Symptom | Cause / fix |
|---|---|
| `'--base' cannot be used with '[PROMPT]'` | codex ≥0.153. Drop the prompt, or use plain `codex exec` (Step 2). |
| Shell hangs after `codex` | You launched the interactive TUI. Kill it; use `codex exec`. |
| Codex output full of thinking noise | Read the `-o` file, not stdout. |
| `unexpected argument '-s'` on `exec review` | The `review` subcommand manages its own sandbox. Drop `-s`. |
| Review cost more than expected | Fable bills ~$3 at medium, ~$5 at max, on a small diff — top tiers build large 1h prompt caches, so even a *trivial* `--effort max` call billed $1.12. Quote the cost before escalating. |
| Codex ran unsandboxed | You called bare `codex` and picked up the `.zshrc` alias. Use `command codex`. |
| Codex log shows `Rejected(...) rm -f style commands are not permitted` | Codex tried to run the repo's tests and hit execpolicy. It recovers on its own. Do not kill the run. |
| Codex "not logged in" after an upgrade | Auth migration. Hand off `! codex login`; never automate it. |
| Findings describe code already changed | The local branch was behind the remote. Step 0b exists for this. Re-sync and re-run; do not hand-filter a stale report. |
| `merge --ff-only` refused | Histories diverged. Stop and report; never `reset --hard` a branch you did not create. |
| Both reviewers agree and both are wrong | Usually a shared stale checkout, not a shared insight. Agreement raises confidence only for claims about the diff; for absence claims it means they grepped the same out-of-date tree. Steps 0c and 4 exist for this. |
| "Nothing references X" on a cross-repo integration | The setter/caller lives in a sibling repo whose local checkout is behind. Re-check with `git grep X origin/<default>`. Measured: `platform#38289`, `bfcid`, twice. |
| `git grep` returns nothing on a ref that should have it | Missing `fetch`, or the wrong default branch. `supabase` = `master`, `platform` = `develop`. Read it with `symbolic-ref`, do not assume. |

## Out of Scope

- Does NOT post comments to GitHub — use `pr-review` or `share-pr-for-review`.
- Does NOT apply fixes. It produces the recommendation; implementing is a separate task.
- Does NOT replace `claude ultrareview` (cloud multi-agent, single vendor) or `codex-review` (Codex alone). Use those when one vendor is enough.
- Does NOT run tests, typecheck, or lint. Those are verification, not review.
- Does NOT automate `codex login` or manage either vendor's plan and rate limits.
- Does NOT resolve a diverged or dirty branch on its own — Step 0b stops and hands the decision to Sean.
- Does NOT add a third reviewer. Two independent opinions plus adjudication; more is noise.
