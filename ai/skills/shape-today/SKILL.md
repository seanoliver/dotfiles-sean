---
name: shape-today
description: Use when Sean sits down to work and wants to decide what he's actually doing today, when his Things Today list has grown past what he can finish, when Inbox has piled up, or when he asks what should I work on / plan my day / what's on today / shape my day / triage today. Also use when returning after days away and Today or Inbox has accumulated, when several big initiatives are running at once, or when the day's work is interconnected project pieces rather than discrete tasks. Always triage Inbox in the same pass as Today.
---

# Shape Today

Turn an overgrown Things Today list into a plan Sean can actually finish, **empty the Inbox in
the same pass**, and **write both back into Things** so the plan survives the conversation ending.

## Core principle

**A plan that lives only in chat is not a plan.** The terminal step of this skill is applying
dispositions to Things. If the conversation ends with items still piled on Today **or sitting in
Inbox**, the skill failed — no matter how good the prose was.

## The capacity fact

Sean completes a **median of 2 substantive tasks per day** (mean 2.9, measured over 30 days of
Logbook, excluding recurring rituals). The cap is **3 substantive items**. Rituals are uncapped and
do not count.

This number is empirical, not aspirational. Do not raise it because today looks like a good day.

The cap counts **units of commitment**, not line items. Normally a unit is one task. On days when
whole initiatives are in flight, a unit can be a bucket — see below. Either way, **three.**

## Bucket mode

Some days the work doesn't decompose. An active incident is not eight tasks, it's one thing with
eight moving parts, and staffing "three of the eight" leaves the incident unstaffed. Bucket mode
lets a **project count as one unit**, so the cap describes the day honestly instead of forcing a
fiction.

**Default is discrete tasks.** Use bucket mode only when Sean asks for it, or when Step 0 surfaces
two or more multi-task initiatives and the flat cap would obviously misdescribe the day. Say which
mode you're in, in the first line of the output.

### Admission test — a bucket must pass ALL four

1. **It is a real Things project or area**, not a grouping you invented during the shape.
2. **It has 2+ tasks on Today.** A one-task project is a task. Call it a task.
3. **The tasks share one working context** — same incident, same dataset, same document, same
   person. You load the context once and it serves all of them.
4. **Splitting it across days costs rework** — re-reading the same export, re-establishing the same
   thread, re-deriving the same numbers.

Fails any one of these? It is not a bucket. Its tasks are individual items competing for the three
slots like everything else. **"These are all kind of related" is not the test.** Same project field
in Things plus shared context plus real split-cost is the test.

### Rules once you're in bucket mode

- **Three buckets maximum.** Not three buckets plus loose tasks. Not "two buckets and these four
  quick ones." Mixed is fine — two buckets and one discrete task is three units — but the total is
  always three.
- **Every bucket names a droppable tail.** State the one task inside it that goes if the day
  compresses. A bucket without a tail is a blank check, and blank checks are how the cap dies.
- **Every bucket gets a one-line internal order**, including dependencies. "Validate the export →
  verify their claims → post the update carrying both answers" is the deliverable, not a task list.
- **Blockers live inside the bucket they unblock.** A two-minute chore that unblocks a bucket task
  is not a free extra item floating beside the three — it is part of that bucket. Move it into the
  project in Things (`list_id` / `list`) so the grouping is real and not just narration.
- **Buckets over ~6 tasks get called out.** Say plainly which tasks are genuinely today and which
  are the project's backlog that drifted onto Today, and disposition the backlog like anything else.
  A bucket is not permission to leave an entire project sitting on Today.
- **The unit is consistent across the whole shape.** If buckets are the unit for Today, they are the
  unit for the Step 4 day caps too. Don't count buckets on Today and line items on Wednesday.

## Hard rules

1. **Exactly 3 substantive units on Today.** Not 4, not "3 plus a couple quick ones." A unit is one
   task, or one bucket that passed the admission test above.
2. **No optional tier.** No "quick wins," "stretch goals," "if you have time," or "bonus" section.
   A soft tier is how the cap gets defeated — the baseline agent that this skill replaces produced
   3 committed + 3 "quick wins" + 5 "parked," which is just the old 11-item list with headings.
3. **Every item you touch gets an explicit disposition.** Never leave an item's fate implied by
   prose. See Dispositions below.
4. **You must apply the changes.** Read-only shaping is a failed run. See Step 5.
5. **Rituals are never dispositioned.** Don't move, defer, or comment on recurring chores.
6. **Inbox is in scope every run.** Read it with Today. Every inbox item gets an explicit
   disposition in this pass. Do not dump Inbox onto Today — those items compete for the 3-slot
   cap like everything else. Default is the right project + Anytime (tag `🟠 On Me` if it must
   stay visible). Named day / Today only if it earns one of the 3 slots.

## Rationalizations to refuse

