---
name: speaker-notes
description: Use when Sean needs notes to speak from live — a meeting, presentation, demo, design review, 1:1, standup, interview, board or exec update, conference talk, or a hard conversation. Trigger on "speaker notes", "talking points", "prep me for", "help me prep for this meeting", "notes for my presentation", "I'm presenting X tomorrow", "what should I say in", "give me a cheat sheet for", "I need to defend X", or when he pastes a list of points he wants to make plus a meeting name. Also trigger when he asks what questions he'll get asked. Do NOT use for writing the message/email itself (message-crafter) or for a written status update (weekly-update-formatter).
argument-hint: [meeting/topic + any points you already know you want to make]
---

# Speaker Notes

Produce a single Markdown document Sean can paste into Bear or Obsidian and glance at **while talking**.

The document is a **retrieval surface, not a script**. Success is: glance down → find the thought in under a second → absorb it → look back up and speak naturally. Every formatting decision serves that. A beautifully written paragraph he can't parse mid-sentence is a failure.

This is **not** a summarization skill. Do not preserve information. Select the small set of things he is most likely to need under pressure, and make each one instantly findable.

Prefer: useful over comprehensive · scannable over elegant · defensible over impressive · concise over exhaustive · direct source links over unsupported precision.

## Inputs

Accept either or both, in any form:

- A list of points he already knows he wants to make
- A description of the meeting, presentation, or conversation

Missing detail is normal. Do not interrogate. Ask a question **only** when the ambiguity would change the meeting objective itself or make the output actively misleading (e.g. you cannot tell whether he is presenting a decision or asking for one). Otherwise infer, produce the document, and mark uncertainty inline with `UNCLEAR` / `VERIFY` / `UNVERIFIED`.

**Thin input is not a blocker, and it is not a licence to hand back a form.** Never emit a fill-in-the-blank template. A document that is half `[your definition here]` is homework, not speaker notes — he cannot use it at the podium, and it moves the work back onto him at the exact moment he had least time. With little context, commit to the most probable concrete version, write it as real content, and mark the specific claims he must check with `VERIFY`. Two or three bracketed slots for facts only he holds is acceptable. Fifteen is a failure.

**Nothing in the document except the document.** No preamble, no framing note, no "here's what I couldn't access," no apology for thin sources, no notes-to-self about your own tool limits. If a gap matters, it appears as a `VERIFY` or `UNVERIFIED` anchor in the place he'd need it. Everything else goes in your message to him, outside the artifact — he is going to paste this into Bear and read it in a room.

## Process

Run these in order. Do not emit any part of the document until step 8 is done.

1. **Classify the situation.** Meeting type drives structure: presentation · discussion · decision · status · demo · 1:1 · interview/panel · difficult conversation. Read `formats.md` for the matching skeleton. If it is a hybrid, pick the dominant type and borrow sections from the other.

2. **Name the audience and the stakes.** Who is in the room, what do they already know, what are they deciding, what do they care about. If teammates are named, read the `PEOPLE.md` memory file for positioning before assuming anything about them.

3. **Read first — search before writing.** See Research below. Do not skip this because his bullets look complete; his bullets are his intent, not the record.

4. **Build the mental model.** Explicitly reason (in thinking, not in the output) about:
   - What is this meeting actually trying to accomplish?
   - What decision needs to be made, and by whom?
   - What context will attendees already have? What are they missing?
   - What is he implicitly being asked to defend?
   - Where will he get challenged, and by whom specifically?
   - What commitment should he avoid accidentally making?
   - Is there an elephant in the room he should name proactively?

5. **Find the narrative spine.** One core message, then the 2–5 topics that carry it, ordered by importance — not chronology, not the order he listed them.

6. **Draft the main notes.** Apply the format rules below and the templates in `formats.md`.

7. **Anticipate questions.** Generate `## LIKELY QUESTIONS`, ranked by likelihood × damage-if-fumbled. Research the answers where possible. Do not manufacture confidence.

8. **Verify every number.** Each numeric claim, date, quote, and commitment either carries a direct link or gets downgraded to qualitative / marked `VERIFY BEFORE USING`. Do this as an explicit pass over the draft, not as you write.

