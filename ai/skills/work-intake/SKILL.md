---
name: work-intake
description: Use when Sean shares a meeting transcript, call recording notes, or a 1:1 recap and wants it turned into action items. Also use when a work session reaches a stopping point and Linear or Things 3 may now be stale, or when something learned mid-session contradicts what a ticket, task, doc, or memory file currently says. Covers Linear and Things 3.
---

# Work intake

Turn a source (a transcript, or a session's own history) into an accurate Linear and Things 3 state.

**Things holds the next physical action. Linear holds the work and its status.** They are not alternatives. Most items belong in both, at different granularities.

## The Iron Law

```
PRODUCE A PLAN. GET IT ANNOTATED. THEN WRITE.
```

Never create, update, close, cancel, or delete anything before Sean has replied to the plan. He wants back-and-forth in this loop, not headless execution. A plan he can say "no" to costs one message; a wrong write costs a cleanup and erodes trust in the tracker.

Reading state before the plan is not just allowed, it is required. The prohibition is on writes.

## Step 1: dispatch a fresh-context subagent (REQUIRED)

Do not do the extraction and state-check in your own context. Dispatch a subagent (Agent tool, `general-purpose`), read-only, and have it return findings plus a draft plan.

**Why this is not optional.** This was tested. An in-context operator who had been working for hours produced three errors in one intake: left a ticket In Progress whose decision the transcript had reversed, created a near-duplicate of a ticket created 3 hours earlier, and filed a ticket into no project when the obvious project existed. A cold subagent given the same transcript caught all three, unprompted, and opened its report by noting most of the work was cleanup rather than capture.

The failure mode is context pressure, not ignorance. You will feel like you already know what is in Linear. That feeling is the symptom.

Tell the subagent, explicitly:
- It may read anything (Linear, Things, files, GitHub) but must not write. Name the forbidden tools.
- Sean's setup: Things areas and their IDs, his Linear team, where docs and memory live.
- The source material, verbatim.
- To return a concrete plan: per item, what it would create or change, in which system, and why.

## Step 2: curate, subtractively only

Review the subagent's plan against what you know from the conversation. You may **cut** items, merge them, or flag them as questionable.

**You may not silently drop a contradiction it found.** Trimming a proposed new ticket is judgment. Dropping "this existing ticket now says something false" is the exact failure the subagent exists to catch. If you disagree with a contradiction finding, put it in the plan marked as disputed and let Sean decide.

## Step 3: the plan format

Format for annotation, not for reading. Sean replies inline, prefixing his comments with `SO:`. So: flat, one action per line, grouped by system, every item independently answerable.

```
## Linear

**Fix (contradicts a decision)**
- GROWTH-1234 — description says X; the call decided Y

**Create**
- <title> — one line on why, and what it unblocks

**Comment**
- GROWTH-5678 — what the comment records

**[DESTRUCTIVE] Close / cancel / reverse**
- GROWTH-9012 — reverse In Progress; the call reversed this decision

## Things
- Create: <title> (today | 🟠 On Me | anytime) — one line
- Update: <existing title> — what changes
- [DESTRUCTIVE] Complete/cancel: <existing title> — why

## Docs and memory
- <path> — what changes and why

## Not doing
- <item> — and why not
```

Mark anything destructive so he can scan for it. Closing, cancelling, reversing a status, reprioritising, or deleting all count. So does reversing work on a ticket someone else created, which needs his call rather than yours.

## Step 4: execute, then report

Execute exactly what he approved. Where he added context, use it. Where he said no, do nothing and do not relitigate.

Then report: what changed, and what you deliberately did not do. The skipped list matters as much as the executed one.

## Contradiction before addition

The default failure of intake is appending new items while stale ones keep asserting things that are now false. Reconcile first, add second.

Look for:
- A ticket description or a doc section stating a decision the source reverses.
- A ticket whose premise is now wrong (work already done elsewhere, or a blocker that turned out not to exist).
- A ticket In Progress whose work the source deprioritised, especially with an open PR.
- A claim in a doc or memory file that new evidence falsified.
- Something you asserted earlier in the session that turned out wrong.

A recorded claim that is now false is worse than a missing task. The task is absent; the claim actively misleads.

## Routing

| Item | Destination |
|---|---|
| An action only Sean takes | Things |
| Work others need to see, or whose status is public | Linear |
| Both, usually | Linear for the work, Things for the next action on it |
| Durable technical knowledge, how a system works | `~/supabase/docs/investigations/` |
| Design decisions and rationale for a build | `~/supabase/docs/plans/` |
| Expiring project state, a preference, a correction | memory file + MEMORY.md row |
| Where we left off this session | `sessions.md` only, never duplicated elsewhere |
| Anything a teammate asked not be broadcast | memory file, never a team-visible surface |

A Things task should carry the Linear URL. A Linear ticket must never depend on a Things task existing, because nobody else can see it.

Notion is deliberately out of the automatic path. Propose it explicitly if a stakeholder-facing artifact is warranted.

## Guardrails

- **Prefer a comment on an existing ticket over a new ticket.** Ticket sprawl is a real ceiling. One ticket per unit of work, not per discussion point.
- **Check whether the ticket already exists before proposing it.** Search by concept, not just by title.
- **Put new tickets in a project** if an obvious one exists. A ticket with no project is invisible in the view a teammate actually reads.
- **Do not assign work or ownership to teammates** in ticket text unless they agreed to it in the source.
- **Scheduling, calendar moves, and personal logistics go to Things**, never Linear.

## Red flags

These thoughts mean stop:

| Thought | Reality |
|---------|---------|
| "I already know what's in Linear" | This is the exact feeling that produced three errors. Dispatch the subagent. |
| "This is a small transcript, I'll just do it" | Small sources still contradict recorded state. |
| "I created that ticket an hour ago, I remember it" | You also missed one created 3 hours earlier by Sean. |
| "The subagent is overkill here" | It costs one dispatch. The cleanup costs more. |
| "I'll just make these few writes, they're additive" | Additive writes are where duplicates come from. |
| "He said do intake, so he means just do it" | He said he wants back-and-forth. Plan first. |

## Out of scope

- **Reading state to answer "what do I have open."** That is `work-sweep`. This skill writes; `work-sweep` reads.
- **Writing the session continuity log.** `sessions.md` is its own layer with its own trigger. Do not fold it in.
- **Drafting prose for anyone to read.** If an approved item is a message, ticket body, or doc, use `writing-as-sean` for the words.
- **Notion.** Explicit request only.
- **Deciding what the work should be.** This records decisions already made in the source. It does not invent scope.