| Thought | Reality |
|---|---|
| "Five is achievable today" | The median is 2. Five means four failures and a red list tonight. |
| "I'll add a small optional section" | That's a fourth, fifth, sixth item wearing a hat. Banned. |
| "I don't know his calendar, so I shouldn't reschedule" | Correct — so *ask*, in one batch. Don't skip the step. |
| "I'll tag it On Me so it isn't lost" | On Me is not a safety net. Name who's waiting or what date is running, or leave it untagged. |
| "I'll spread them across next week so he sees them" | Fake dates. Decide, don't schedule. |
| "He can decide what to defer himself" | He asked you because deciding across 30 items is the expensive part. |
| "Categorizing them in my reply is enough" | The reply evaporates. Things is the record. |
| "This one's urgent, it should also go on Today" | Then it displaces one of the 3. Say which. |
| "It's already overdue so it must be today" | Overdue means it needs a decision, not a slot. |
| "It's only two minutes, it doesn't really count" | Nothing is free. Either it's inside a bucket or it's a fourth unit. |
| "It's already drafted, it's a paste-and-send, not a project" | Effort is not the unit. Commitment is. Still a fourth item wearing a hat. |
| "These are all sort of the same initiative" | Run the four-part admission test. Vibes-based grouping is the loophole. |
| "Bucket mode, so the cap doesn't really apply today" | The cap never stops applying. Bucket mode changes the unit, not the number. |
| "I'll just leave the whole project on Today, it's one bucket" | A bucket is 2–6 tasks you'll actually touch, not a project's full backlog. |
| "I counted buckets today and line items for the deferrals" | Pick one unit and hold it through Step 4. Mixed counting hides overcommitment. |

## Step 0 — Ask what's top of mind (do not skip)

**Before reading Things, ask:**

> "What's top of mind right now — anything you're already planning to work on, or worrying about?"

Wait for the answer. One short question, then listen.

This step exists because the ranking in Step 3 measures **who is waiting on Sean**, and that is not
the same as **what Sean cares about**. Deadlines and blocked people are legible to Things; a project
he's mentally living inside often isn't in Things at all. A shape built only on the queue produces a
technically-defensible day that feels wrong, and he stops trusting the skill.

Handle the answer as follows:

- **Named something already in Things** → it gets a Today slot. Top-of-mind beats every ranking
  criterion below except a hard deadline inside 48 hours or a person actively blocked *today*.
- **Named something not in Things** → capture it (`when: "today"` if it's one of the 3, else
  `anytime` + tag `🟠 On Me` if he still wants it visible), then shape. Never let an untracked
  priority stay untracked.
- **Named more than 3 things** → tell him the cap forces a choice and ask which one or two are
  today. Don't silently pick.
- **Named nothing** ("no idea, that's why I'm asking") → fine, fall through to pure ranking.

`work-sweep` opens with this same brain-dump for the same reason. It is the highest-signal input
available and it costs one question.

## Step 1 — Read

```bash
S=~/dotfiles/scripts/things-db.sh
$S check            # integrity gate — if any line says FAIL, stop and fix it first
$S today            # the roster, rituals flagged, with substantive count
$S inbox            # untriaged captures; in scope every run
$S sql "SELECT uuid, start_d, COALESCE(project,area) bucket, COALESCE(due_d,'-') due, title
        FROM lt WHERE start_d > date('now','localtime') ORDER BY start_d"   # upcoming, for day caps
date +%Y-%m-%d
```

**Read the roster from `things-db.sh`, not from the MCP.** The Things MCP does not filter by
parent-project status and emits headings as tasks: measured 2026-08-16, its unfiltered open-task
count was 866 against a true live count of 194. `get_today` has also been observed silently omitting
items (2026-08-07: 26 returned against 32 actually on Today). The script's `lt` view resolves
heading→project, drops dead parents, and decodes `startDate` correctly — it is a packed bitfield, not
a timestamp, and reading it as epoch returns 1974.

`$S today` flags rituals in its `kind` column and prints `substantive_today` at the end. That count is
the one the 3-cap applies to.

Note today's date via `date +%Y-%m-%d`. You need it to compute ages and to name deferral days. Age
items by `created`, never by modification — every sweep by this skill, `unbury`, or `things-review`
rewrites modification date.

If Today has 3 or fewer substantive items **and Inbox is empty**, say so and stop — offer to pull
one forward from Anytime instead. Don't shape a Today list that doesn't need shaping.

If Today is already at 3 (or fewer) but Inbox has items, **still triage Inbox**. Skip the Today
reshuffle; only disposition Inbox. A clean Today with a dirty Inbox is not a finished shape.

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

Pick three units from **Today and Inbox together**. An inbox item can win a Today slot if it
outranks what's already on Today. Most inbox items will not; they get filed, not scheduled.

