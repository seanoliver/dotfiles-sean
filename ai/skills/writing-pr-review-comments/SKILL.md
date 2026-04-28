---
name: writing-pr-review-comments
description: Use when authoring an inline PR review comment, suggestion, or feedback message destined for GitHub or a teammate — applies whether triggered by the pr-review skill or used standalone.
---

# Writing PR Review Comments

## Overview

Ship comments that read like a thoughtful senior engineer noticing something — not a pedantic reviewer issuing a ruling. Lead with the point. Cut the investigation. Stay collaborative.

The author already knows their code. Your comment exists to surface something they should *consider* — not to prove you understood the diff.

## When to Use

- Authoring an inline GitHub review comment
- Drafting a PR review comment in any form (pending review, suggestion, mid-conversation)
- Writing a code review note in Slack threads
- The pr-review skill invokes this before each inline comment

## Out of Scope

- Writing PR descriptions — different format, see CLAUDE.md PR description guidelines
- Replying to comments left on YOUR PR — use review-pr-comments skill
- Composing the overall review summary or verdict — those live in terminal output, not as inline comments
- General async-message drafting outside code review — use message-crafter

## Output Format

Every comment must be:

- **2–5 short sentences.** Rarely more.
- **Bullets only when listing 3+ truly separate items.** Otherwise prose.
- **Prefixed** with one of: `Nit:`, `Quick question:`, or `FYI` (integrate inline — `FYI:` and `FYI from last week, not blocking:` both work). No prefix for a real bug.
- **Paragraph-broken** if it's longer than 2 sentences. Two short paragraphs reads better in the GitHub UI than one dense block.
- **Ready to paste.** No internal references, no `~/...` paths, no private investigation docs.
- **Linkable.** If you cite something, link it (PR, issue, Slack permalink) — but only if teammates can access it.

## Decision Framework

Pick the comment shape from what kind of finding it is:

| Finding type | Comment shape |
|---|---|
| Real bug | Direct but collaborative. "This will break when X — Y handles it elsewhere." No `Nit:` or `Quick question:` prefix. |
| Possible product / API decision | "Quick question: do we want X or Y here?" Frame as a choice, not a verdict. |
| Observability / telemetry change | One-sentence consequence. "Heads up — this strips Sentry alerts for that path. Is that what we want?" |
| Type / test cleanup | "Nit: ..." Keep it short. Say "not a big deal" if it isn't. |
| Context only, no action needed | "FYI, not blocking: [point]. Nothing to change here." |

## Voice Rules

**Do:**

- Lead with the actual finding, not the path you took to find it.
- **Trust the reader.** They wrote the code. They know how TypeScript narrowing works, what `draft/uploaded/processing` statuses mean, and what's repeated across four return statements. State the conclusion; don't re-derive it for them.
- **Compress technical lists to their concept.** "first-send retries" beats "draft/uploaded/processing docs (no reminder flag) plus the new reminder_sent path (with reminder: true)." The full list is in the diff.
- Use "could" / "might" instead of "should" — unless it's a definite bug.
- Frame product calls as "do we want this?" instead of "this is wrong."
- Say "not blocking" or "nothing to change" explicitly when it isn't.
- Keep certainty proportional to evidence. "Probably fine, but…" is fine when you mean it.

**Don't:**

- Open with the investigation ("Pre-PR... post-PR...", "Looking at line X...", "I traced through the lib and...").
- Use **arguably**, **technically**, **semantics**, **regression**, **deliberate fall-through**, **worth thinking through**, **flagging explicitly** — unless no simpler word works.
- Stack caveats. "Not blocking, just wanted to flag, but worth noting that, though probably..." → pick one.
- Re-explain code the author obviously wrote on purpose.
- Reference local files, personal investigation docs, or anything outside the team's reach.
- Sound like you're trying to win the review.

## Before / After

**Verbose investigation → punchy point**

> ❌ Question: the other two functions go 20 → 50 (2.5×); this one removes the inner brake entirely, so effective cap goes from 50 → 100 (2×). PR description calls it out as redundant inner slice removed, which is true given the outer 100 — but it does mean startGracePeriods is no longer rate-limited symmetrically with imposeRestrictions. With endGracePeriods still capped at 50 (line 138, untouched), feeding 100/run into grace_period means orgs will queue at the next stage until grace expires. Probably fine since grace periods are days, but worth confirming this asymmetry is intentional vs. just a side-effect of dropping the redundant slice.

> ✅ Quick question: the other two functions go from 20 → 50, while this one effectively goes from 50 → 100. The removed inner slice does look redundant given the outer limit, but it means this path is no longer capped the same way as the others. Probably fine, but wanted to check whether that asymmetry is intentional.

**Observability change → one-sentence consequence + concrete suggestion**

> ❌ Question: observability change worth thinking through. Pre-PR, an updateRestrictionStatusOrThrow failure bubbled to Sentry.wrapHandler and produced a Sentry alert plus a Lambda invocation error. Post-PR, those failures become CloudWatch console.error lines — invisible to Sentry unless someone wires up the metric filter mentioned in the PR description. That trade is defensible (you want one bad org to not abort 49 others), but you can keep both by adding Sentry.captureException(error, { tags: ... }) inside the catch...

