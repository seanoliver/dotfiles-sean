---
name: writing-pr-descriptions
description: Use when writing or revising a pull request description, converting notes/diffs into a PR body, or cleaning up a verbose PR description into something a teammate can skim. Trigger on phrases like "write the PR description", "draft the PR body", "clean up this PR description", "turn this into a PR description", "rewrite the PR description", "use the team template".
---

# Writing PR descriptions

A PR description's job is to let a reviewer skim it in 60 seconds and leave knowing: (1) what changed, (2) why, (3) what to test. Everything else is decoration.

The work splits into two skills that compose: **voice** (conversational, like a thoughtful Slack message — no corporate speak, no marketing copy, no emoji) and **compression** (lead with cause, structure aggressively, cut chronology). Voice without compression produces friendly-sounding noise. Compression without voice produces clinical filler. You need both.

## Step 1 — Use the repo's PR template when one exists

**Always check for a repo PR template before writing.** Locations to look:

- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/pull_request_template.md`
- `.github/PULL_REQUEST_TEMPLATE/*.md` (directory of named templates)
- `docs/PULL_REQUEST_TEMPLATE.md`

If a template exists, **fill every section it asks for**, in the order it asks. The template is the team's house style and skipping it signals to reviewers that you didn't read the contributing docs. The rest of this skill's structure guidance is subordinate to the repo template — apply the compression principles to whichever sections the template asks for, but don't bolt extra sections onto a template that doesn't ask for them.

If no template exists, use the default structure in Step 4 as a starting point.

### Supabase/supabase repo template

For `~/supabase/supabase/` (the frontend monorepo), the canonical template is at `.github/pull_request_template.md`. As of this skill's creation it asks for:

1. **I have read the [CONTRIBUTING.md](https://github.com/supabase/supabase/blob/master/CONTRIBUTING.md) file.** — answer `YES` (don't skip; reviewers look for this)
2. **What kind of change does this PR introduce?** — pick from: Bug fix, feature, docs update, refactor, chore, etc. One word or short phrase.
3. **What is the current behavior?** — describe what's broken or missing. Link relevant issues.
4. **What is the new behavior?** — describe what the PR does. Include screenshots for visual changes.
5. **Additional context** — anything that doesn't fit above: rollout notes, related PRs, follow-ups, validation steps.

Re-read this template before writing; it may have evolved. If you find a section the live template asks for that this skill doesn't mention, prefer the live template.

## Step 2 — Voice and tone

**Voice is owned by the `writing-as-sean` skill. Read it and apply it.** It is the single source of truth for tone, phrasing, the em-dash ban, bullets-over-prose, and section-title style. Do not restate its rules here.

PR-specific additions only:

- **For testing**, describe what you actually tested, not formal test cases.
- No "Resolves #123" footers. Reference the issue inline or at the end.

## Step 3 — Lead with cause, not chronology

The first paragraph must answer **what broke, why, why this PR exists** — without storytelling. Chronology padding is the most common AI/junior-engineer tell and adds zero reviewer signal.

| Don't | Do |
|---|---|
| "After deploying #123 we noticed an uptick in..." | "A race between X and Y returns null Z." |
| "We started investigating and found that..." | State the root cause directly. |
| "It turns out the issue was..." | "The issue is..." |
| "After tracing through the logs, we eventually realized..." | State the finding. |

Compress timelines into causality. Replace "We noticed... then we found... this led us to realize..." with direct statements.

## Step 4 — Structure aggressively

If the repo has a template (Step 1), fill its sections. If it doesn't, the structure below is a reasonable default. Either way, **use named section headers and don't write giant prose blocks** — the reviewer should be able to jump to the section that answers their question.

The default structure has three core sections that nearly every PR needs, plus optional sections that you add only when the PR's context demands them.

**Core sections (use for nearly every PR):** Problem, Fix, Testing.

**Optional sections (include only when relevant):** Experiment / rollout impact, Post-deploy expectations.

Don't pad a PR with optional sections just to look thorough. A routine bug fix or refactor needs Problem / Fix / Testing and nothing else.

### Problem

What's wrong, root cause, user impact. One short paragraph or 2-3 bullets. **Lead with the cause, not the symptom timeline.** If there's load-bearing evidence (a metric, a query result, a screenshot), surface it here — don't make the reviewer hunt for it.

For complex bugs, the diagnosis is the load-bearing part. Show the reviewer how you know. But prefer **directional summaries over exhaustive evidence**:

| Don't | Do |
|---|---|
| "Every one of the 484 sampled events showed `project_ref` and `org_slug` null in context, with no exceptions across the entire 20-minute window" | "Affected events consistently lacked org/project context — the signup race signature." |
| "Bucketing rate was 1.02%, 1.16%, 0.94%, 0.88%, ..." | "Bucketing rate hovered around 1% before the fix." |

### Fix

Chosen strategy. **Collapse verbose implementation detail.** When multiple steps serve one conceptual purpose, summarize together; only expand if individual steps matter semantically.

| Verbose | Compressed |
|---|---|
| `- add field to decorator`<br>`- thread through function`<br>`- pass through middleware`<br>`- plumb into helper` | "Thread JWT `iat` through request auth into feature-flag person properties." |

**Keep the "why" for constraints.** Retain rationale that explains safety bounds, correctness, rollout decisions, fallback validity. Example: "The 5-minute cap avoids treating token refresh time as signup time."

If the change touches a non-obvious mechanism (a flag eval pattern, a cache invalidation strategy, an SDK behavior), explain the mechanism briefly. Future-them needs the why, not just the what.

### Experiment / rollout impact (optional)

**Include when:** the PR touches an experiment, A/B test, feature flag, audience filter, exposure event, or staged rollout. Also include if the change could affect data integrity for an in-flight experiment.

**Skip when:** the PR is a routine bug fix, refactor, dependency bump, docs change, or anything that doesn't interact with experiment infrastructure.

When you do include it, cover: whether data integrity is affected, what gating logic protects (or fails to protect) the change, expected behavior differences.

### Testing

What you actually verified. Prefer a **flat bullet list** when there are multiple paths; prefer casual narration when there's one or two ("Ran the e2e suite locally, all green. Spot-checked the new toggle in Chrome and Safari."). Don't write formal test cases. Don't list every test name — reviewers know what tests exist.

### Post-deploy expectations (optional)

**Include when:** the PR has a measurable post-deploy signal — a Sentry rate that should move, a conversion metric that should change, a dashboard to watch, a query to rerun on a timeframe. Also include for production hotfixes where reviewers need to know what "working" looks like after merge.

**Skip when:** the PR has no specific metric to track post-deploy. Most PRs don't need this section.

When you do include it, name what should improve, how validation works, what residual failures would mean. Examples:
- "The Sentry rate should drop from ~1,400/hr to single-digit. A non-trivial residual would indicate a non-race miss path we haven't covered."
- "Conversion rate for the new flow should land above 8%; under 6% means the audience filter is wrong."

If validation has a timeframe ("rerun query in 24h", "watch the dashboard through end of week"), name it explicitly.

## Step 5 — Compression heuristics

When compressing a draft into final form, aim for ~40-70% word reduction relative to a "thorough" first draft. The reduction comes from:

**Aggressively compress:**
- Deploy timelines and investigation chronology
- Repeated metric references (state once, refer back)
- Duplicated causal explanations
- Low-level plumbing details that don't change reviewer judgment
- Repeated mentions of the same invariant
- Balanced phrasings ("well beyond X and well below Y") — usually rewriteable as a single sentence

**Preserve verbatim:**
- Exact race condition descriptions
- Important schema/table names, exact identifiers
- Precise fallback behavior
- Rollout safety constraints
- Experiment gating logic
- Operational thresholds (cache TTLs, rate limits, timeouts)

## Step 6 — Defensive-phrase blacklist

These phrases add hedging and word count without adding signal. Replace with a direct statement or delete the sentence:

- "Worth noting that..." / "It's worth noting..."
- "As a heads up..."
- "Interestingly..."
- "Technically..."
- "It turns out..."
- "I'd argue that..."
- "Arguably..."
- "It could potentially..."
- "X is real" (as in "the concern is real", "the gap is real") — state the fact directly instead

## Step 7 — Pre-PR checklist

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

## Step 8 — Updating an existing PR description

Use `gh pr edit <number> --body "$(cat <<'EOF' ... EOF)"` rather than the web UI. This keeps the PR description versioned in commit-adjacent state and makes the rewrite reviewable in chat.

Read the existing description first (`gh pr view <number> --json body`) and identify what to preserve. If the existing description was written without the template, rewrite it FROM the template — don't bolt template sections onto an existing freeform body.

## Anti-patterns

| Don't | Do |
|---|---|
| Skip the repo's PR template because "it's a small PR" | Always use it. Reviewers expect it. |
| "This PR adds support for X" (template-violating opener) | Answer the template's "What kind of change" prompt directly. |
| Long narrative about what you were thinking while debugging | Lead with the finding. Trim the journey. |
| Open with chronology ("After deploying...") | Open with cause ("A race between X and Y...") |
| List every file changed | Describe the strategy. The diff shows the files. |
| Formal test case enumeration | "Ran the suite locally, all green. Spot-checked X in Chrome." |
| Emojis, "🚀", "✨", marketing copy | None of that. Sean's voice is dry. |
| "Resolves #123" or "Closes #123" footer with auto-linking phrasing | Just reference the issue inline or at the end; don't add closure keywords unless the repo conventions require them. |
| Re-deriving the bug story in the PR when it's documented elsewhere (Linear, bug journal) | Link to the diagnosis doc; summarize the conclusion in two lines. |
| Long balanced framings ("well beyond X and well below Y") | One direct sentence: "5 min covers the race; tokens live up to 1 hour." |
| Exhaustive enumeration of evidence | Directional summary: "Affected events consistently lacked org context." |
| Sub-bullets for parallel implementation steps that serve one purpose | Collapse into one sentence describing the strategy. |

## Output format

When the repo has no PR template, a finished description should look like:

```markdown
[Opening paragraph: 1-3 sentences. Lead with cause. State the symptom and root cause. Reference linked PRs/tickets inline.]

## Problem

[Optional expanded problem section if the opener didn't cover diagnosis. Or fold into opener if short enough.]

## Fix

[Strategy + key constraint rationale. Bullets if multiple changes; prose if one coherent change.]

- [Strategy bullet 1]
- [Strategy bullet 2]
- [Strategy bullet 3, with sub-bullets if a constraint needs explaining]

## Testing

[Flat bullet list of test paths, OR casual narration of what you verified.]

[Issue reference]
```

Add `## Experiment / rollout impact` and/or `## Post-deploy expectations` only when the PR's content meets the inclusion criteria for those sections (see Step 4). For a routine bug fix, the three core sections above are the whole shape.

When the repo HAS a template, fill the template's sections in its order. Apply the compression principles (Steps 3, 5, 6) to whichever sections it asks for. Don't add the optional sections above unless the template invites them (often under a freeform "Additional context" section).

Aim for ~300-500 words total for a focused PR. Larger refactors may run longer; one-line fixes may need less.

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

## Out of scope

This skill does NOT cover:

- **Commit messages** — different shape and audience. Commit messages live forever in `git log`; PR descriptions are for the reviewer in the moment. Use the project's commit-message conventions instead.
- **PR review comments** — use the `writing-pr-review-comments` skill for inline review feedback.
- **Release notes** — those have a different shape (user-facing changelog vs reviewer-facing PR body).
- **Slack messages announcing the PR** — use the `share-pr-for-review` skill.
- **The actual code review** — separate skill (`pr-review` or `growth-pr-review` depending on context).
