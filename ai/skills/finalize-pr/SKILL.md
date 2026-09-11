---
name: finalize-pr
description: Use as the last gate before a PR goes to human reviewers — "finalize this PR", "final checks before I share it", "is this PR ready for review", "clean this up before I tag people", "anything blocking on this PR". Also use when a PR has sat open collecting bot review comments and needs a sweep before it is merged or re-shared.
---

# Finalize PR

## Overview

The last gate before a human is asked to spend attention on this PR. Steps 1–7 audit and repair (commit hygiene is planned at 1b and executed at 6b, after the repairs land); each produces a verdict. Step 8 requests the review, and runs **only** on Sean's explicit sign-off — expect to run 1–7 two or three times before he gives it. A human reviewer's time is the scarce resource, so every problem caught here is one they would have caught instead.

**Nothing here is sampled.** Every comment, every bot thread, every hunk gets a verdict. "A lot of unneeded comments slip through" is what happens when an agent spot-checks and declares it clean.

Announce at start: "Using finalize-pr."

## Step 0: Resolve the PR and read the ground truth

```bash
gh pr view <n> --json number,title,url,body,baseRefName,headRefName,headRefOid,isDraft,mergeable,author
git fetch origin --prune
git diff origin/<base>...HEAD --stat
```

Set `BASE=origin/<baseRefName>` for every command below. Use `origin/<base>`, never the bare local branch name.

### Step 0b: Sync gate — audit the branch GitHub has, not the one on disk

Every step below reads the local working tree. A checkout behind the remote means you audit code that was already changed, and Step 7's reviewers come back with findings on work that has already landed. **`git fetch` does not fix this** — it moves `origin/<head>`, not your local branch.

```bash
git rev-parse HEAD
gh pr view <n> --json headRefOid -q .headRefOid
git status --porcelain
git rev-list --left-right --count HEAD...origin/<headRefName>   # "<local-only>	<remote-only>"
```

| State | Action |
|---|---|
| `0	0`, HEAD == `headRefOid` | Proceed. |
| `0	N` — behind | `git checkout <head>` then `git merge --ff-only origin/<head>`. Re-check, then restart Step 0. |
| `N	0` — unpushed local commits | **Stop.** You would audit and Step 7 would review code the PR does not contain. Sean decides: push, or drop them. |
| `N	M` — diverged | **Stop.** Report both counts. Never auto-reset or rebase. |
| Dirty working tree | **Stop.** Uncommitted edits are not in the PR, and Step 7's reviewers read them as if they were. |

`--ff-only` refuses on divergence, so a sync can never silently discard local commits.

Record the audited sha. It appears in the report, and Step 8 re-checks against it.

**Sibling repos too.** If the change depends on another repo — the other side of an API contract, a cookie or header the frontend writes, a shared package — fetch that repo and report its drift now. Step 7's reviewers grep sibling repos to check integration assumptions, and a checkout two commits behind turns into a confident "nothing sets this" P2. Fetch only; never `pull` a repo that is not under review.

```bash
for r in ~/supabase/supabase ~/supabase/platform; do
  d=$(git -C "$r" symbolic-ref --short refs/remotes/origin/HEAD | sed 's|origin/||')
  git -C "$r" fetch origin --quiet
  echo "$r ($d): $(git -C "$r" rev-list --count HEAD..origin/$d) behind"
done
```

`cross-model-review` Step 0c owns the full rule. This runs early so the drift is on screen before Steps 1–6, not discovered at Step 7.

## Step 1: Pre-push integrity (Sean's mandatory checklist)

From `~/.claude/CLAUDE.md`. This exists because stacked PRs silently absorb commits when the local base is ahead of `origin/<base>`.

```bash
git log --oneline $BASE..HEAD                    # exactly the commits you meant. 10+ when you expected 2 = STOP
git diff $BASE...HEAD --stat                     # size matches the scope of the change
gh pr view <n> --json commits,additions,deletions \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Commits: {len(d[\"commits\"])}, +{d[\"additions\"]}/-{d[\"deletions\"]}')"
```

GitHub's numbers must match what you saw locally. Larger → the PR is contaminated; say so and stop.

Session-link check — must return nothing:

```bash
git log $BASE..HEAD --format=%B | grep -inE '^[[:space:]]*Claude-Session:|https?://claude\.ai/code'
```

