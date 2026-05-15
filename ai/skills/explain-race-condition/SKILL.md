---
name: explain-race-condition
description: Use when the user asks to explain a race condition, debug timing-related concurrency, clarify why ordering matters in a system, or correct a partial mental model of why two operations interact badly. Trigger on phrases like "explain the race", "is this a race condition?", "why does X happen before Y?", "are we sure the timing isn't the issue?", "walk me through what's happening step by step".
---

# Explain a race condition step-by-step

Race conditions are hard to explain clearly because three things get conflated:
1. **The participants** — which two operations are actually racing
2. **The timeline** — what fires first in wall-clock time vs what depends on what
3. **The post-hoc view** — what the data looks like *after* the race resolved, vs what the system saw at the moment of the bug

Most "race condition" explanations fail by skipping step 1 ("it's a timing thing") or by stepping through the sequence without ever naming the two racers. This skill produces an explanation a reader can follow cold, in the same shape the user already validated as helpful: numbered steps, load-bearing step marked, post-hoc view distinguished from the in-flight view, mechanism-of-fix explained, validation path named.

## The 8-part template

Use each section in order. Skip a section only when the situation genuinely doesn't have that piece (e.g. no prior mental model to correct).

### 1. Correct the wrong mental model up front (if present)

If the user offered a hypothesis, address it directly in the first sentence: "Not quite — the race isn't X. It's Y." Don't bury the correction at the end. If the user hasn't offered a hypothesis, skip.

### 2. Name the two participants explicitly

One sentence: "The race is between **A** and **B**." A and B should be the smallest concrete operations that actually race. Examples of well-named participants:

- An async write to a database vs a synchronous read from the same database
- A network response arriving vs a component unmounting
- A cache invalidation vs a cache hit
- A subscription firing vs a component-state update applying
- A flag-property persistence vs a flag-evaluation request

If you can't name A and B in one sentence, you don't understand the race yet — go back to reading the code.

### 3. Step through the BUGGY sequence with numbered steps

Number every operation. Use mechanism verbs ("fires", "triggers", "writes", "reads", "evaluates", "caches") not abstraction verbs ("happens", "occurs", "is set").

For each step, be explicit about which actor does it (the SDK, the server, the user, the database). When there's a server/client split, say which side every step is on.

**Mark the load-bearing step in bold** with a one-line annotation. The load-bearing step is the one where the race actually happens — the moment where the timing relationship turns into a bug. If you can't find the load-bearing step, you're describing a sequence, not a race.

### 4. State when this triggers, and how often

"This bug fires when [specific precondition], in roughly X% of cases."

Hand-waving here is a sign you don't yet have the empirical evidence to validate the model. If you don't have a frequency estimate, say so — don't invent one.

### 5. Distinguish the post-hoc view from the in-flight view

Race conditions create a gap between what the system saw at the moment of the bug and what data shows after the fact. Name both views.

Example: "My post-hoc query saw 18,000 users matching the cohort. But at the moment the flag evaluated, only ~26% of those users *looked* in-cohort to the server. The other 74% had stale persisted state at eval time but caught up by query time."

This step is often what unlocks the user's understanding. They've been looking at the post-hoc view, which makes the bug look like one thing; the in-flight view makes it look like a different thing. Both are real; they just describe different moments.

### 6. Explain the fix as a new numbered sequence

Same numbered-step format as the buggy sequence. Show what changes. Identify the new load-bearing step (the one that breaks the race).

Make the mechanism explicit: "The fix doesn't depend on [old timing assumption] at all because [new arrangement]." If the fix relies on a specific platform behavior (e.g. "PostHog's /decide accepts person_properties in the request body"), name that behavior — that's the load-bearing claim the fix depends on.

### 7. Distinguish theoretical from empirical validation

Two halves, both required:

- **Theoretical:** why the mechanism is sound, citing documented behavior, source code, or specs. If your confidence rests on a single claim about how a system behaves, name that claim plainly.
- **Empirical:** how to verify in production. A specific query, network trace, log line, or metric. Include a timeframe ("rerun the diagnostic in 24h").

Never substitute one for the other. "It should work" is not validation.

