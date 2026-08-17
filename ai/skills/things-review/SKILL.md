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
6. **Every number comes from `things-db.sh` (Step 0a).** No MCP list reads, no AppleScript counts.
7. **Never state elapsed time.** You cannot measure it. Saying "we're 35 minutes in" when 12 have
   passed pressures Sean into cutting a review short on a number you invented. If pacing matters,
   count steps remaining, not minutes.
8. **When two queries disagree, stop and reconcile before continuing.** A contradiction is a
   methodology failure, not a curiosity to note in passing. Observed 2026-08-16: one query reported
   a project that a second query said did not exist. It was a *completed* project leaking through an
   unfiltered read, and pressing on turned one bad number into six.

## Step 0a — Data integrity gate (before anything else)

**Run `./things-db.sh check` from this skill's folder. If any line starts with FAIL, stop and fix it
before presenting a single number to Sean.**

```bash
~/.claude/skills/things-review/things-db.sh check      # integrity gate
~/.claude/skills/things-review/things-db.sh buckets    # reconciled counts
~/.claude/skills/things-review/things-db.sh sql "SELECT ... FROM lt"
```

**Do not use the Things MCP tools to build any list in this review.** Measured on 2026-08-16, the
MCP's unfiltered view of "open tasks" was 866 against a true live count of 194, because:

- **672 open tasks belong to completed, cancelled, or trashed projects.** The MCP does not join
  parent status, so dead work reads as live.
- **70 open headings exist**, and the MCP emits them as if they were tasks. A heading also prints
  without a `Project:` line, so its children look unfiled.
- **`startDate` and `deadline` are packed bitfields** (`year<<16 | month<<12 | day<<7`), not
  timestamps. Decoding them as unix epoch returns 1974 for every row. `creationDate` and
  `userModificationDate` *are* epoch seconds. The two encodings sit in adjacent columns.
- **`Age:` and `Last modified:` describe creation and modification**, and every sweep by
  `shape-today` / `unbury` / this skill rewrites modification. Age a backlog item by `created`.

The script's views (`lt` for live to-dos, `proj` for active projects) apply all of these filters.
Query them for every list in this review.

**A count you did not get from `things-db.sh` does not go in front of Sean.** This review is what he
commits to doing; a number that is off by 4x is worse than no review. If the script can't answer
something, say so rather than falling back to the MCP or to AppleScript.

## Step 0 — Ask first

> "Before I look: what's on your mind about the last week? Anything you worked on that isn't in
> Things, or any project you're worried about?"

Wait. Then:

- **Untracked work named** → capture it (`when: "anytime"`, correct project) before going further.
- **A project named as a worry** → it leads the project-health section regardless of what the data
  says.
- **Nothing** → proceed to the data.

## Step 1 — Project health (the main event)

Per-project open counts and completion history, straight from the database:

```bash
S=~/.claude/skills/things-review/things-db.sh

# open tasks per active project
$S sql "SELECT COALESCE(project,'(no project)') p, COUNT(*) n,
        SUM(CASE WHEN created<=date('now','-90 day') THEN 1 ELSE 0 END) older_90d, MIN(created) oldest
        FROM lt WHERE start=1 AND start_d IS NULL GROUP BY 1 ORDER BY 2 DESC"

# completions per project, last 7 and 30 days (status=3 is completed; stopDate is epoch)
$S sql "SELECT COALESCE((SELECT title FROM TMTask p WHERE p.uuid=COALESCE(NULLIF(t.project,''),
          (SELECT h.project FROM TMTask h WHERE h.uuid=t.heading))),'(none)') proj,
        SUM(CASE WHEN t.stopDate>=strftime('%s',date('now','-7 day')) THEN 1 ELSE 0 END) d7,
        COUNT(*) d30, MAX(date(t.stopDate,'unixepoch','localtime')) last
        FROM TMTask t WHERE t.type=0 AND t.status=3 AND t.trashed=0
          AND t.stopDate>=strftime('%s',date('now','-30 day'))
        GROUP BY 1 ORDER BY 3 DESC"
```

Exclude repeating rituals from completion counts (`rep IS NOT NULL` in `lt`) — 123 of the last 30
days' 207 completions were rituals, which swamps every real signal.

**Never use the project's own `Modified` / `Age` field as an activity signal.** It does not update
when child tasks change — 🎿 Skiing has shown "modified 9 months ago" during a week with 8
completions in it. Derive movement from the **Logbook only**.

Assign exactly one verdict per project:

