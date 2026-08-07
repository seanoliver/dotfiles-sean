---
name: shape-today
description: Use when Sean sits down to work and wants to decide what he's actually doing today, when his Things Today list has grown past what he can finish, or when he asks what should I work on / plan my day / what's on today / shape my day / triage today. Also use when returning after days away and Today has accumulated.
---

# Shape Today

Turn an overgrown Things Today list into a plan Sean can actually finish, and **write that plan back
into Things** so it survives the conversation ending.

## Core principle

**A plan that lives only in chat is not a plan.** The terminal step of this skill is applying
dispositions to Things. If the conversation ends with items still piled on Today, the skill failed —
no matter how good the prose was.

## The capacity fact

Sean completes a **median of 2 substantive tasks per day** (mean 2.9, measured over 30 days of
Logbook, excluding recurring rituals). The cap is **3 substantive items**. Rituals are uncapped and
do not count.

This number is empirical, not aspirational. Do not raise it because today looks like a good day.

## Hard rules

1. **Exactly 3 substantive items on Today.** Not 4, not "3 plus a couple quick ones."
2. **No optional tier.** No "quick wins," "stretch goals," "if you have time," or "bonus" section.
   A soft tier is how the cap gets defeated — the baseline agent that this skill replaces produced
   3 committed + 3 "quick wins" + 5 "parked," which is just the old 11-item list with headings.
3. **Every item you touch gets an explicit disposition.** Never leave an item's fate implied by
   prose. See Dispositions below.
4. **You must apply the changes.** Read-only shaping is a failed run. See Step 5.
5. **Rituals are never dispositioned.** Don't move, defer, or comment on recurring chores.

## Rationalizations to refuse

| Thought | Reality |
|---|---|
| "Five is achievable today" | The median is 2. Five means four failures and a red list tonight. |
| "I'll add a small optional section" | That's a fourth, fifth, sixth item wearing a hat. Banned. |
| "I don't know his calendar, so I shouldn't reschedule" | Correct — so *ask*, in one batch. Don't skip the step. |
| "He can decide what to defer himself" | He asked you because deciding across 30 items is the expensive part. |
| "Categorizing them in my reply is enough" | The reply evaporates. Things is the record. |
| "This one's urgent, it should also go on Today" | Then it displaces one of the 3. Say which. |
| "It's already overdue so it must be today" | Overdue means it needs a decision, not a slot. |

## Step 1 — Read

```
mcp__things__get_today          # rich data: notes, deadlines, projects
mcp__things__get_upcoming       # what's already committed to coming days
osascript -e 'tell application "Things3" to get name of to dos of list "Today"'
```

**Run both Today reads. `get_today` under-reports.** Observed 2026-08-07: it returned 26 items while
AppleScript returned 32, silently omitting four substantive items that were genuinely on Today. Use
`get_today` for the rich fields (notes, deadlines, project) and **AppleScript for the authoritative
roster**. Anything in the AppleScript list but missing from `get_today` still needs a disposition —
look it up by name to get its id.

Note today's date via `date +%Y-%m-%d`. You need it to compute ages and to name deferral days.

If Today has 3 or fewer substantive items, say so and stop — offer to pull one forward from Anytime
instead. Don't shape a list that doesn't need shaping.

## Step 2 — Detect rotters

A **rotter** is an item whose start date is 14+ days in the past. Because deferral always names a
day, an old start date means it has been pushed repeatedly without a decision.

**Compute the age yourself** from `Start Date` against today's date. Do not trust the `Age:` and
`Last modified:` strings in the Things MCP output — they describe *creation* and *modification*, not
how long the item has sat on Today, and they will disagree with the number that matters.

Rotters do not get silently pushed again. Each one gets surfaced by name with its age and a forced
choice: **do it today / schedule a specific day / Someday / delete.**

Items at **10–13 days** are *aging*, not yet rotters. List them in one line under the rotter section
("aging: X (11d), Y (10d)") without forcing a decision. This keeps the binary cutoff from hiding
things that are one day short of it. Aging items still get a normal Step 4 disposition like
everything else — the aging line is visibility, not an exemption.

This is the mechanism that prevents the list from rotting invisibly. Never skip it.

## Step 3 — Pick 3

Rank by, in order:

1. **Hard external deadline** within ~7 days, or already passed
2. **A person is blocked on Sean** — a customer, a teammate, someone waiting on a reply
3. **A promise already broken** — he said he'd do it and went quiet (check notes for "told X I'd…")
4. **Rotter that he chose to commit to** in Step 2
5. **The thing he'd feel best having shipped** — bias toward finishing over starting

A **person** waiting outranks a **ticket or issue** being blocked. "Blocks GROWTH-1073" is rank 5
work, not rank 2 — no human is sitting there refreshing. Within rank 2, a **named individual** who
messaged Sean directly outranks a **queue ticket** whose customer is anonymous and who has other
channels.

**Reserve one slot for proactive work.** If the first two picks are both reactive — replies,
tickets, follow-ups, anything where someone else set the agenda — the **third slot goes to the best
proactive item**: shipping something, finishing a parked branch, moving a project he owns.