Keep the pattern anchored. An unanchored grep matches any commit that merely discusses the rule and trains you to wave the check through. If one landed and the commit is unpushed or the PR has no reviews: `git commit --amend` and `--force-with-lease`.

Title: conventional-commit prefix matching the repo's history (`git log $BASE --oneline -20`). Supabase frontend uses `fix(studio):`, `feat(growth):`, `chore(docs):`.

## Step 1b: Commit hygiene — assess (do not squash yet)

Reviewers who read commit-by-commit are reading a story. "fix lint", "address review", "oops" is not a story. This runs early so the plan is settled before any repair work, and **executes late** (Step 6b) because Steps 2–6 add their own commits.

```bash
git log --oneline $BASE..HEAD
git log $BASE..HEAD --format='%h %an <%ae> %s'   # author check, see safety rules
```

Target shape:

| Commits | Action |
|---|---|
| 1 | Nothing. This is the goal. |
| 2–3, each a coherent unit with a real message | Leave it. Multiple commits are fine when each one is separately reviewable. |
| 2–3 where any is a fixup | Fold the fixups into their parent. |
| 4+ | Squash toward the smallest set of independently reviewable units. **Default to 1.** |

A commit is a fixup if its message matches the work rather than the change: `wip`, `fixup`, `squash`, `oops`, `typo`, `lint`, `format`, `nit`, `address (review|comments|feedback)`, `pr feedback`, `fix tests`, `revert` immediately followed by a redo.

Keep the leading `\b`. Without it, `nit` matches "recog**nit**ion" and `lint` matches nothing useful — a false positive here proposes rewriting history over a well-named commit, so the grep is a shortlist for your own reading, never the verdict.

```bash
git log --oneline $BASE..HEAD | grep -inE '\b(wip|fixup|squash|oops|typo|lint|format|nit)|address (review|comment|feedback)|pr feedback|fix(es)? tests'
```

Output a plan: current commits, proposed final commits, and the message for each. **Get Sean's approval on the plan. Do not rewrite history in this step.**

### Safety rules — all of them, every time