| Verdict | Definition |
|---|---|
| **moving** | ≥1 non-ritual completion in the last 7 days |
| **quiet** | not moving, **and** has ≥1 open task either scheduled (`start_d`) or created within 90 days |
| **stalled** | not moving, **and** zero open tasks **or** every open task created 90+ days ago with no start date |

**Staleness is measured by `created`, never by modification.** Modification is rewritten by every
sweep, so a task nobody has genuinely touched since April reads as fresh. Observed 2026-08-16:
❤️ Mom and 🧠 TheraGPT were both misclassified in opposite directions off modification date.

These are exhaustive and ordered — test `moving`, then `quiet`, then `stalled`. A project whose last
completion was 20 days ago is **quiet**, not an edge case; the only thing that matters after
"moving" fails is whether a live next action exists.

Flag a quiet project with an asterisk when **more than half its open tasks are 60+ days stale** —
*"quiet\*, 9 of 12 tasks are 2–4 months old."* It doesn't need a forced decision, but it's rotting
underneath a healthy-looking verdict and Sean should see that.

"Quiet" is not a problem. A project with real next actions and no recent completions is just waiting
its turn — do not force a decision on it. Only **stalled** projects need one.

**Force at most 2 decisions per review, oldest-stalled first:**

> **🧠 TheraGPT** — no completions in 7 months, 0 open tasks.
> → activate (give it a task this week) / park (move tasks to Someday) / kill (delete the project)?

"Oldest" means **most recent completion date, oldest first**; for projects that have never had one,
fall back to project creation date, and treat never-completed as older than any completed project.
Say which ordering you used in one clause so the ranking is reproducible.

If more than 2 are stalled, name the rest in one line — *"also stalled, next review: 🏡 41 Westwood,
❤️ Mom"* — and stop there. Because the order is deterministic and decided projects stop being
stalled, next week's review resumes exactly where this one left off with no bookkeeping.

This cap resolves the tension with the timebox: **completeness loses to Sean actually finishing the
review.** Six forced decisions produces a review he abandons, which surfaces nothing at all.

A project that is deliberately parked is healthy. A project that is *accidentally* parked is the
thing this review exists to surface. Sean can't tell which is which from inside the daily loop.

**If Step 0's named worry contradicts the data**, say so explicitly rather than picking a side — the
worry is often about a system Things can't see (a Linear project, a Slack thread). Report both:
*"Things shows movement 2 days ago, but the concern is the Linear project, which Things doesn't
track."* Then ask whether the tracked next action actually addresses the worry. If it does but isn't
scheduled soon enough, offer to pull its date forward — that's the whole remediation. If there is no
tracked action at all, capture one before moving on. Don't leave the worry discussed-but-unrecorded;
that's the failure mode that made the Gauge conversation invisible.

## Step 2 — Aging backlog

Anytime items whose last-modified is 30+ days old, grouped by project. These are candidates, not
condemned — present them and let him triage in bulk ("kill the whole 41 Westwood block").

**Exclude any project already flagged stalled in Step 1.** Its tasks are old *because* the project
is stalled — listing them again is the same signal twice, and it's the main thing that makes this
review feel long.

**One line per project bucket, ~10 buckets max**, not one line per task. "🏡 41 Westwood — 19 tasks,
2–9 months" is one line. State how many buckets you're not showing.

## Step 2b — 🟠 On Me (the daily parking lot)

`🟠 On Me` is where `/shape-today` parks still-live work that is not on Today. **It is a queue for
`unbury` to sweep, not a list Sean reads** — he doesn't open it, and the `Scan Soon` ritual that tried
to make him was deleted on 2026-08-14. This review is where that queue gets honest.

`unbury` handles individual burning/rotting items daily. This step handles the queue's **shape** —
whether it has grown past what a daily sweep can keep up with — and it is **the only place items get
promoted into the tag.**

**The admission test, same one `shape-today` uses:** a named person is waiting, or a real-world date
applies. Nothing else qualifies. "Still alive" and "don't let him forget it" are not criteria.

### Demote

- **Count it.** Target is **under ~10**. Past that, a daily sweep of ≤5 can never drain it. If it has
  grown past 10, force a bulk triage: keep / name a day / drop the tag (plain Anytime) / Someday /
  delete. Don't silently restamp the whole list.
- **Re-run the admission test on every tagged item.** Anything that can't name a person or a date
  loses the tag and drops to plain Anytime. This is the routine case, not a failure.