### 8. Calibrate the user's intuition

If the user had a hypothesis, name the specific axis on which they were off. "Your intuition was X, the reality is X' — same shape, different unit." This corrects without making them feel wrong, and gives them a sharper model for next time.

If their hypothesis was a complete miss, just acknowledge what they were trying to get at, then redirect.

## Anti-patterns

| Don't | Do |
|---|---|
| "It's a timing issue." | Name the two participants and the ordering. |
| "Sometimes A finishes before B." | Say *what* A and B are doing and *what* depends on the order. |
| Use "race condition" without naming which two operations race. | Always name them in step 2. |
| Explain only the bug without explaining why the fix works. | Step 6 is required, not optional. |
| Say "the fix should work" without empirical validation criteria. | Step 7 names a specific query/trace/metric to watch. |
| Treat post-hoc data as ground truth for what the system saw at bug time. | Step 5 distinguishes the two views explicitly. |
| Bury the corrected mental model at the end. | Lead with the correction in step 1. |

## Worked example

User asked: "are we saying the race is happening because in 75% of cases the 2nd decide call is completing BEFORE the first decide call?"

The good explanation (from a real session, 2026-05-15):

> Not quite — the race isn't `/decide` calls completing out of order. They complete in the order they fire. The race is between **server-side persistence of `/decide` #1's `$set` properties** and **server-side evaluation of `/decide` #2**.
>
> Step by step:
> 1. SDK fires `identify(uid, { gotrue_id, signup_timestamp })`
> 2. SDK sends `/decide` #1 with `person_properties: { gotrue_id, signup_timestamp }`
> 3. Server evaluates `/decide` #1's flag using request body + persisted person. `org_count` is nowhere yet → audience fails → returns `false`. (Fine — exposure gate still waiting.)
> 4. **Async: server ingestion writes `signup_timestamp` to the persisted person record.** Takes some unknown time — usually fast, but not synchronous with the `/decide` response.
> 5. ...time passes (orgs query loads)...
> 6. SDK fires `identify(uid, { org_count })`
> 7. SDK sends `/decide` #2 with `person_properties: { org_count }`
> 8. Server evaluates `/decide` #2 using request body + persisted person. **If step 4 hasn't completed**, the persisted record is still missing `signup_timestamp` → audience filter fails → returns `false`.
> 9. SDK caches `flag = false`. Exposure gate fires → exposure event captures `flag = false`.
>
> Why my post-hoc query shows the user as in-cohort even though they got `false`: by the time I queried, step 4 had completed. My query reads the persisted record (now populated), counts the user as in cohort. The exposure event already fired with the wrong value.
>
> 74% of cohort-matched users hit `false` → step 4 hadn't completed before step 8 in 74% of cases.
>
> **The fix:** include `signup_timestamp` in the identify call at step 6, so `/decide` #2's request body carries both audience properties. The server evaluates the audience filter against `request.person_properties ∪ persisted_person` — with both properties in the request body, the persisted-record state at eval time doesn't matter. The fix sidesteps the persistence-vs-eval race entirely.
>
> **Validation:** theoretical — PostHog documents that `/decide` accepts `person_properties` in the request body and merges them into flag evaluation. Empirical — rerun the diagnostic query 24h post-deploy, filtered to users who signed up *after the deploy timestamp*. Treatment share should approach 5%, not 0.87%.
>
> **Your intuition** was close in shape but off in unit: not "`/decide` #2 wins a race against `/decide` #1" but "the async write triggered by `/decide` #1 races the synchronous read inside `/decide` #2." Both are server-side timing races; the unit is persistence-vs-eval, not request-completion-order.

This explanation got the user from "wrong model, partially close" to "correct model, ready to ship the fix" in one read.

## When not to use this skill

- The user asks "what is a race condition in general?" (educational, not debugging) — give them a textbook definition, not this template.
- The bug isn't actually a race — it's a logic error or a config issue. Don't force-fit. If you can't name the two racing operations in step 2, the bug isn't a race; figure out what it actually is.
- The race is documented elsewhere already (a bug journal entry, an investigation doc) — link to that, don't re-derive.
