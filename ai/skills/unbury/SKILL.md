---
name: unbury
description: Use after /shape-today, or when Sean says unbury me, what am I forgetting, what's falling through the cracks, anything burning, did I drop anything, or I have five minutes. Also use when he suspects the 🟠 On Me tag or the Anytime backlog has gone stale, when quick replies keep piling up undone, or when he asks to be shown things outside the Today list without rebuilding Today.
---

# Unbury

Surface the few buried items that are **burning, owed, or rotting**, one at a time, and clear the
two-minute ones **inside the conversation**. Everything else gets a disposition and a write back to
Things.

## Core principle

**Sean does not visit lists. Lists must come to him.**

He keeps Things open on the Today list all day and does not take the second step to open anything
else. A `Scan Soon` ritual — a daily task whose entire content was "go look at another list" — failed
every day it existed and was deleted on 2026-08-14. Do not rebuild that pattern in any form. Never
tell him to go check a list. Read it for him and bring him the items.

The second principle follows from the first: **the goal is completions, not decisions.** His quick
replies don't fail at triage, they fail at execution. They are already correctly filed. Asking "when
do you want to do this?" about a two-minute reply is the failure mode, not the fix. Do it with him,
now, and it never touches a list again.

## Hard rules

1. **Surface at most 5 items.** Most runs will be 1–3. If nothing clears the bar, say "nothing
   burning" and stop — a clean run is a real outcome, not a failed one.

   **A short time window is a reason to run, never a reason to defer.** "I've only got 5 minutes"
   means surface one item and clear it — that is a complete, successful run. Never answer with a
   promise to do a more thorough pass later. Observed in testing 2026-08-14: a baseline agent told
   Sean it couldn't do the job properly in 5 minutes and offered a full sweep "when you're back."
   He does not come back. One cleared item beats a scheduled sweep that never happens.
2. **One item at a time.** Present item, get disposition, apply it, then move to the next.

   **Never preview what's coming, in any form.** Not a table, not a bulleted list, not a
   parenthetical aside, not "three more quick ones are queued," not a count of what each one is. A
   preview is the menu wearing a disguise, and it stalls him exactly the same way. Observed in
   testing 2026-08-14: two separate agents obeyed "no table" and then listed the remaining four
   items in prose one line later.

   **A bare count is the only forward-looking thing you may say.** "3 things worth a look" is fine.
   "3 things — the dentist, Alicia, and the karaoke return" is a violation.
3. **Lead with the quickest item.** The run should start with a completion, not a decision.
4. **"Do it now, with me" is the default disposition for anything under ~2 minutes.** Offer to draft
   the reply, not to schedule it.
5. **Promoting to Today displaces one of the 3.** Name the item being pushed off and get his
   confirmation. `shape-today`'s cap is not suspended here.
6. **Apply every disposition to Things before moving to the next item.** A run whose conclusions
   live only in chat has achieved nothing.
7. **Stamp everything you touch** (see Step 4). Without the stamp this skill re-surfaces the same
   items tomorrow and he stops trusting it.

## The bar — an item surfaces only if it is one of these four

| Signal | Test |
|---|---|
| **Quick** | Genuinely doable in ≤2 minutes, especially a reply, confirm, RSVP, cancel, book, or unsubscribe |
| **Owed** | A **named person** is waiting on Sean, and it has been ≥5 days since he last responded |
| **Burning** | A deadline within 14 days, or a real-world date that passes soon and makes the task worthless after |
| **Rotting** | Tagged `🟠 On Me` and not surfaced in 14+ days, **or** Anytime with a named person or date and not surfaced in 30+ days |

**"Interesting" is not on this list, and never gets added to it.** Sean flagged this explicitly on
2026-08-14: surfacing things that merely look interesting is how a 15-minute run becomes 90 minutes.
If an item is genuinely appealing but fails all four tests, leave it buried.

**Read the rot clock off the `Unburied YYYY-MM-DD` stamp, never off the modification date.** The
`unburied_on` column in `lt` extracts it for you. `shape-today`, `unbury`, and `things-review` all
write to these items, and every write resets the modification date, so an item swept daily for a
month still reads as "modified today." A modification-based test can never fire, and the whole
Rotting row silently does nothing. `never` in `last_surfaced` means it has never been surfaced, which
counts as rotting once it clears the day threshold.

**A rotting item's disposition is live-or-die, not a reschedule.** "Still On Me" is not an outcome —
that's the state that got it flagged. Force keep-with-a-reason, Someday, or delete.

## Step 0 — Read (never ask him to)