9. **Emit the document.** One Markdown file, nothing else. No preamble, no "here's what I found."

## Research

Search before writing whenever tools are available. Prefer **primary sources** over recaps:

- actual Slack thread > someone's summary of it
- Linear issue > a mention of the issue
- GitHub PR/diff > a description of the change
- original meeting notes (Granola/Notion) > later recollection
- the code > the doc about the code

Available surfaces here: Slack, Linear, GitHub, Notion, Granola, Google Drive, PostHog, Hex, `~/supabase/docs/` (investigations, bugs, plans), the repos themselves, `sessions.md`.

Search broadly enough to know: what has already been decided · what is still open · who the stakeholders are · prior objections · deadlines and commitments · current implementation state · the metrics likely to come up · contradictions between sources · **anything Sean himself previously said or committed to**.

That last one matters most. A quote of his own words from three weeks ago is the highest-value thing this skill can hand him.

Stop researching when new sources stop changing the notes. Depth over breadth on the two or three topics that will actually get contested.

## Format rules

Strict. These are the product.

- Markdown only
- One idea per line
- Fragments and short sentences over full ones
- No paragraphs. Ever. If it needs three lines of prose, it needs three bullets
- No tables unless the table is genuinely more scannable than bullets (comparisons across 3+ options, cost/effort grids)
- Whitespace aggressively — blank line between every labeled block
- `##` headings as visual landmarks; `---` between major sections
- **Bold** and CAPS only on the single most important word in a block
- Do not over-format. If every line is bold, nothing is
- Transitions on their own line, prefixed `→`, in quotes: `→ "Which brings us to cost"`
- Headings and question text written so Command-F finds them — use the words he'd search for, not clever paraphrases
- Most important topic first, most likely question first
- Never write out a full speech unless he explicitly asks

### Visual anchors

Use these as bare labels on their own line (no bold, no colon-heavy prose). Consistency is what makes them findable.

`CORE POINT` · `WHY` · `EVIDENCE` · `DECISION` · `RISK` · `TRADEOFF` · `NEXT` · `ASK` · `MY POSITION` · `ANSWER` · `KEY POINTS` · `IF PUSHED` · `SOURCE` · `?` · `→` · `[PAUSE]`

Uncertainty anchors: `UNCLEAR` · `VERIFY` · `UNVERIFIED` · `OPEN QUESTION` · `WHAT WE DO KNOW`

Do not invent a parallel vocabulary per document. Add a new anchor only when none of these fit.

## Numbers and factual claims

**Do not state a specific number without a direct link to the source that substantiates it.** This is the rule most likely to embarrass him in a room.

Bad:
```markdown
EVIDENCE
- Conversion improved 17%
```

Good:
```markdown
EVIDENCE
- Conversion improved 17%
  SOURCE [PostHog experiment result](https://...)
```

If the evidence exists but cannot be linked, either describe it qualitatively or mark it:
```markdown
EVIDENCE
- Activation improved materially after the change
- Exact magnitude: VERIFY BEFORE USING
```

**A number Sean half-remembers is an unsourced number.** This is the most common version of the failure, and a tilde is not a fix. When he says "I think it was something like 1,200 credits for 8 runs," the notes do not get to say "~1,200 credits for 8 runs" and move on — especially not as the load-bearing evidence for his recommendation. Either link it, or put the marker on the page where he will see it:

```markdown
EVIDENCE
- Vendor run economics break down at regression volume
- Specific credit figures: VERIFY BEFORE USING — from memory, not checked
```

Reasoning about his uncertainty in your head does not count. It has to be visible at the moment he is about to say the number out loud.

Never invent numbers, dates, commitments, quotes, or conclusions. Not even plausible placeholder ones — he will read them under pressure and say them out loud.

Put a source link directly under any claim he may have to defend. Do not cite every bullet; citation noise defeats scanning.

## Handling uncertainty

Surface conflicts, never silently resolve them:

```markdown
UNCLEAR
Slack says the rollout is paused; the Linear issue is still In Progress.
→ Confirm before asserting either.
```

Stale sources:
```markdown
VERIFY
Latest source found is from May 14 — three months old.
```

His own unsupported points:
```markdown
UNVERIFIED
No primary source found for this. Included as your position, not as established fact.
```