- **Never squash without explicit approval of the plan.** History rewriting is not a judgment call you get to make.
- **Never squash commits authored by anyone but Sean.** Check `%an`/`%ae` above. A co-authored or teammate commit means stop and ask.
- **Human review threads are a blocker.** Check for non-bot review comments (Step 4's query). A force-push marks their threads outdated and breaks the links reviewers are working from. If a human has reviewed, the default is **do not squash** — say so and let Sean decide. Bot threads do not count.
- Anyone else has this branch checked out → do not squash.

## Step 2: PR description matches the repo template

**Voice and structure are owned by `writing-pr-descriptions`. Read it and apply it.** Do not restate its rules. This step only decides whether the current body passes.

```bash
ls .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md .github/PULL_REQUEST_TEMPLATE/ docs/PULL_REQUEST_TEMPLATE.md 2>/dev/null
gh pr view <n> --json body -q .body
```

- **Template exists:** every section present, in the template's order, each actually answered. An unanswered heading is worse than no heading. Do not bolt on sections the template does not ask for.
- **No template:** fall back to the default structure in `writing-pr-descriptions` (Problem / Fix / Testing).

**Diff over 100 lines → a "What's inside" section is required.** Check the Step 1 diff stat. If the PR exceeds 100 changed lines and the body has no `What's inside`, write one per `writing-pr-descriptions` Step 4b: bullets ordered reviewable → skimmable → low-attention, `~N lines of <what>, <why this tier>`, each deep-linked. Generate the anchors rather than copying them:

```bash
git diff $BASE...HEAD --numstat
printf '%s' '<repo-relative path>' | shasum -a 256   # → /pull/<n>/changes#diff-<hash>
```

Under 100 lines, a `What's inside` section is noise — flag it for removal if one is there.

Then read the body against `writing-as-sean` and the no-mannered-prose rules. Flag and rewrite:

| Tell | Fix |
|---|---|
| Metaphor standing in for a statement ("a dial worth turning", "earns its keep", "load-bearing") | The literal thing |
| `not X, but Y` / `X, not Y` antithesis, in any ordering | Write the half you mean |
| Aphorism-shaped sentence carrying no fact | Delete |
| Rule-of-three cadence | Two items, or four |
| Chronology opener ("After deploying #123 we noticed...") | Lead with the cause |
| Flourish verbs: unlock, surface, land, unpack, lean into, double down | Plain verb |
| Emoji, marketing copy, "🚀" | Delete |
| `Resolves #123` / `Closes #123` | Reference the issue inline |
| A Testing claim for a command you cannot prove ran | Cut it, or write `unverified` |

That last row is the one that matters. A Testing section is what a reviewer merges on. If you cannot point at the command and its output, it does not go in.

Rewrite with `gh pr edit <n> --body "$(cat <<'EOF' … EOF)"`. Show Sean the diff of the body before writing it.

## Step 3: Comment audit — brutally strict

Enumerate every comment the diff **adds or changes**. Not a sample.

```bash
git diff $BASE...HEAD -U0 | grep -E '^\+' | grep -E '^\+\s*(//|#|/\*|\*[^/]|--|\{/\*)'
```

Group contiguous lines into one comment block — the grep splits block comments across lines and inflates the count. Then open each block in context; a comment can only be judged against the code it sits on.

**A comment survives only if it answers a question the code cannot.** Four grounds, and only these four:

1. **Why, over what.** It explains a decision a reader would otherwise undo. *"The 5-minute cap avoids treating token refresh time as signup time."*
2. **A non-obvious external constraint,** with a link or identifier: vendor bug, spec quirk, browser behavior, upstream API contract.
3. **A hazard.** *"Changing this order reintroduces GROWTH-853."*
4. **Required by tooling or convention:** `eslint-disable` with a reason, `ts-expect-error` with a reason, JSDoc on an exported public API, license headers.

**Delete on sight:**

| Pattern | Example |
|---|---|
| Restates the code | `// increment the counter` |
| Narrates the diff, addresses the reviewer | `// now uses positional keys`, `// removed the old call`, `// NEW:` |
| Section banner | `// ---------- helpers ----------` |
| Commented-out code | any |
| Temporal wording that rots | "for now", "temporary", "will refactor later" |
| `TODO` with no owner and no ticket | `// TODO: fix this` |
| Restates a name or type that already says it | `// the user id` above `userId: string` |
| Numbered step comments narrating each line | `// 1. fetch  // 2. map  // 3. return` |
| Doc comment re-spelling the signature | `@param userId The user id` |
| Cites a line number, a count, or a current value | "currently 3 variants", "see line 42" |
| Debug log with no group-id prefix | Sean's rule: a surviving debug log needs its `[x]` prefix. No prefix → delete the log |

**The rot test, applied to every survivor:** will this comment still be true after the next unrelated change to this file? If it names a count, a line, a current value, or a plan, it will not. Rewrite it to be invariant or delete it.

**Grandfather rule:** comments the diff does not touch are out of scope. Fixing them inflates the diff, which Step 5 will flag.

Output a table: file:line, the comment (truncated), verdict `KEEP` / `DELETE` / `REWRITE`, and for KEEP which of the four grounds it met. Apply the deletions.

## Step 4: No open automated reviews

CodeRabbit, Codex, Claude, Copilot, Greptile and friends post review threads depending on the repo. Every one must be **read, addressed, and replied to** before a human is asked to look.

First, confirm no bot is still working:

```bash
gh pr checks <n>                                  # a bot review in progress is not a green board
gh pr view <n> --json reviews -q '.reviews[] | "\(.author.login) \(.state)"' | sort | uniq -c
```

A pending automated review means **wait**. Finalizing before it posts is a false all-clear.

Then pull every unresolved thread:

```bash
gh api graphql -f query='query($owner:String!,$repo:String!,$number:Int!){
  repository(owner:$owner,name:$repo){pullRequest(number:$number){
    reviewThreads(first:100){nodes{id isResolved isOutdated path line originalLine
      comments(first:20){nodes{databaseId url body author{login}}}}}}}}' \
  -F owner=<owner> -F repo=<repo> -F number=<n> \
  --jq '.data.repository.pullRequest.reviewThreads.nodes[]
        | select(.isResolved==false)
        | "\(.comments.nodes[0].author.login) outdated=\(.isOutdated) \(.path):\(.line // .originalLine)\n\(.comments.nodes[0].body[0:400])\n---"'
```

Also check top-level conversation comments, where CodeRabbit posts its summary:

```bash
gh api repos/<owner>/<repo>/issues/<n>/comments --jq '.[] | "\(.user.login): \(.body[0:300])\n---"'
```

For each unresolved thread, one of three outcomes. Never a fourth:

- **Valid** → fix it, reply naming the commit that fixed it, resolve.
- **Wrong** → reply with the reason, resolve. Verify against the source first; bots are confidently wrong. Use `receiving-code-review` for the judgment and `review-pr-comments` to draft the reply.
- **Out of scope** → reply saying so and where it is tracked, resolve.

`isOutdated=true` with `isResolved=false` is the common leak: a later push fixed the code and nobody replied. It still needs a reply — an unresolved thread reads to a human as unaddressed.

```bash
# reply, then resolve
gh api repos/<owner>/<repo>/pulls/<n>/comments/<databaseId>/replies -f body='<reply>'
gh api graphql -f query='mutation($id:ID!){resolveReviewThread(input:{threadId:$id}){thread{isResolved}}}' -F id=<thread node id>
```

**Never resolve without replying.** Silent resolution destroys the record of why a finding was dropped. Show Sean the replies before posting them.

## Step 5: Scope-creep audit

Sean's rules: PRs under 100 lines; ship only what is verified to fix the stated problem; adjacent gaps become follow-up notes.

Walk the hunks. For each, name which sentence of the PR description it serves. A hunk that serves none is scope creep.

Do **not** delete it on your own judgment — it may be the thing Sean wants. Report it: hunk, what it does, why it is unrelated, and a one-line follow-up note he can file. Let him choose.

Diff over ~100 lines with no structural reason → say so and suggest the split.

## Step 6: Debug-artifact sweep

```bash
git diff $BASE...HEAD | grep -nE '^\+.*(console\.(log|debug|dir)|debugger|\bdbg!|print\(|pp )' 
git diff $BASE...HEAD | grep -nE '^\+.*(\.only\(|\.skip\(|fdescribe|fit\()'
git diff $BASE...HEAD | grep -nE '^\+.*(localhost|127\.0\.0\.1|ngrok|\.local:[0-9])'
git diff $BASE...HEAD | grep -niE '^\+.*(api[_-]?key|secret|token|password|bearer)\s*[:=]\s*["'"'"'][^"'"'"']{8,}'
```

- `console.log` → delete, unless it is a real product log. A surviving debug log needs its `[x]` group-id prefix.
- `.only` / `.skip` on a test → blocking. `.only` silently disables the rest of the file in CI.
- Hardcoded local URL → blocking unless it is fixture data.
- Any credential-shaped literal → **stop the skill**, tell Sean, do not paste the value into chat or a commit.

## Step 6b: Commit hygiene — execute

Now, after Steps 2–6 have landed their edits, so the cleanup commits get folded in rather than left behind.

Record the escape hatch first:

```bash
git rev-parse HEAD                                    # write this down in the report
git branch backup/pre-squash-$(date +%Y%m%d-%H%M) HEAD
```

**Squash to one** — the default, and non-interactive:

```bash
git reset --soft $(git merge-base HEAD $BASE)
git commit -m "<type>(<scope>): <subject>"
```

**Squash to N groups** whose files don't overlap — reset then commit in stages:

```bash
git reset --soft $(git merge-base HEAD $BASE)
git add <paths for group 1> && git commit -m "..."
git add <paths for group 2> && git commit -m "..."
```

`git rebase -i` is unavailable in this environment — interactive flags are not supported. Use `reset --soft`. If groups genuinely interleave within the same files, say so and leave the history alone rather than reaching for a rebase you cannot drive.

Then:

```bash
git push --force-with-lease
```

Never bare `--force`. `--force-with-lease` refuses if the remote moved, which is the only thing standing between a squash and destroying someone else's push.

**Re-run two Step 1 checks after squashing. Squashing concatenates commit messages, so both can newly fail:**

```bash
git log $BASE..HEAD --format=%B | grep -inE '^[[:space:]]*Claude-Session:|https?://claude\.ai/code'
gh pr view <n> --json commits,additions,deletions
```

A `Claude-Session:` trailer buried in a fixup commit gets dragged into the squashed message. This is the most likely way that rule gets violated, and only this re-check catches it.

Sean's fresh-branch hook can block `git commit` on a stale or foreign branch. If it fires, relay what it said — do not work around it.

## Step 7: Cross-model review, one last pass

Invoke the `cross-model-review` skill against the finalized diff. This is the launch-blocker sweep and it runs **after** Steps 1–6, so the reviewers see the cleaned-up diff rather than reviewing comments you were about to delete.

**Push first, then re-run the Step 0b sync gate.** Steps 2–6b add commits and Step 6b rewrites history, so the sha you audited at Step 0 is not the sha on disk now, and neither may be what is on the remote. Reviewers that read a stale tree produce findings on work already done — the single most common failure of this skill.

```bash
git push --force-with-lease          # or plain push if 6b did not rewrite
git rev-parse HEAD && gh pr view <n> --json headRefOid -q .headRefOid   # must match
git status --porcelain                                                   # must be empty
```

Mismatch → fix it before spawning either reviewer. Pass the confirmed sha into `cross-model-review` and quote it back in the model receipt.

Read its adjudicated output. The only question here is narrower than that skill's: **is anything launch-blocking?**

**An absence finding is not launch-blocking until you re-check it yourself.** "Nothing sets X", "no caller", "unused flag" — re-run `git grep X origin/<default>` in the named repo before treating it as a P1. That class of finding is the one most often produced by a stale sibling checkout, and it is the most convincing when wrong.

- `CONFIRMED` P1 → blocking. Name it, fix it, re-run Step 7.
- `CONFIRMED` P2 → Sean's call. Recommend, do not decide.
- P3 → follow-up note.

## Steps 1–7 end here. Stop.

After the report, **stop**. Do not continue to Step 8, do not offer to, do not treat a clean board as permission. Sean re-runs 1–7 after pushing fixes, usually more than once, and each run must end with him holding the decision.

## Step 8: Request review — gated on explicit sign-off

**Three preconditions. All three, every time:**

1. **Sean asked for it, unambiguously.** "Share it", "request review", "post it", "ship it", "step 8", "go". A reaction to the report is not a request: "looks good", "nice", "lgtm", "thanks", "ok" all mean he read it, not that he wants it posted. Unsure? Ask in one line and wait.
2. **The last run's verdict was `READY`.** Any `BLOCKED` step means no. Unresolved P2s he declined are fine — they were his call.
3. **The sign-off is not stale.** Re-check that HEAD still matches what Steps 1–7 audited:

```bash
git rev-parse HEAD && gh pr view <n> --json headRefOid -q .headRefOid
```

Different from the run you reported on? The sign-off was for a different diff. Re-run 1–7 and say why, rather than sharing an audit that no longer describes the PR.

Then invoke the **`share-pr-for-review`** skill. It owns the message format (`:open-pr:` prefix, `:smol:` sizing, lowercase bullets) and it writes the finished message to a Bear note tagged `pr-share`, because pasting into Slack out of a terminal transcript mangles it.

Feed it what Steps 1–7 already established, so it does not re-derive the PR: the URL, the final diff stat (for the `:smol:` call), and the two-or-three-line substance of what changed. Any P2 Sean declined and any follow-up from Step 5 that a reviewer should know about belongs in the message as context.

This skill does not post to Slack. Bear note, then Sean pastes.

## Output format

One report. Verdict line first.

**Verdict:** `READY` / `BLOCKED (n)` — one line on what blocks it.

| # | Check | Result |
|---|---|---|
| 0b | Branch sync | PASS — audited `a1b2c3d`, matches PR head, tree clean |
| 1 | Pre-push integrity | PASS — +85/-14, GitHub agrees, no session links |
| 1b | Commit hygiene (plan) | 7 commits → 1 proposed; 4 are fixups |
| 2 | Description vs template | REWRITTEN — 3 sections were empty, added What's inside (+815 lines), cut 2 mannered phrases |
| 3 | Comment audit | 11 blocks: 4 KEEP, 6 DELETE, 1 REWRITE |
| 4 | Open automated reviews | 2 CodeRabbit threads addressed + replied; CodeRabbit check green |
| 5 | Scope creep | 1 unrelated hunk — follow-up note below |
| 6 | Debug artifacts | PASS |
| 6b | Commit hygiene (done) | squashed 7 → 1; backup at `abc1234`; session-link recheck clean |
| 7 | Cross-model review | re-synced to `e4f5a6b` before launch; 1 CONFIRMED P2, 0 P1 |

Step 8 is not in this table. It has not run — it runs on sign-off, after this report.

Then, in order:

1. **Changes made** — file, what changed, one line each. Comment deletions can be one grouped line with the count.
2. **Blocking** — numbered, each with the fix. Empty if `READY`.
3. **Sean's call** — P2s and scope-creep hunks. Recommendation each, not a decision.
4. **Follow-ups** — one line each, ready to paste into Linear.
5. **Model receipt** — from Step 7.

## Red flags — stop and redo the step

- Running any step against a local branch that is behind `origin/<head>` — Step 0b exists for this
- Treating `git fetch` as having synced the branch
- Launching Step 7 without pushing and re-running the sync gate first
- Spot-checking comments instead of enumerating all of them
- Resolving a bot thread without replying
- Declaring Step 4 clean while a bot review is still pending
- Writing a Testing section for a command you did not watch run
- Deleting a scope-creep hunk instead of reporting it
- Running Step 7 before Steps 1–6, so the reviewers audit code you then change
- Bolting sections onto a repo template that does not ask for them
- Shipping a 100+ line PR with no `What's inside`, or hand-copying diff anchors instead of generating them
- Running Step 8 off "looks good", or off a report that predates the current HEAD
- Offering to run Step 8 instead of stopping after the report
- Squashing in Step 1b instead of planning there
- Squashing without approval, or after a human has left review comments
- Using bare `git push --force`
- Skipping the post-squash session-link re-check
- Pasting the share message into the session only, when `share-pr-for-review` is supposed to write it to Bear

## Gotchas

| Symptom | Cause / fix |
|---|---|
| `line` is `null` on a review thread | Thread is on an outdated diff position. Fall back to `originalLine`. |
| Comment count looks inflated | The grep splits block comments per line. Group contiguous lines first. |
| `gh pr checks` green but a bot has posted nothing | The bot's check may report `pass` before the review lands. Cross-check `reviews`. |
| A reviewer reports "nothing references X" across repos | Sibling repo checkout is behind. Re-check with `git grep X origin/<default>`; do not block on it until you have. |
| Review findings describe code already fixed | The reviewed tree was stale. Re-sync per Step 0b and re-run Step 7; do not hand-filter a stale report. |
| `merge --ff-only` refused | Histories diverged. Stop and report; never `reset --hard` a branch you did not create. |
| GitHub's diff is bigger than local | Local base is ahead of `origin/<base>`. Classic stacked-PR contamination. Step 1 catches it. |
| Resolve mutation rejected | `resolveReviewThread` needs the thread's GraphQL **node** `id`, not the comment `databaseId`. |
| An unresolved thread is `isOutdated=true` | Already fixed by a later push, never replied to. Still reply, then resolve. |
| Squashed message now contains a `Claude-Session:` trailer | It was in a fixup commit and got concatenated. Step 6b's re-check exists for exactly this. Amend and `--force-with-lease`. |
| `git rebase -i` does nothing / hangs | Interactive git flags are unavailable here. Use `git reset --soft`. |
| `--force-with-lease` rejected | The remote moved since you fetched. Someone pushed, or a bot amended. Re-fetch and re-assess; do not escalate to `--force`. |
| Step 6 greps abort the rest of your command | `grep` exits 1 on no match. Run each grep as its own command, never chained with `&&`. Exit 1 there means clean. |

## Out of Scope

- Does NOT run the code review itself — Step 7 delegates to `cross-model-review`.
- Does NOT write the PR description from scratch — `writing-pr-descriptions` owns that; this checks and repairs.
- Does NOT post to Slack. Step 8 delegates to `share-pr-for-review`, which writes a Bear note; Sean pastes it himself.
- Does NOT assign reviewers or request review on GitHub.
- Does NOT merge, rebase, or force-push without Sean saying so, beyond the Step 7 push of its own repairs.
- Does NOT resolve a diverged or dirty branch on its own — Step 0b stops and hands the decision to Sean.
- Does NOT write the bug journal or investigation entry — separate completion ritual.
- Does NOT touch comments outside the diff, or refactor code it merely dislikes.
- Does NOT run the test suite or typecheck as its own gate — `ship-pr` does that upstream. This reads their results.