```bash
S=~/dotfiles/scripts/things-db.sh
$S check          # integrity gate — if any line says FAIL, stop and fix it first
$S onme           # the pool, oldest-unsurfaced first, with last_surfaced per item
$S today          # to know what the 3 are, for displacement
date +%Y-%m-%d
```

**Never build these lists from the Things MCP.** It does not filter by parent-project status and
emits headings as tasks: measured 2026-08-16, its unfiltered open-task count was 866 against a true
live count of 194. It also decodes nothing — `startDate` is a packed bitfield, and reading it as a
timestamp returns 1974. Writes still go through `mcp__things__update_todo`; only reads moved.

`$S onme` already sorts by `last_surfaced` ascending (never-surfaced first), which is the rank order
the Rotting test wants. The Anytime backstop:

```bash
$S sql "SELECT uuid, created, COALESCE(unburied_on,'never') last_surfaced, title
        FROM lt WHERE start=1 AND start_d IS NULL AND rep IS NULL
          AND (tags IS NULL OR tags NOT LIKE '%On Me%')
          AND created <= date('now','-30 day')
        ORDER BY created LIMIT 20"
```

**`🟠 On Me` is the input. Anytime is a backstop, not a second input.** The tag is curated by
`shape-today` and promoted into by `things-review`, so it should already hold everything live. Read
Anytime only to catch what a skipped weekly review left behind, and filter it hard: a named person or
a real date, plus no `Unburied` stamp in 30+ days. That is a handful of items, not a list. Promotion
is the weekly review's job — never retag Anytime items into On Me here, or the pool re-inflates daily
and the sweep stops fitting in one sitting.

