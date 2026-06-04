---
name: journal-entry
description: Use when Sean wants to write a Day One journal entry — triggers include "let's journal", "write a journal entry", "help me reflect", a bare mood ("feeling flat today"), or a specific thing he wants to write/vent about. Conducts the interview, drafts in his voice, saves to Day One, and keeps his recurring threads current.
---

# Journal Entry

Interview Sean, draft a Day One entry in his voice, save it, and update his recurring threads. The goal is **low context cost** — Sean should be able to start with a mood or a topic and almost nothing else.

## Read First (required, before interviewing)

1. **Read `~/cortex/wiki/personal/journal-threads.md`** — his active arcs (e.g. Kai, build-vs-buy, remote-work). You'll check in on these during the interview and update them after saving.
2. **Pull the day's activity** — silent, best-effort, in parallel, never blocking. If a source is slow or unavailable, skip it without comment:
   - Things completed today (`mcp__things__get_logbook`)
   - Today's calendar events (`mcp__google_workspace__get_events`)
   - Commits in the current repo today (`git log --since=midnight --author="Sean"`)
   - Do **not** pull Slack or GitHub PRs. Do **not** read his other Day One entries.

## Step 1 — Detect mode

- **Guided** — vague mood, "let's journal", or no specific subject → run the full reflective interview below.
- **Freeform** — he hands you a specific topic or wants to vent ("write about the Anna text") → skip the structured battery and the activity pull. Follow the thing he raised, ask 1–2 light follow-ups, then draft.

## Step 2 — Interview (guided mode)

Open with **one** message combining:
- A short structured prompt: emotional weather, what happened, what's on your mind, anything for tomorrow.
- Thread check-ins drawn from the threads file: "any update on build-vs-buy?"
- One or two activity-seeded observations: "you closed out X today — worth noting?"

Then **follow what he raises adaptively** — 1–3 rounds, probing only the threads with energy in them. Stop when answers stop adding new material, or when he says "write it." Don't interrogate; batch follow-ups, protect his momentum.

## Step 3 — Draft

Write the entry in **Sean's voice** — first person, dry, plain, honest. No hype words, no forced silver lining, no padding. A flat day gets a short entry. Use **bold mini-headers** to separate threads when there's more than one. Match this register directly; do **not** read past entries to calibrate.

**Always show the draft in chat before saving.** Show the suggested tags alongside it.

## Step 4 — Save (on his go-ahead)

Call `mcp__day-one__create_entry` with:
- `journal_id`: `243478339` (the **Life** journal — the only MCP-accessible one)
- `date`: today, ISO8601 (e.g. `2026-06-04T20:00:00Z`)
- `tags`: auto-suggested from content + thread names (e.g. `reflection,work,kai`) — he can veto before save
- `text`: the approved markdown body

Return the `viewLink` so he can open it.

## Step 5 — Update threads (after saving)

Surgically edit `~/cortex/wiki/personal/journal-threads.md`:
- Bump `last-touched` on any thread that came up.
- Adjust a thread's status/summary if it moved.
- Add any new arc that surfaced.
- Archive a thread he's resolved (move to the Archived section).
- Bump `updated:` in the file's frontmatter.

Keep edits surgical — never regenerate the file.

## Output Format

The saved entry is markdown:
- Optional bold title line (e.g. `**Flat and a little scattered**`).
- Short prose paragraphs in his voice.
- `**Bold mini-header**` per thread when multiple threads are present.
- First person throughout.

## Common Mistakes

- **Padding a flat day.** Three sentences of real feeling beats five manufactured paragraphs.
- **Pulling activity in freeform mode.** When he hands you a topic, stay out of the way.
- **Forgetting the thread update.** The whole point is zero-effort memory for next time. Always do Step 5.
- **Reading past entries to match voice.** Don't — his register is encoded here. Reading entries is out of scope.
- **Saving before he's seen the draft.** Never. Always show it first.
- **Guessing the journal.** It's always Life (`243478339`) until he says otherwise.

## Out of Scope

- Scheduling future or post-dated entries (always today).
- Routing to any journal other than Life.
- Reading or editing past Day One entries.
- Media/photo attachments.
- Slack or GitHub-PR activity scanning.