In bucket mode, rank the buckets themselves by the criteria below using their
strongest member task — an incident with a customer waiting ranks on that customer, not on its
average task.

Rank by, in order:

0. **Top of mind** — anything he named in Step 0. This outranks everything below except a hard
   deadline inside 48 hours or a person actively blocked today. If a top-of-mind item displaces a
   queue item, say which one it displaced and why.
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
this skill's core principle. In bucket mode, tag the **project row itself**, not a task inside it.

The tag string is exactly `🌟 MIT`, emoji included. Writing `MIT` creates a second, duplicate tag in
Things rather than reusing the existing one.

## Step 4 — Disposition everything else

Every remaining item gets exactly one:

| Disposition | Means | Things action |
|---|---|---|
| **A named day** | Committed to a specific date | `when: "YYYY-MM-DD"` |
| **🟠 On Me** | A named person is waiting, or a real-world date applies. No day committed yet. | `when: "anytime"` + tag `🟠 On Me` |
| **Anytime** | Real work, but nobody is waiting and no date is running | `when: "anytime"`, no On Me tag |
| **Someday** | Not now; weekly review will resurface it | `when: "someday"` |
| **Delete** | It's dead | trash it |

**Spread named days, and cap each one.** A future day may hold **at most 3 substantive units**,
counting what `get_upcoming` shows is already scheduled there. Use the same unit you used for Today
— if a cluster of tasks moves to Wednesday together and it passed the admission test, it lands as
one unit; if it didn't pass, it lands as several and fills the day accordingly. Deferring 4 items onto Monday is the
same overcommitment you're fixing, relocated three days out — Monday arrives and `/shape` has to
push them all again.

If a day is full, use the next open one. If you run out of days inside the next ~2 weeks, that is
the signal that too much is being date-committed rather than decided. Send overflow that still
needs eyes to **🟠 On Me**, not to a fourth named-day slot and not to untagged Anytime.

### The On Me admission test

**Name who or what is waiting. If you can't, it doesn't get the tag.**

An item earns `🟠 On Me` only if one of these is true:

- **A named person is waiting on Sean.** Not a ticket, not a project, a person you can name.
- **A real-world date applies.** A trial that lapses, an event that passes, a deadline inside ~30 days.

Everything else that is real work goes to **untagged Anytime** and becomes the weekly review's
problem, not a daily one. "Still alive" is not a criterion. "I don't want him to forget it" is not a
criterion — that instinct is what grew the tag to 18 items by 2026-08-16, at which point it ranked
nothing and drained never.

The tag string is exactly `🟠 On Me`, emoji included. Writing `On Me` without the emoji creates a
second, duplicate tag in Things.

**On Me is a machine-readable queue, not a list Sean reads.** He does not open it, and the `Scan Soon`
ritual that tried to make him was deleted on 2026-08-14 after failing daily. The tag's only job is to
give `unbury` a curated pool to sweep, and a pool only stays sweepable while it stays small. Never
write a disposition that depends on him going to look at On Me himself.

**Untagged Anytime is not a black hole, it is the weekly review's inbox.** `things-review` reads it
and promotes what has become live. Parking real work there is correct when nobody is waiting and no
date is running. Someday is for "not now."

**Deadlines don't need to be start dates.** An item with a hard deadline 8–21 days out doesn't
belong on a near-term day just because the deadline exists. Set `deadline`, send it to Anytime, and
let it surface in review. Pull it onto a day when it's genuinely within striking distance.

**Respect dependencies.** If item B can't start until item A is done, don't schedule them the same
day or B before A. Chain them across consecutive open days.

**Inbox default:** file to the matching project (or area) + Anytime. Tag `🟠 On Me` only if it passes
the admission test above. Someday if it is not now. Delete if it is noise. A named day
only when it earned one of the 3 Today slots or has a real date commitment. Never leave an item
in Inbox "to deal with later."

Propose the full set as a table, then let Sean edit inline ("no, Wave 4 Friday not Monday"). Apply
what he lands on.

## Step 5 — Apply, then verify

Use `mcp__things__update_todo` per item (writes still go through the MCP; only reads moved).

Then re-verify from the database, not from the tool you just wrote with:

```bash
S=~/dotfiles/scripts/things-db.sh
$S check && $S today && $S inbox
```

Report the actual post-state numbers. If Today isn't 3 substantive + rituals, or Inbox still has
items you were supposed to file, say so plainly and fix it. Never claim a shape succeeded without
re-reading both lists.

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

### Inbox
| Item | To |
|---|---|
| [title] | Anytime · 📈 Instrumentation · 🟠 On Me |
| [title] | Someday |
| [title] | delete |

### Deferred
| Item | To |
|---|---|
| [title] | Fri Aug 8 |
| [title] | 🟠 On Me · 📈 Instrumentation |
| [title] | Anytime · 💰 Finance |
| [title] | Someday |

