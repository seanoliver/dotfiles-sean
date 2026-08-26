# Example output

> **This is a formatting reference only.** Every claim, number, and link below is illustrative and must not be reused as fact. Copy the *shape*, never the content.

The example is a decision meeting with a `TOPIC` body section — the most common shape.

---

```markdown
# Eval tooling — build vs buy (Aug 26)

## AT A GLANCE

GOAL
Get agreement on splitting discovery from regression, and on who owns each.

MY POSITION
Buy discovery. Build regression in-house on the existing evals repo.

ASK
Approve the split. I'll own the in-house side and come back with a timeline.

DO NOT FORGET
- Say up front that this is not a rejection of the vendor
- Do NOT commit to a delivery date today

---

## CORE MESSAGE

We're trying to make one tool do two different jobs, and that's why the cost math keeps failing.

WHY
- discovery asks "what's broken that we don't know about"
- regression asks "did the thing we already fixed stay fixed"
- the second one needs consistency and volume; the first needs breadth

EVIDENCE
- Run economics break down at the volume regression needs
  SOURCE [feasibility investigation](https://example-placeholder)

→ "So the question isn't which vendor — it's which job we're buying."

---

## TOPIC — Regression harness in-house

CORE POINT
The evals repo already covers most of what a regression harness needs.

WHY
- scoring infrastructure exists
- integrates with the dev workflow, so it runs on every change
- no per-run cost ceiling

EVIDENCE
- The two blockers I found both turned out to be already handled
  SOURCE [investigation](https://example-placeholder)
- Prompt-bias issue is already tracked and scoped
  SOURCE [linear issue](https://example-placeholder)

RISK
Someone has to own it, and that someone is me for the first quarter.

→ "Which leaves the discovery side."

---

## TOPIC — Discovery stays external

MY POSITION
Keep a vendor for discovery, on BYOK.

WHY
- outside perspective finds things we're blind to
- low volume, so the run economics work

WHERE I'M FLEXIBLE
- which vendor
- whether we run continuously or in waves

QUESTION FOR GROUP
Do we want discovery on a cadence, or only before major launches?

---

## LIKELY QUESTIONS

### ? Why not just use one vendor for both?

ANSWER
Because the two jobs have different requirements, and the vendor is priced for the wrong one.

KEY POINTS
- discovery benefits from breadth
- regression needs the same harness every time
- cost per run stops mattering at low volume and dominates at high volume

IF PUSHED
The decision should follow the job each system is doing, not the convenience of one contract.

SOURCE
- [run-economics thread](https://example-placeholder)

### ? What are you actually asking us to decide?

ANSWER
Just the split. Approve that discovery is bought and regression is built, and I'll bring the plan back.

### ? How long until the in-house harness is usable?

ANSWER
I don't want to give a date in this room yet.

WHAT WE DO KNOW
- the scoring infrastructure is already there
- the known blockers are tracked, not open-ended

OPEN QUESTION
- how much of the existing harness needs rework for our task shapes

### ? Didn't we already agree to the vendor?

ANSWER
We agreed to evaluate them, and the evaluation is what produced this split.

UNCLEAR
Slack reads as a commitment; the Linear issue is still in Triage.
→ Confirm before asserting either.

---

## SOURCES

- [Feasibility investigation](https://example-placeholder)
- [Linear: prompt-bias issue](https://example-placeholder)
- [Slack: run-economics thread](https://example-placeholder)
```

---

## What makes this work

- Every block is ≤ 5 lines, so any one of them is absorbable in a glance
- `ASK` and `DO NOT FORGET` sit at the very top, where a pre-meeting glance lands
- Questions are phrased the way the room would ask them, so Command-F on "one vendor" or "how long" hits
- The unresolved timeline question stays unresolved instead of getting a confident fake answer
- The one conflict between sources is surfaced as `UNCLEAR` rather than silently picked
