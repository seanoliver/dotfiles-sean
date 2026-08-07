---
name: things-review
description: Use for Sean's weekly Things 3 review — when he asks to review his tasks, do a weekly review, check on his projects, asks which projects are stalled or what's slipping, wonders what he's forgetting, or when it's been a week or more since the last review. Also use when the backlog feels stale or Someday has become a graveyard.
---

# Things Review

The weekly pass over everything `/shape-today` deliberately ignores: project health, the aging
backlog, Someday, deadlines, and blocked items. Roughly 20 minutes, interactive, and — like
`shape-today` — **it writes its conclusions back into Things.**

## Core principle

**The daily skill optimizes for what's urgent. This one is the only thing that notices what's
important.** If a project quietly stops moving, nothing in the daily loop will ever say so — the
whole point of this review is to catch that. Lead with project health, not with list hygiene.

## Hard rules

1. **Start with Step 0.** Sean's head holds state Things doesn't. Ask before reading.
2. **Ask what he worked on that isn't in Things.** Untracked work is the failure mode that made a
   prior `/shape-today` run useless — the Gauge contract conversation was his top priority and had
   no task. Capture whatever surfaces.
3. **Stalled projects get a decision** — activate, park, or kill. "Still stalled" is not an outcome.
   **Max 2 per review**, oldest first; name the rest and leave them for next week.
4. **Apply the changes.** A review whose conclusions live only in chat has to be redone.
5. **Timebox to ~20 minutes.** If a section is generating more than a couple of decisions, capture
   the rest as a task and move on. A review he dreads is a review he skips.

## Step 0 — Ask first

> "Before I look: what's on your mind about the last week? Anything you worked on that isn't in
> Things, or any project you're worried about?"

Wait. Then:

- **Untracked work named** → capture it (`when: "anytime"`, correct project) before going further.
- **A project named as a worry** → it leads the project-health section regardless of what the data
  says.
- **Nothing** → proceed to the data.

## Step 1 — Project health (the main event)

```
mcp__things__get_projects           # active projects
mcp__things__get_logbook period=7d  # what actually got done
```

**Never use the project's own `Modified` / `Age` field as an activity signal.** It does not update
when child tasks change — 🎿 Skiing has shown "modified 9 months ago" during a week with 8
completions in it. Derive movement from the **Logbook only**.

Assign exactly one verdict per project:

| Verdict | Definition |
|---|---|
| **moving** | ≥1 completion in the last 7 days |
| **quiet** | no completions in 30 days, but has open tasks modified within 60 days, or any dated task |
| **stalled** | no completions in 30 days **and** (zero open tasks **or** every open task untouched 60+ days) |

"Quiet" is not a problem. A project with real next actions and no recent completions is just waiting
its turn — do not force a decision on it. Only **stalled** projects need one.

**Force at most 2 decisions per review, oldest-stalled first:**

> **🧠 TheraGPT** — no completions in 7 months, 0 open tasks.
> → activate (give it a task this week) / park (move tasks to Someday) / kill (delete the project)?

If more than 2 are stalled, name the rest in one line — *"also stalled, next review: 🏡 41 Westwood,
❤️ Mom"* — and stop there. Because the order is deterministic (oldest first) and decided projects
stop being stalled, next week's review resumes exactly where this one left off with no bookkeeping.

This cap resolves the tension with the timebox: **completeness loses to Sean actually finishing the
review.** Six forced decisions produces a review he abandons, which surfaces nothing at all.

A project that is deliberately parked is healthy. A project that is *accidentally* parked is the
thing this review exists to surface. Sean can't tell which is which from inside the daily loop.

**If Step 0's named worry contradicts the data**, say so explicitly rather than picking a side — the
worry is often about a system Things can't see (a Linear project, a Slack thread). Report both:
*"Things shows movement 2 days ago, but the concern is the Linear project, which Things doesn't
track."* Then ask whether the tracked next action actually addresses the worry.

## Step 2 — Aging backlog

Anytime items whose last-modified is 30+ days old, grouped by project. These are candidates, not
condemned — present them and let him triage in bulk ("kill the whole 41 Westwood block").

**Exclude any project already flagged stalled in Step 1.** Its tasks are old *because* the project
is stalled — listing them again is the same signal twice, and it's the main thing that makes this
review feel long.