> ✅ Quick question: this change effectively strips Sentry errors and replaces them with console logs. Is that what we want? If we still want visibility in Sentry, we could keep it by adding something like `Sentry.captureException(...)` inside the catch while still letting the loop continue.

**Trust the reader → state the conclusion, not the mechanism**

The single most common failure mode. The author wrote the code; they know how their tools work. Don't re-derive their own knowledge for them.

> ❌ Nit: since the function has an explicit `Promise<DpaRequestResponseType>` return type, the `as const` casts on every `return` are redundant — TS will narrow against the discriminated union from the literal alone. Doesn't hurt anything; just a touch of noise repeated four times.

> ✅ Nit: since the function already has a `Promise<DpaRequestResponseType>` return type, the `as const` on each return isn't really needed.
>
> Doesn't hurt anything, just a bit of extra noise.

The "✅" version trusts the reader to know how TS narrowing works. It also drops "repeated four times" — that's visible in the diff.

**Compress lists to the concept**

When the diff shows a list, refer to it conceptually rather than re-listing every item.

> ❌ Quick question: this changes telemetry semantics. Pre-PR, `dpa_requested` only fired when `resultDocument.id !== existingDocument.id` (the voided/recreated branch). Post-PR it also fires for stuck-first-send (`draft` / `uploaded` / `processing`) without a `reminder` flag, plus the new `reminder_sent` path with `reminder: true`...

> ✅ Quick question: this slightly changes the meaning of the `dpa_requested` event.
>
> It used to only fire on recreate, but now it'll also fire for some first-send retries. That seems correct, but it will bump event volume a bit beyond what the PR description calls out.
>
> Might be worth noting so anyone comparing to historical data knows to filter on `properties.reminder`.

"first-send retries" carries the same conceptual weight as the three-status list — without forcing the reader to scan it.

**Stacked nits → split or simplify**

> ❌ Nit: getDpaSignedByEmail is mocked in the vi.mock factory but never referenced in any test — safe to drop. Also MOCK_USER = { gotrue_id: ... } as any could be as User (already imported transitively) for slightly less type erosion, but trivial.

> ✅ Nit: `getDpaSignedByEmail` is mocked but not used in any tests, so we could remove it. Also, `MOCK_USER` could be typed as `User` instead of `any` for a bit more type safety, but not a big deal.

**Coverage gaps → short ask, defer the detail**

> ❌ Question: coverage gaps worth considering — none are blocking, but they cover real states the controller handles: existing doc in document.error state, multiple existing docs, pollDocumentStatusAndSend timeout. Likely ok to defer, since the lib has its own tests, but flagging for visibility.

> ✅ Quick question: do we want to add tests for a few edge cases here? Things like an error state, multiple existing docs, or a timeout on the create path. Not blocking, just flagging in case we want to tighten coverage later.

**Context FYI → strip private references, keep the point**

> ❌ FYI / context from last week — not a blocker on this PR, just so you're caught up: [long paragraph]. Full investigation in `~/supabase/docs/investigations/2026-04-23-...md`. I'm planning a follow-up...

> ✅ FYI from last week, not blocking this PR: we had a case where a DPA showed as "signed" in the dashboard but the underlying PandaDoc was incomplete. Support had to manually archive it so the customer could re-request. So this `already_signed` branch is technically correct based on PandaDoc status, but "signed" doesn't always mean "complete" from the user's perspective. Follow-up ticket: [GROWTH-XXX]. Nothing to change here, just flagging the context.

## Common Mistakes

| Symptom | Fix |
|---|---|
| Opens with "Pre-PR... post-PR..." | Cut. State current behavior and the question. |
| Cites `~/...` paths or local-only docs | Strip — replace with PR / issue / Slack permalinks if relevant. |
| Bundles 3+ unrelated points | Split into separate inline comments. |
| Ends with multi-sentence "but / however / though" trail | You're hedging. Pick one stance. |
| Author would respond "yes I know that" | You're explaining their own code back. Cut it. |
| Comment explains the mechanism (how TS narrowing works, what `draft/uploaded/processing` means) | State the conclusion only. Trust the reader to know the why. |
| Comment lists items the diff already shows | Compress to the concept. ("first-send retries", not "draft/uploaded/processing docs".) |
| Uses "should" for a non-bug | Switch to "could" / "might". |
| Cites file:line numbers as evidence | Trust the inline anchor — it's already pinned to the line. |
| Sentence count > 5 | Trim. Move detail into a follow-up if the author wants it. |
| One dense paragraph for a 4+ sentence comment | Split into 2 short paragraphs — easier to scan in the GitHub UI. |

## Workflow

1. Draft the comment as you naturally would.
2. Strip the investigation prelude — keep the point.
3. Pick a prefix: `Nit:` / `Quick question:` / `FYI` (integrate inline) / none for real bugs.
4. **Trust check.** For each sentence, ask: would the author respond "yes I know that"? If yes, cut it. State the conclusion only.
5. Re-read once: does it sound like a teammate or a judge? If judge, soften.
6. Check accessibility — no local paths, no private docs.
7. Sentence count check: 2–5. If over, trim.
8. Paste.