This rule exists because strict ranking is self-defeating. Reactive work always looks more urgent,
so it wins every day, and the proactive work that actually constitutes his job never gets a slot.
A week of all-reactive days is how a shipping drought sustains itself. If there is genuinely no
proactive candidate on the list, say so explicitly rather than silently filling the slot with a
third ticket.

When several items tie at the same rank, break it by, in order: stated severity (an urgent ticket
beats a low one) → how long the person has been waiting → smaller effort first, so the day starts
with a completion. An item that satisfies *two* ranks (blocked person **and** broken promise) beats
one that satisfies a single higher rank.

Each pick needs a one-line reason naming the specific fact that earned it. "Important" is not a
reason. "Yorvi re-pinged Aug 3 after 11 days of silence, and Pam is OOO" is a reason.

Mark the single most important one `🌟 MIT` — **and apply that tag in Things**, don't just print the
star. Clear it from whatever held it previously. A star that exists only in the chat reply violates
this skill's core principle.

## Step 4 — Disposition everything else

Every remaining item gets exactly one:

| Disposition | Means | Things action |
|---|---|---|
| **A named day** | Committed to a specific date | `when: "YYYY-MM-DD"` |
| **Anytime** | Active, no specific day, lives in its project | `when: "anytime"` |
| **Someday** | Not now; weekly review will resurface it | `when: "someday"` |
| **Delete** | It's dead | trash it |

**Spread named days, and cap each one.** A future day may hold **at most 3 substantive items**,
counting what `get_upcoming` shows is already scheduled there. Deferring 4 items onto Monday is the
same overcommitment you're fixing, relocated three days out — Monday arrives and `/shape` has to
push them all again.

If a day is full, use the next open one. If you run out of days inside the next ~2 weeks, that is
the signal that too much is being deferred rather than decided: send the overflow to **Anytime**,
where the weekly review will surface it. Anytime is not a failure state — it's the correct home for
"real, but not tied to a day."

**Deadlines don't need to be start dates.** An item with a hard deadline 8–21 days out doesn't
belong on a near-term day just because the deadline exists. Set `deadline`, send it to Anytime, and
let it surface in review. Pull it onto a day when it's genuinely within striking distance.

**Respect dependencies.** If item B can't start until item A is done, don't schedule them the same
day or B before A. Chain them across consecutive open days.

Propose the full set as a table, then let Sean edit inline ("no, Wave 4 Friday not Monday"). Apply
what he lands on.

## Step 5 — Apply, then verify

Use `mcp__things__update_todo` per item. Then **re-read `get_today`** and confirm the count.

Report the actual post-state number. If it isn't 3 substantive + rituals, say so plainly and fix it.
Never claim a shape succeeded without re-reading.

## Output format

```markdown
## Today — [Day, Mon D]

**🌟 [Title]**
[one-line reason it earned the slot]

**[Title]**
[reason]

**[Title]**
[reason]

_Rituals: [names], uncapped._

### Needs a decision
**[Title]** — on Today [N] days, pushed without resolution.
→ do it today / [specific day] / Someday / delete?

_Aging: [title] (11d), [title] (10d)._

### Deferred
| Item | To |
|---|---|
| [title] | Fri Aug 8 |
| [title] | Anytime · 📈 Instrumentation |
| [title] | Someday |

---
Applied: Today now has 3 + N rituals (was M).
```

Keep reasons to one line. He is deciding, not reading.

## Common mistakes

- **Shaping without applying.** The most common and most damaging. Step 5 is the point of the skill.
- **Pushing everything to tomorrow.** Spread across the week.
- **Dispositioning rituals.** Leave them alone.
- **Burying the decision.** Rotters go in their own section, not a footnote.
- **Re-deriving capacity.** The cap is 3. Don't recompute it from today's vibes.
- **Counting wrong.** `get_today` and AppleScript disagree, and **AppleScript is the authoritative
  one** — `get_today` has been observed omitting items. Verify with AppleScript in Step 5 and report
  that number.
- **Resetting start dates on the 3 picks.** Leave them alone. They're already on Today, and
  refreshing the date to today resets the age clock — an item picked-but-not-done every day would
  never accumulate age and never trip rotter detection. Only write the `🌟 MIT` tag.

## Out of Scope

- **Capturing new tasks.** That's `add-todo`. If Sean mentions something new mid-shape, capture it
  with `when: "anytime"` and keep going — never add it to today's 3.
- **Backlog review.** Aging reports, stalled projects, Someday resurfacing, tag hygiene — all
  `/things-review`. This skill only touches Today and the items on it.
- **Cross-tool sweeps.** Slack, Linear, Gmail, GitHub — that's `work-sweep`. This skill reads Things
  and nothing else.
- **Doing the work.** Shape the day, then stop. Don't start executing the first item unless asked.
- **Re-litigating the cap.** If Sean wants a different number he'll say so; take his instruction for
  that session and don't argue. Do not change it on your own initiative.