**One line per project bucket, ~10 buckets max**, not one line per task. "🏡 41 Westwood — 19 tasks,
2–9 months" is one line. State how many buckets you're not showing.

## Step 3 — Someday resurface

Pull the **5 oldest** Someday items. Each gets a forced choice: **do it (schedule a day) / keep in
Someday / delete.**

Five per week is the quota. It is deliberately small — Someday only stops being a graveyard if it's
sampled regularly, and a 70-item purge is a thing he'll abandon halfway.

## Step 4 — Deadlines and blocked items

- **Deadlines in the next 21 days** that have no start date. Each needs a day, or an explicit "not
  yet."
- **`🟡 Waiting` items** — first separate the two things this tag conflates:
  - *Genuinely blocked* (he asked, they haven't replied). Over two weeks → they've forgotten. Offer
    to convert it into a follow-up nudge.
  - *Not yet asked* (the task IS "go ask someone"). This isn't waiting at all — it's an unstarted
    task wearing the wrong tag. Drop the tag and treat it as normal work.

## Step 5 — Capacity check

```
mcp__things__get_logbook period=7d
```

Count substantive (non-ritual) completions. Compare to 21 (3/day × 7).

Report one line: *"Last week: 14 substantive completions, ~2/day. Cap of 3 is about right."*

If the actual rate has been under 1/day for two consecutive reviews, say so plainly and ask whether
the cap should drop to 2. Don't adjust it yourself.

## Step 6 — Apply and verify

Apply every decision via `mcp__things__update_todo` / `update_project`.

**Verify the mutations, not just the lists.** Checking that a list is non-empty proves nothing about
whether a specific task got its date changed or its tag removed. Re-read the items you actually
touched:

```bash
osascript <<'AS'
tell application "Things3"
	set t to first to do whose id is "<uuid>"
	return (name of t) & " | " & ((activation date of t) as string) & " | " & (tag names of t)
end tell
AS
```

**Any list-membership count you report must come from AppleScript**, not the MCP — `get_today` and
`get_upcoming` have both been observed silently omitting items. Ages and Logbook stats can come from
the MCP; those aren't affected.

Things has **no MCP delete for projects**. Killing a project requires
`osascript -e 'tell application "Things3" to delete (first project whose name is "X")'`, which moves
it to Trash rather than destroying it. Confirm with Sean before running it, and tell him it's
recoverable from Things' Trash.

## Output format

```markdown
## Weekly Review — [Mon D]

### Projects
| Project | Last movement | Open | |
|---|---|---|---|
| 🤖 Agent-Led Growth | 3 days ago | 4 | moving |
| 📈 Instrumentation | 3 weeks ago | 2 | quiet |
| 🧠 TheraGPT | 4 months ago | 3 | **stalled** |

**Decisions needed**
- 🧠 TheraGPT — activate / park / kill?

### Aging (30+ days untouched)
[grouped list, ~15 max]

### Someday — this week's 5
1. **[Title]** (9 months) → do / keep / delete?

### Deadlines ≤21 days
- [Title] — due Aug 21, no day assigned → schedule when?

### Waiting
- [Title] — waiting 3 weeks. Follow up?

---
Last week: N substantive completions (~N/day).
Applied: [what changed]
```

## Common mistakes

- **Leading with list hygiene.** Project health first. That's what he came for.
- **Reporting stalled projects without forcing a decision.** Same list next week.
- **Dumping all 70 Someday items.** Five. Every week.
- **Trusting MCP list reads for counts.** AppleScript only.
- **Running long.** Twenty minutes. Capture the overflow as a task.
- **Treating "quiet" as a problem.** A project with no movement but a scheduled next action is fine.

## Out of Scope

- **Choosing today's tasks.** That's `shape-today`. This skill may schedule items onto future days,
  but it never builds the Today list.
- **Cross-tool sweeps.** Slack, Linear, Gmail, GitHub — `work-sweep`. This reads Things only.
- **Capture-by-default.** New items surfaced in Step 0 get captured, but don't turn the review into
  a brainstorming session.
- **Restructuring areas, projects, or tags.** If the structure feels wrong, note it and take it up
  separately. Don't reorganize mid-review.
- **Doing the work.** Review, decide, apply, stop.