- **On Me but stale** — read the `Unburied YYYY-MM-DD` stamp in notes, never the modification date.
  Every sweep rewrites these items, so modification date always looks fresh and can never detect
  staleness. No stamp in 30+ days means the tag is lying; force live-or-die.

### Promote

Walk **untagged Anytime** and pull up anything that has since become live: a person started waiting,
or a date came into range. Tag those `🟠 On Me`.

This is the step that makes the narrow tag safe. `shape-today` files conservatively and `unbury` only
reads Anytime as a thin backstop, so without a weekly promotion pass, work that goes live between
reviews sits unseen. **Promote after demoting**, so the count you're holding under ~10 is the final one.

- **Don't double-count** with Step 2. If an On Me item is also in an aging project bucket, mention it
  here, not again as aging.

The tag string is exactly `🟠 On Me`, emoji included.

## Step 3 — Someday resurface

Pull the **5 oldest** Someday items. Each gets a forced choice: **do it (schedule a day) / keep in
Someday / delete.**

Five per week is the quota. It is deliberately small — Someday only stops being a graveyard if it's
sampled regularly, and a 70-item purge is a thing he'll abandon halfway.

## Step 4 — Deadlines and blocked items

- **Deadlines in the next 21 days** that have no start date. Each needs a day, or an explicit "not
  yet."

  The MCP can't query a date range — `search_advanced` takes an exact date. Sweep with AppleScript
  instead (iterate lists **and** projects, then de-duplicate by name; an item in a project shows up
  in both passes):

  ```bash
  osascript <<'AS'
  tell application "Things3"
  	set out to ""
  	repeat with t in (to dos of list "Anytime")
  		try
  			set dd to due date of t
  			if dd is not missing value then set out to out & (short date string of dd) & " | " & (name of t) & linefeed
  		end try
  	end repeat
  	repeat with p in projects
  		repeat with t in (to dos of p)
  			if status of t is open then
  				try
  					set dd to due date of t
  					if dd is not missing value then set out to out & (short date string of dd) & " | " & (name of t) & linefeed
  				end try
  			end if
  		end repeat
  	end repeat
  	return out
  end tell
  AS
  ```
- **`🟡 Waiting` items** — first separate the two things this tag conflates:
  - *Genuinely blocked* (he asked, they haven't replied). Over two weeks → they've forgotten. Offer
    to convert it into a follow-up nudge.
  - *Not yet asked* (the task IS "go ask someone"). This isn't waiting at all — it's an unstarted
    task wearing the wrong tag. Drop the tag and treat it as normal work.

## Step 5 — Capacity check

```bash
~/.claude/skills/things-review/things-db.sh sql "SELECT COUNT(*) substantive FROM TMTask t
  WHERE t.type=0 AND t.status=3 AND t.trashed=0 AND t.rt1_repeatingTemplate IS NULL
    AND t.stopDate>=strftime('%s',date('now','-7 day'))"
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

### 🟠 On Me
N items. Stale: [titles]. Over ~20? triage keep / day / drop tag / Someday / delete.

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

- **Using the MCP for any list or count.** It reports 866 open tasks against a true 194. Step 0a or
  nothing.
- **Decoding startDate/deadline as a timestamp.** They are packed bitfields. You get 1974.
- **Aging an item by modification date.** Every sweep resets it. Age by `created`.
- **Stating elapsed time.** You can't measure it, and a wrong number makes Sean cut the review short.
- **Continuing past a contradiction.** Two queries disagreeing means stop and reconcile, not note
  and move on.
- **Leading with list hygiene.** Project health first. That's what he came for.
- **Reporting stalled projects without forcing a decision.** Same list next week.
- **Dumping all 70 Someday items.** Five. Every week.
- **Trusting MCP list reads for counts.** AppleScript only.
- **Running long.** Twenty minutes. Capture the overflow as a task.
- **Treating "quiet" as a problem.** A project with no movement but a scheduled next action is fine.

## Out of Scope

- **Choosing today's tasks.** That's `shape-today`. This skill may schedule items onto future days,
  but it never builds the Today list.
- **Clearing individual quick replies.** That's `unbury`, daily. This review sizes and reshapes the
  On Me queue; it doesn't work through it item by item.
- **Cross-tool sweeps.** Slack, Linear, GitHub — `work-sweep`. This reads Things only.
- **Capture-by-default.** New items surfaced in Step 0 get captured, but don't turn the review into
  a brainstorming session.
- **Restructuring areas, projects, or tags.** If the structure feels wrong, note it and take it up
  separately. Don't reorganize mid-review.
- **Doing the work.** Review, decide, apply, stop.
