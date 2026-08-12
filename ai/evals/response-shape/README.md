# Response-shape evals

Measures whether Cortex's replies obey the countable rules in `SOUL.md`. Those
rules exist because the judgment-style rules beside them ("cap it", "one next
action") were being rationalized past under load.

## Run it

```bash
./run.sh                    # tag "run", 3 reps per case
REPS=5 ./run.sh nightly     # more reps, tighter rate
MODEL=opus ./run.sh o       # different model
PAR=4 ./run.sh slow         # fewer parallel sessions
```

Every rep is a fresh headless session, so `SOUL.md` loads through the normal
`SessionStart` hook and the result reflects real behavior rather than the
authoring session's context. `claude` is an interactive alias on this machine, so
`run.sh` addresses the binary by path; override with `CLAUDE_BIN`.

## Reps are the point

The first version of this suite ran each case once. That was useless in a
specific way: on two runs of the identical `debug` prompt, minutes apart, the same
rules produced 39 words and a pass, then 192 words and two failures. A single
green run cannot tell a rule that always fires from one that fires half the time,
and a one-run before/after comparison will happily show a fix that is really
sampling noise.

So a case reports `2/3`, not `PASS`. Read the rate, not the run.

## Cases and gates

`cases.tsv` is `name<TAB>rule-tag<TAB>prompt`. A `@file` prompt is read from that
file. The tag selects which checks gate the case, because most rules only apply to
a matching prompt. Every check is still measured and printed for every case; only
the gated ones can fail it.

| Tag | Gates | Prompt shape |
|---|---|---|
| `before-you-send` | length, opener, closer, list cap, menu ending, landing | ordinary requests, plus the report-shaped one |
| `land-the-plane` | length, opener, closer, names one pick | "should I use A, B, or C" |
| `time-in-units` | length, opener, at least one concrete duration | "how long will X take" |
| `numbered-steps` | length, opener, plan is numbered, list cap | "give me a plan" |
| `no-hype` | length, opener, zero hype words | bait: work worth praising |
| `no-emoji` | zero emoji | bait: a Slack one-liner |

`hard.txt` is the case that matters most: a pile of audit findings plus "report
back on the audit". That shape is what actually breaks the rules. The three
ordinary prompts passed the density check before any rule was added, so a suite of
only easy cases would have reported a clean bill of health while the real failure
went unmeasured.

## Coverage, honestly

`SOUL.md` asserts far more than this suite checks. Covered: the four counts in
`## Before you send`, the plan-numbering and duration rules from
`## Multi-step work`, land-the-plane from `## Explaining things`, and the emoji and
hype bans. Not covered and not mechanically checkable today: glossing jargon on
first use, pronouns having clear referents, concrete-over-abstract, restating
"step N of M" across turns (needs a multi-turn harness, not one-shot), and every
rule about *correctness* rather than shape.

A green suite means the replies are shaped right. It says nothing about whether
they were true or useful.

## The outcome metric

The suite measures compliance. The thing worth watching is whether Sean still has
to ask for a simpler version:

```bash
grep -c 'slash:eli5' ~/.claude/skill-usage.tsv
awk -F'\t' '/eli5/{print substr($1,1,10)}' ~/.claude/skill-usage.tsv | sort | uniq -c
```

At the time this was written: 47 invocations across 11 active days, 4.3 per day,
the highest per-day rate of any skill. `SOUL.md` calls an `/eli5` invocation a
failed explanation, which makes that number the real scoreboard. If the rules
work, it falls.

## Caveats

- One model per run, three reps by default. Enough to catch a regression, not
  enough to call a small delta real.
- Word count is a proxy. A tight 250-word answer to a genuinely large question
  fails this suite and should.
- False positives are expensive here. A mechanical check that cries wolf gets
  skimmed, and then a real violation walks through. Two were already found and
  narrowed during authoring: an opener regex that missed meta-narration, and a
  menu detector that flagged the word "or" inside an ordinary sentence.
