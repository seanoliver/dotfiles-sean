---
name: writing-pr-descriptions
description: Use when writing or revising a pull request description, converting notes/diffs into a PR body, or cleaning up a verbose PR description into something a teammate can skim. Trigger on phrases like "write the PR description", "draft the PR body", "clean up this PR description", "turn this into a PR description", "rewrite the PR description", "use the team template".
---

# Writing PR descriptions

A PR description's job is to let a reviewer skim it in 60 seconds and leave knowing: (1) what changed, (2) why, (3) what to test. Everything else is decoration.

Match Sean's voice as documented in `~/supabase/CLAUDE.md`'s "PR Description Guidelines": conversational, like a thoughtful Slack message to a teammate. No corporate speak. No marketing copy. No emoji. End on the issue reference, no formal sign-off.

## Step 1 — Use the repo's PR template when one exists

**Always check for a repo PR template before writing.** Locations to look:

- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/pull_request_template.md`
- `.github/PULL_REQUEST_TEMPLATE/*.md` (directory of named templates)
- `docs/PULL_REQUEST_TEMPLATE.md`

If a template exists, **fill every section it asks for**, in the order it asks. The template is the team's house style and skipping it signals to reviewers that you didn't read the contributing docs.

### Supabase/supabase repo template

For `~/supabase/supabase/` (the frontend monorepo), the canonical template is at `.github/pull_request_template.md`. As of this skill's creation it asks for:

1. **I have read the [CONTRIBUTING.md](https://github.com/supabase/supabase/blob/master/CONTRIBUTING.md) file.** — answer `YES` (don't skip; reviewers look for this)
2. **What kind of change does this PR introduce?** — pick from: Bug fix, feature, docs update, refactor, chore, etc. One word or short phrase.
3. **What is the current behavior?** — describe what's broken or missing. Link relevant issues.
4. **What is the new behavior?** — describe what the PR does. Include screenshots for visual changes.
5. **Additional context** — anything that doesn't fit above: rollout notes, related PRs, follow-ups, validation steps.

Re-read this template before writing; it may have evolved. If you find a section the live template asks for that this skill doesn't mention, prefer the live template.

## Step 2 — Voice and tone (from Sean's CLAUDE.md)

- Conversational. "Back in October we changed X" not "On October 17, 2025, the implementation was modified to X."
- Plain narrative. Skip background the team already knows.
- Use "we/our" instead of passive voice when natural.
- Specific about technical details but don't over-explain the obvious.
- Minor imperfections and casual phrasing are fine and signal a human wrote it.
- For testing, describe what you actually tested, not formal test cases.
- No emojis. No excessive formatting. No marketing copy. No "Resolves #123" footers (just reference the issue inline or at the end).

## Step 3 — Structure inside template sections

Most PR descriptions break down into three movements regardless of template shape:

### Problem

What's wrong, what we're fixing, why it matters. One short paragraph or a few bullets. If there's load-bearing evidence (a metric, a query result, a screenshot), surface it here — don't make the reviewer hunt for it.

For complex bugs, the diagnosis is the load-bearing part. Show the reviewer how you know the bug is what you say it is. A diagnostic narrative — "running query X showed Y; isolating Z confirmed it" — earns confidence faster than asserting the conclusion.

### Changes

What you did, usually as a few bullets. Don't restate the diff line-by-line; describe the strategy. Bullets are fine.

If the change touches a non-obvious mechanism (a flag eval pattern, a cache invalidation strategy, an SDK behavior), explain the mechanism briefly. Future-them needs the why, not just the what.

### Testing / Validation

What you actually verified. Casual narration: "ran the e2e suite locally, all green. spot-checked the new toggle in Chrome and Safari." If there's a post-merge validation step (rerun query in 24h, watch a metric, check a dashboard), name it explicitly with the timeframe.

Don't write formal test cases. Don't list every test name. Reviewers know what tests exist.

## Step 4 — Pre-PR checklist

Before opening the PR, run through Sean's PR Pre-Push Checklist from `~/.claude/CLAUDE.md`:

```bash
# 1. What commits will this PR include?
git log --oneline origin/<base-branch>..HEAD

# 2. What is the diff size?
git diff origin/<base-branch>...HEAD --stat

# 3. After creating the PR, verify GitHub agrees:
gh pr view <number> --json commits,additions,deletions
```

This is mandatory before every push. The most common failure it catches: stacked-PR contamination where `origin/<base>` is behind the local base and the PR ends up including unintended commits.

## Step 5 — When updating an existing PR description

Use `gh pr edit <number> --body "$(cat <<'EOF' ... EOF)"` rather than the web UI. This keeps the PR description versioned in commit-adjacent state and makes the rewrite reviewable in chat.

Read the existing description first (`gh pr view <number> --json body`) and identify what to preserve. If the existing description was written without the template, rewrite it FROM the template — don't bolt template sections onto an existing freeform body.

## Anti-patterns

| Don't | Do |
|---|---|
| Skip the repo's PR template because "it's a small PR" | Always use it. Reviewers expect it. |
| "This PR adds support for X" (template-violating opener) | Answer the template's "What kind of change" prompt directly. |
| Long narrative about what you were thinking while debugging | Lead with the finding. Trim the journey. |
| List every file changed | Describe the strategy. The diff shows the files. |
| Formal test case enumeration | "Ran the suite locally, all green. Spot-checked X in Chrome." |
| Emojis, "🚀", "✨", marketing copy | None of that. Sean's voice is dry. |
| "Resolves #123" or "Closes #123" footer with auto-linking phrasing | Just reference the issue inline or at the end; don't add closure keywords unless the repo conventions require them. |
| Re-deriving the bug story in the PR when it's documented elsewhere (Linear, bug journal) | Link to the diagnosis doc; summarize the conclusion in two lines. |

## Worked example

The `fix(telemetry): pass signup_timestamp on org_count identify` PR (supabase/supabase#46005) rewritten to use the template:

```markdown
## I have read the [CONTRIBUTING.md](https://github.com/supabase/supabase/blob/master/CONTRIBUTING.md) file.

YES

## What kind of change does this PR introduce?

Bug fix.

## What is the current behavior?

The `dataApiRevokeOnCreateDefault` experiment (GROWTH-853) flipped to 5%
rollout on 2026-05-14 22:59 UTC. First-day diagnostic on cohort-filtered
exposures showed treatment share at 0.87%, well below the 5% target —
about 5× under-bucketed.

Diagnosis: the two audience properties (`org_count` and `signup_timestamp`)
were being set on two separate `posthog.identify` calls. Identify #2's
`/decide` request body only carried `org_count`. The server-side person
record didn't yet have `signup_timestamp` persisted from identify #1
(ingestion is async), so the audience filter failed and the flag returned
`false` by default. About 74% of cohort users hit this race.

Pinned down by isolating filters: `org_count = 1` alone vs
`org_count = 1 AND signup_timestamp >= rollout` gives the same treatment
count (188 vs 190) but the control count halves (28,626 → 14,075). Same
numerator, smaller denominator → confirms ~14,500 users had `org_count`
matched at flag-evaluation time but `signup_timestamp` not yet landed
server-side.

## What is the new behavior?

The studio `Telemetry` component's `org_count` identify now also passes
`signup_timestamp` (sourced from `user.created_at`). That makes the
`/decide` request body self-sufficient for the audience filter — the
server can match `org_count = 1 AND signup_timestamp >= rollout` against
request `person_properties` regardless of whether the previous identify's
`$set` has been persisted yet.

Kept the existing `signup_timestamp` set in `useTelemetryIdentify` in
`packages/common/`. That hook runs in non-studio apps too (www, docs, cms)
and they still need `signup_timestamp` set for cross-app analytics.

## Additional context

Validation plan: rerun the cohort-filtered exposure-by-variant query in
PostHog 24h post-deploy, filtered to users who signed up after the deploy
timestamp. Treatment share should approach 5% vs 0.87% pre-fix. If it
doesn't, the assumption about `/decide` honoring request-body
`person_properties` is wrong and we need to dig further.

Tracking ticket: [GROWTH-858](https://linear.app/supabase/issue/GROWTH-858).
Live PostHog readout: https://eu.posthog.com/project/34344/insights/fBk4AZ1K.
```

Notice what's *not* in there: no race-condition theory deep-dive (linked to GROWTH-858 instead), no list of changed files, no formal test plan, no emoji, no closure keyword.

## When not to use this skill

- Drafting commit messages — different shape and audience. Commit messages live forever in `git log`; PR descriptions are for the reviewer in the moment.
- Writing PR review comments — use the `writing-pr-review-comments` skill for inline review feedback.
- Generating release notes — those have a different shape (user-facing changelog vs reviewer-facing PR body).