---
Applied: Today now has 3 + N rituals (was M). Inbox now empty (was K).
```

**Bucket mode** replaces the three title blocks with three bucket blocks, and reports both counts:

```markdown
## Today — [Day, Mon D]

Three project-level commitments. [M] loose items → 3 units.

**🌟 [Project name]** — [N] tasks
[one-line reason the bucket earned the slot]
Order: [a] → [b] → [c]. Droppable tail: [task].

**[Project name]** — [N] tasks
[reason]
Order: [...]. Droppable tail: [task].

**[Project name]** — [N] task(s)
[reason]

_Rituals: uncapped._

---
Applied and verified: Today is 3 units ([K] line items) + N rituals, was M loose items.
```

Keep reasons to one line. He is deciding, not reading.

## Step 6 — Offer `unbury` (do not skip)

Today is now correct, but it is deliberately only 3 items. Everything else in the system is invisible
to Sean, because he does not open lists other than Today. Close every run with a one-line offer:

> Want me to check what's buried? (`unbury` — quick replies, anything owed or rotting.)

If he says yes, invoke `unbury`. If he says no, stop — do not surface a preview of what it would have
found, since that is the run without the structure.

**This offer is mandatory, and it is the offer that must be automatic, not the run.** Sean will not
remember to invoke `unbury` himself; requiring him to is the same second-location failure that killed
the `Scan Soon` ritual. The `unbury` skill enforces its own 5-item cap and will not touch the 3 you
just set without an explicit displacement.

## Common mistakes

- **Shaping without applying.** The most common and most damaging. Step 5 is the point of the skill.
- **Leaving Inbox dirty.** Today at 3 with 12 items still in Inbox is a failed shape.
- **Dumping Inbox onto Today.** Inbox is not extra Today slots. File it. Only promote what earned a cap slot.
- **Pushing everything to tomorrow.** Spread across the week, or use 🟠 On Me if there is no real
  date.
- **Tagging On Me because it feels important.** The test is a named person or a real date, nothing
  else. An unbounded tag is the same overgrown list one layer down.
- **Inventing named days to keep something visible.** That is how Friday hits 5. Visibility is the
  On Me tag; a date is a commitment.
- **Dispositioning rituals.** Leave them alone.
- **Ending without offering `unbury`.** Sean will not invoke it from memory. Step 6 is not optional.
- **Burying the decision.** Rotters go in their own section, not a footnote.
- **Re-deriving capacity.** The cap is 3. Don't recompute it from today's vibes.
- **Counting from the MCP.** `get_today` omits items and counts dead-project tasks and headings as
  live. Every count comes from `things-db.sh`; report `substantive_today` from `$S today`.
- **Resetting start dates on the 3 picks.** Leave them alone. They're already on Today, and
  refreshing the date to today resets the age clock — an item picked-but-not-done every day would
  never accumulate age and never trip rotter detection. Only write the `🌟 MIT` tag.
- **Letting a bucket smuggle in a freebie.** Observed 2026-08-11: a token refresh stayed on Today as
  "only 2 minutes, and it unblocks the incident." It was a fourth unit. It belonged *inside* the
  incident project, moved there in Things.
- **Bucketing by vibes.** Three tasks that merely share a topic are three tasks. Run the four-part
  admission test and say which part each bucket passed on.
- **A bucket with no tail.** Eight tasks and no statement of what drops when the day compresses is
  not a plan, it's the old overgrown list with a project name on top.

## Out of Scope

- **Capturing new tasks.** That's `add-todo`. If Sean mentions something new mid-shape, capture it
  with `when: "anytime"` and tag `🟠 On Me` if it's live work he wants to see — never add it to
  today's 3.
- **Surfacing buried work.** Quick replies, owed follow-ups, and rotting On Me items are `unbury`.
  Offer it in Step 6; don't do its job inline, and don't let it expand today's 3.
- **Backlog review.** Aging reports, stalled projects, Someday resurfacing, tag hygiene — all
  `/things-review`. This skill touches **Today and Inbox** (and Upcoming only to cap named days).
  It does not walk Anytime, Someday, or project lists.
- **Cross-tool sweeps.** Slack, Linear, GitHub — that's `work-sweep`. This skill reads Things
  and nothing else.
- **Doing the work.** Shape the day, then stop. Don't start executing the first item unless asked.
- **Re-litigating the cap.** If Sean wants a different number he'll say so; take his instruction for
  that session and don't argue. Do not change it on your own initiative. Bucket mode is not a
  loophole for this — it changes what counts as one, never how many.
- **Restructuring his projects.** Bucket mode reads the project structure already in Things. Don't
  create projects, split them, or re-parent tasks to make buckets come out neatly. The one exception
  is moving a blocker into the bucket it unblocks.