His stated talking points always survive into the document as his intended position. They just never get promoted to externally validated fact.

Unresolved answers stay unresolved:
```markdown
ANSWER
I don't think we know yet.

WHAT WE DO KNOW
- ...

OPEN QUESTION
- ...
```

## Output format

One Markdown document, in this order:

1. `# [Meeting name]`
2. `## AT A GLANCE` — `GOAL`, `MY POSITION`, `ASK`, `DO NOT FORGET` (1–2 items max). Omit any line that isn't relevant. Keep it under ~10 lines; this is the pre-meeting glance.
3. `## CORE MESSAGE` — the one thing they must leave understanding, with `WHY` / `EVIDENCE`, ending in a `→` transition
4. Body sections in the shape from `formats.md`, `---` separated, most important first
5. `## LIKELY QUESTIONS` — `### ? <question in his words>`, then `ANSWER` / `KEY POINTS` / `IF PUSHED` / `SOURCE`
6. `## SOURCES` — only sources actually used, as `- [Description](link)`

See `example-output.md` for a complete rendered example.

## Common mistakes

| Mistake | Fix |
|---|---|
| Rewriting his bullets into prose | Restructure and add what he's missing; his bullets are the input, not the deliverable |
| Comprehensive coverage of the topic | Cut to what he'll need mid-sentence; everything else is noise on the page |
| A number with no link | Link it, qualify it, or mark `VERIFY BEFORE USING` |
| Every line bold | Bold the one word that matters per block |
| Questions phrased the way you'd phrase them | Phrase them the way the room will ask them, so Command-F hits |
| Chronological ordering | Importance ordering |
| Skipping research because his bullets seem complete | His bullets are intent; the record often disagrees |
| Asking clarifying questions before delivering anything | Infer, deliver, mark uncertainty inline |
| Artificially confident answers to open questions | `ANSWER / I don't think we know yet` + `OPEN QUESTION` |
| Slides invented for a presentation | Only use `## SLIDE N` when an actual deck exists; otherwise use `## TOPIC` |

## Rationalizations

Observed in baseline testing. Each of these produced a document Sean could not have used in the room.

| Rationalization | Reality |
|---|---|
| "I don't have his real data, so a scaffold with placeholders is the honest deliverable" | Honest and useless. Infer the concrete version, mark it `VERIFY`. Brackets are work handed back. |
| "I should explain up front what I couldn't access" | Not in the document. That's a sentence to him, outside the artifact. |
| "He said the number himself, so I can state it" | His memory is not a source. Marker on the page or it doesn't ship. |
| "A tilde signals the number is approximate" | Nobody reads a tilde mid-sentence under pressure. `VERIFY BEFORE USING`. |
| "Bold labels are clearer than repeating the same anchors" | Bespoke labels per block mean nothing is findable twice. Consistency IS the retrieval mechanism. |
| "A verbatim opener helps if he freezes" | One short quoted line, yes. Four sentences to read aloud is a script. |
| "This meeting is too emotional for terse fragments" | Especially then. He will be least able to parse prose in the room he's dreading. |
| "The ask is obvious from the content" | Then it costs one line at the top. `ASK` buried in section five is not retrievable. |
| "Ordering by time-in-room is more useful for a talk" | Only inside a section. The document still leads with what matters most. |

## Red flags — the document isn't done

- No `## AT A GLANCE` block, or no `ASK` line in it
- No `## LIKELY QUESTIONS` section for any meeting with other humans in it
- Any block label that appears exactly once in the document
- Any bullet with two clauses joined by "and" or an em-dash
- Any bracketed placeholder count above three
- Any sentence addressed to you rather than to the room
- A number without either a link or a verify marker within one line of it

## Out of Scope

This skill does **not**:

- Write the deck, the doc, the email, or the Slack message (use `message-crafter` for messages, `writing-as-sean` for prose under his name)
- Produce a written status update for async consumption (`weekly-update-formatter`)
- Create or update Linear tickets, Things tasks, or Notion pages as a side effect (`work-intake`)
- Rehearse, time, or critique his delivery
- Decide his position for him — it sharpens and defends the position he brings, and flags where it's weak
- Take notes during or after the meeting
