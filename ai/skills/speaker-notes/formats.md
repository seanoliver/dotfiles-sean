# Format library

Pick the skeleton that matches the situation. Borrow blocks across types freely. Do not force every meeting into one template — the shape should mirror how the conversation will actually move.

Every type keeps: `## AT A GLANCE`, `## CORE MESSAGE`, `## LIKELY QUESTIONS`, `## SOURCES`.

---

## Front matter (all types)

```markdown
# [Meeting name] — [date]

## AT A GLANCE

GOAL
What I want to accomplish.

MY POSITION
The core position I expect to take.

ASK
The decision / feedback / action I want from the group.

DO NOT FORGET
- one critical thing I must say
- one thing I must not commit to
```

Omit any block that doesn't apply. `DO NOT FORGET` caps at two items — a third means nothing is emphasized.

---

## Presentation (a deck exists)

```markdown
## SLIDE 4 — Measurement approach

CORE POINT
We should separate DISCOVERY from REGRESSION monitoring.

WHY
- different questions
- different sample-size requirements

EVIDENCE
- [concise, sourced]

→ "Which raises the external-vs-in-house question"
```

Use `## SLIDE N — title` only when real slide numbers exist. Otherwise use `## TOPIC — title`.

Add `[PAUSE]` on its own line where he should stop and let the room react — after a number that needs to land, before an ask.

---

## Discussion meeting

```markdown
## TOPIC — Vendor decision

MY POSITION
...

WHY
- ...
- ...

WHERE I'M FLEXIBLE
- ...

QUESTION FOR GROUP
...

→ "..."
```

`WHERE I'M FLEXIBLE` is the block that keeps a discussion from turning into a defense. Include it when the topic is contested.

---

## Decision meeting

```markdown
## DECISION — Build vs buy

RECOMMENDATION
Build the regression harness in-house; keep a vendor for discovery.

WHY
- ...

TRADEOFF
What we give up if we do this.

RISK
What breaks if I'm wrong, and the early signal that tells us.

COST / EFFORT
- ...

ASK
Approve the split; I'll own the in-house side.
```

Always include `TRADEOFF` and `RISK`. A recommendation with neither reads as a sales pitch and invites the room to find the downside for him.

---

## Status update

```markdown
## STATUS — Project name

DONE
- ...

IN PROGRESS
- ...

BLOCKED
- ... — blocked on WHO / WHAT

NEXT
- ...

RISK
- ...
```

Name the blocker's owner explicitly. "Blocked on review" is useless in a room; "blocked on Prashant's review since Tuesday" is actionable.

---

## Demo

```markdown
## DEMO FLOW

1. Start on [screen] — say: "..."
2. Click [thing] → shows [outcome]
3. [PAUSE] let them react

WHAT THIS PROVES
- ...

WHAT'S NOT REAL YET
- ...

IF IT BREAKS
→ "..." then show [fallback]
```

`WHAT'S NOT REAL YET` and `IF IT BREAKS` are mandatory for demos. Both failures — overclaiming, and freezing on a bug — happen live and are avoidable on paper.

---

## 1:1

```markdown
## TOPIC — Scope of the ALG work

WHAT I WANT
...

CONTEXT THEY MAY NOT HAVE
- ...

WHAT I NEED FROM THEM
- ...

→ "..."
```

Order by what he cares about most, not by what's easiest to raise. The awkward item goes first or it doesn't get raised.

---

## Interview / panel

```markdown
## TOPIC — Why this role

CORE POINT
...

STORY
- setup → what I did → outcome

EVIDENCE
- ...
```

`STORY` is the only place a three-beat structure beats bullets. Keep each beat to one line.

---

## Difficult conversation

```markdown
## OPENING

SAY FIRST
"..."

NOT ON THE TABLE
- [X] — don't get drawn into it
- [Y] — don't commit on the spot

---

## TOPIC — The actual issue

MY POSITION
...

EVIDENCE
- specific, dated, sourced

IF THEY PUSH BACK
→ "..."

IF IT ESCALATES
→ "Let's take this offline / follow up in writing"
```

`NOT ON THE TABLE` up front is the highest-value block in this format — it's the pre-commitment that survives when the conversation gets warm. Put the specific concession he's most likely to make under social pressure at the top of it.

---

## Likely questions (all types)

```markdown
## LIKELY QUESTIONS

### ? Why don't we just build this ourselves?

ANSWER
We probably should, for the long-term regression use case.

WHY
- internal eval framework already covers most of the infrastructure
- easier to integrate into the dev workflow

IF PUSHED
DISCOVERY = useful external perspective
REGRESSION = better owned internally

SOURCE
- [Feasibility investigation](link)
```

Cover these categories, ranked by likelihood × damage:

- clarification ("what do you mean by X")
- objection ("this won't work because…")
- request for evidence ("how do we know that")
- "why didn't we just…"
- cost / effort / timing
- ownership ("who's doing this")
- tradeoff and alternative approaches
- risk ("what if it fails")
- next steps
- "what are you actually asking us to decide"

The last one belongs in nearly every deck. If he can't answer it in one line, the notes aren't done.