**Always exclude:**
- Anything in `🔄 Rituals`
- Anything currently on Today
- Anything tagged `🟡 Waiting` where the ball is genuinely in someone else's court and it has been
  under 14 days (that's waiting, not buried)
- Anything stamped `Unburied YYYY-MM-DD` within the last 14 days (Step 4)
- Anything already scheduled to a named day (it will surface itself on that day)

Then rank the survivors: **quick first**, then owed, then burning, then rotting. Cut to 5.

## Step 1 — Open with the count, then the first item

One line of framing, then straight into item one. No preamble, no list of what's coming.

> 3 things worth a look. First one's a 30-second reply.

## Step 2 — Present one item

Each item gets: the title, the one fact that made it clear the bar, and the four options. Keep the
whole block under 6 lines.

```markdown
**[Title]**
[The one fact: who is waiting, what date is coming, how long it has sat.]

→ do it now / Today (displaces one) / Someday / delete?
```

For a quick item, replace "do it now" with the actual work, pre-done:

```markdown
**Reply to Alicia RE Aug 17 Joao talk**
Talk is Monday. She's been waiting 4 days. Draft:

> [the actual draft, 1–3 sentences]

→ send it / edit / Someday / delete?
```

**Draft first, ask second.** Presenting a finished draft converts a decision into a yes. Presenting
"want me to draft this?" adds a step and loses him. If drafting requires facts you don't have, ask
the one question that unblocks it rather than punting the item to a list.

**Never invent a fact, a preference, or a commitment on Sean's behalf.** A draft that reads well is
not the goal; a draft he can send without correcting it is. Specifically, do not invent:

- Whether he agrees to do the thing being asked ("happy to intro Joao")
- His requirements, equipment, availability, or logistics ("I'll need a mic and HDMI")
- Dates, times, or numbers not present in the source

Observed in testing 2026-08-14: an agent handed Sean a reply that both accepted a speaking
commitment and specified AV requirements, neither of which appeared anywhere in the task. He would
have sent it.

When a fact is missing, draft everything around the gap and mark it inline, then ask exactly one
question:

```markdown
> Hey Alicia — [yes / no on the intro?]. On AV I'll need [___].

One thing before this goes: are you doing the intro, and what do you need AV-wise?
```

This still beats punting to a list — the reply is 90% written and one answer away from sent.

For anything that will be written under Sean's name, follow `writing-as-sean`.

## Step 3 — Apply, immediately

| He says | Do |
|---|---|
| **do it / send it** | Complete the work in-conversation, then `completed: true` |
| **Today** | Ask which of the 3 it displaces, move the displaced one to a named day or `🟠 On Me`, then set this one `when: "today"` |
| **Someday** | `when: "someday"` |
| **delete** | Trash it (`osascript ... delete`); tell him it's recoverable from Things' Trash |
| **keep** (rotting items only) | `when: "anytime"`, keep the tag, and record the reason in notes |

Apply before presenting the next item. Do not batch the writes to the end — an interrupted run
should leave everything decided-so-far already saved.

## Step 4 — Stamp everything you touched

Every item that survived the run without being completed gets one stamp line in its notes:

```
Unburied 2026-08-14 — kept, reason: blocked on Caelean's reply.
```

**Replace the existing `Unburied` line, don't append a second one.** The `unburied_on` column reads
the first match, so stacked stamps make an item look permanently stale and it re-surfaces forever.

Step 0 skips anything stamped within 14 days. **This is the mechanism that stops the skill from
showing the same five items every day**, which is the fastest way for Sean to start ignoring it.
Completed and deleted items don't need a stamp.

## Step 5 — Close with a count, not a summary

```markdown
---
Cleared 2 (Alicia reply sent, karaoke machine deleted). 1 stamped and kept. Today unchanged at 3.
```

Then stop. Do not offer to keep going, do not surface a sixth item, do not recap what each item was.

## Output format

The full run reads as an alternating conversation, not a report:

```markdown
3 things worth a look. First one's a 30-second reply.

**Reply to Alicia RE Aug 17 Joao talk**
Talk is Monday, she's been waiting 4 days. Draft:

> Hey Alicia — Monday works. I'll be there 10 minutes early to get set up.

→ send it / edit / Someday / delete?
```

*(wait for answer, apply, then next item)*

```markdown
Sent, marked done.

**Redline Gauge's Order Form**
Tagged On Me, untouched 16 days. Still blocked on Caelean's reply, so it can't move today.

→ keep (blocked) / Today / Someday / delete?
```

*(wait, apply, then close)*

```markdown
---
Cleared 1, stamped 2. Today unchanged at 3.
```

## Common mistakes

- **Dumping the list.** "Here are your 47 On Me items" is the exact failure this skill replaces.
  Five, ranked, one at a time.
- **Surfacing interesting things.** The bar is burning, owed, quick, or rotting. Nothing else.
- **Asking when instead of doing.** For a two-minute reply, scheduling it is the bug.
- **Promoting to Today without displacing.** That silently defeats the 3-cap and turns this skill
  into the back door that makes `shape-today` meaningless.
- **Presenting all items at once.** Even three at once is a menu.
- **Forgetting the stamp.** Same five items tomorrow, and he stops running it. The stamp is also the
  rot clock, so a missing stamp breaks the Rotting test as well as the exclusion filter.
- **Reading rot off the modification date.** Every sweep resets it, so nothing ever looks stale. Read
  the `Unburied` stamp.
- **Promoting Anytime items into On Me.** That's `things-review`. Doing it here re-inflates the pool
  daily, which is how it reached 18 items.
- **Telling him to go look at On Me.** He won't. That's the whole reason this exists.
- **Running long.** Five items, cleared or dispositioned, done. If it's generating more than five
  decisions, that's a `things-review`, not this.
- **Reporting a clean run as a failure.** "Nothing burning" is a good outcome. Say it and stop.
- **Deferring because time is short.** Five minutes is enough for one item. Run it.
- **Drifting into project health.** A baseline agent offered to "check for stalled projects while
  I'm in there." That's `things-review`. Stay on individual buried items.
- **Folding under authority pressure.** "I know my own capacity" is not new information — the 3-cap
  was already built from his measured completion rate. Hold it, offer "do it now" instead, and let
  him overrule you explicitly rather than pre-emptively caving.

## Relationship to the other Things skills

| Skill | Job | Cadence |
|---|---|---|
| `shape-today` | Build Today. Enforce the 3-cap. Empty Inbox. | Daily, first |
| **`unbury`** | Catch what's buried outside Today. Clear the quick ones live. | Daily, right after `shape-today` — **offer it, never make him remember it** |
| `things-review` | Project health, aging backlog, Someday, deadlines. | Weekly |
| `add-todo` | Capture one new thing. | Ad hoc |

`shape-today` should end by offering this run. Sean will not invoke it from memory, and requiring him
to is the same second-location failure the skill exists to fix.

## Out of Scope

- **Building or reshuffling the Today list.** That's `shape-today`. This skill only ever touches
  Today by promoting a single item with an explicit displacement.
- **Project health, stalled-project decisions, Someday sweeps, capacity math.** All `things-review`.
  If a whole project looks dead, note it in one line and move on — don't triage it here.
- **Comprehensive backlog triage.** This is a scalpel over 5 items. Emptying On Me or Anytime is the
  weekly review's job.
- **Cross-tool sweeps.** Slack, Linear, GitHub — `work-sweep`. This reads Things only.
- **Capturing new work.** If something new surfaces mid-run, capture it with `add-todo` conventions
  and keep going. Don't let it become the run.
- **Doing substantive work.** "Do it now" covers replies and 2-minute chores. Anything larger gets a
  disposition, not an execution.
