# Response-shape evals

Measures whether Cortex's replies obey the countable rules in `SOUL.md` under
`## Before you send`. Those rules exist because the judgment-style rules above
them ("cap it", "one next action") were being rationalized past under load.

## Run it

```bash
./run.sh baseline      # writes out/baseline-*.txt and scores them
MODEL=opus ./run.sh x  # override the model
```

Each prompt runs in a fresh headless session, so `SOUL.md` loads through the
normal `SessionStart` hook and the result reflects real behavior rather than
this session's context.

## What it checks

Mechanical only. Every check is a count, so a failure is a fact rather than an
opinion:

| Check | Fails when |
|---|---|
| `over_limit` | more than 200 words |
| `announcing_opener` | first two lines contain "Here's the", "Let me", "This is a", … |
| `closer` | trailing "let me know if", "hope this helps", … |
| `list_over_5` | more than five consecutive bullets or numbered items |
| `menu_ending` | last line offers a choice ("want me to X or Y") |
| `no_landing` | last line is not an action, a question, or a thing being done |
| `hedges` / `idioms` | any hit |

## Why these prompts

`prompts.tsv` holds three ordinary requests. `hard.txt` is the one that matters:
a pile of audit findings with "report back on the audit". That shape is what
actually breaks the rules. The three simple prompts passed the density check
before any change was made, so a suite of only easy cases would have shown a
clean bill of health while the real failure went unmeasured.

## Measured results, 2026-08-12

Adding the `## Before you send` block:

| Case | Before | After |
|---|---|---|
| `hard` (report-shaped) | FAIL, 334 words, announcing opener, menu ending | PASS, 196 words |
| `debug` | FAIL, no landing | PASS |
| `multistep` | PASS | PASS |
| `options` | FAIL, no landing | FAIL, no landing |

`options` is the known open failure: asked to choose between three tools, the
reply ends on a two-branch conditional instead of picking one. `SOUL.md` already
says to land the plane and it does not fire on comparison questions. Unfixed.

## The outcome metric

The suite measures compliance. The thing worth watching is whether Sean still
has to ask for a simpler version:

```bash
grep -c 'slash:eli5' ~/.claude/skill-usage.tsv
awk -F'\t' '/eli5/{print substr($1,1,10)}' ~/.claude/skill-usage.tsv | sort | uniq -c
```

At the time this was written: 47 invocations across 11 active days, 4.3 per day,
the highest per-day rate of any skill. `SOUL.md` names an `/eli5` invocation as
a failed explanation, so that number is the scoreboard. If the rules are working
it should fall.

## Caveats

- Four cases, one run each, one model. Enough to catch a regression, not enough
  to call a small delta real.
- Word count is a proxy. A tight 250-word answer to a genuinely large question
  fails this suite and should. Read the output before believing the score.
- The checks cannot see the thing that matters most, which is whether the answer
  was correct and useful. They only see its shape.
