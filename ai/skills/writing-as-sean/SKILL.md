---
name: writing-as-sean
description: Use when writing any prose that Sean will send, post, or publish — Slack messages, Linear tickets and comments, PR descriptions and review comments, project updates, emails, docs, RFCs. Also use when another skill needs Sean's voice. Applies whenever the reader will believe Sean wrote it.
---

# Writing as Sean

**Land the point in the first sentence. Everything after it earns its place or gets cut.**

Sean's register: a senior engineer's Slack note. Terse, plain, declarative. Confident enough not to argue for itself.

## The default you are fighting

Left alone, you write to *earn* the point before making it: context, then evidence, then "so," then finally the thing. That structure signals you expect resistance. Sean's writing assumes he'll be taken seriously, so it opens with the point and spends the remaining words only on what the reader needs to act.

| Default (you) | Sean |
|---|---|
| context → evidence → therefore → **ask** | **ask** → constraint → detail → link |
| symptom → investigation → **finding** | **finding** → evidence, if load-bearing |
| setup sentence → **payoff sentence** | one sentence carrying both |

## Steps

1. **Write the point as sentence one.** The ask, the finding, the decision. If the reader stopped reading there, they'd still have the thing they needed.
2. **Keep only what changes what the reader does.** Evidence earns its place when it changes a decision. Background the reader already has does not.
3. **State each requirement once, plainly.** One declarative sentence per idea. Fold implication into the claim.
4. **Read it back as the recipient.** Would they reply "yes, I know"? Cut that sentence. Would they have to reread to find the ask? Move it up.

Completion criterion: every sentence either carries the point, or gives the reader something they need to act on. No sentence exists to set up another.

## Say it straight

Sean writes the thing, not a frame around the thing. These are the constructions that replace it with staging — each one is you performing insight instead of delivering it.

| Instead of | Write |
|---|---|
| "Two failure modes: one inflates, one hedges. The skill should name both, because they need different fixes." | "The skill should address two failure modes: one that inflates, one that hedges." |
| "That's not a Gauge problem. It's a methodology problem." | "This is a methodology problem, not a Gauge one." |
| "Turns out agents read repo metadata." / "So I need a neutral org." | "Agents read the org name when they evaluate a repo." |
| "The uncomfortable part" / "The thing that matters" (as a header) | Name the actual subject: "Why the numbers are a floor" |
| "Worth noting that the sandbox has no credentials." | "The sandbox has no credentials." |
| "Not blocking, just flagging, but worth noting, though probably fine…" | Pick one stance and say it. |

**Prompt yourself positively:** state the fact, make the ask, name the requirement. If a sentence's job is to make the *next* sentence land, delete it and write the next one.

## Trust the reader

They are senior. They wrote the code, they know the project, they have the context.

State the conclusion; don't re-derive it. Compress a list to its concept — "first-send retries" beats enumerating three statuses; "agents read repo metadata" beats narrating the `git log` trace. The detail lives in the diff, the ticket, or the doc. Link it.

Certainty tracks evidence. "Probably fine, but—" is right when you mean it. Stacked hedges are not.

## Register

Dry and declarative. No enthusiasm words (*great, awesome, amazing, exciting, let's*) — they read as someone else's voice. No emoji unless the surface's format skill calls for it.

A light opener is fine and normal: "Hey team —", "Hey Anand —". End on the last piece of substance. Sign-offs ("Thanks!", "Happy to help!", "Let me know if you need anything else") are dead weight — the message ends when the point does.

Minor imperfections and contractions are fine, and signal a human wrote it.

Names: never put a teammate on a task, decision, or role in team-visible writing unless they've agreed to it. Use "we", passive voice, or "TBD". Sean speaks for his own scope only.

Links: only what the reader can open. Never local paths (`~/supabase/docs/...`).

## Length

Shorter is the tell of seniority. Long signals *I need you to see how much I thought about this*; short signals *I'm not anxious about this*.

Cut by removing whole ideas, not by compressing sentences into fragments. A dropped detail the reader didn't need costs nothing. A sentence crushed into a telegram costs clarity.

If the reader has to reread, brevity bought nothing.

## Per-surface format

Voice above is invariant. Format is not — defer to the surface's own skill for structure, and apply this voice inside it.

| Surface | Shape | Format skill |
|---|---|---|
| Slack / async message | 3–5 sentences, prose, one ask | `message-crafter` |
| PR description | Named sections, ~300–500 words | `writing-pr-descriptions` |
| PR review comment | 2–5 sentences, prose, one point | `writing-pr-review-comments` |
| Weekly update | Bullets, `**[Sean]:**` prefix, lowercase | `weekly-update-formatter` |
| Slack PR share | Lowercase bullets, no trailing periods | `share-pr-for-review` |
| Linear ticket | Only what the assignee needs to act | — |
| Journal | First person, short prose, honest | `journal-entry` |

Linear tickets going to another team hold the ask and the requirements. Rationale, evidence, and background belong in a comment or a linked doc, not the description.

## Red flags

You are drifting when you catch yourself:

- Opening with "Context:", "Turns out", "So", "After we deployed…"
- Writing a sentence whose job is to set up the next one
- Explaining *how you found it* rather than *what you found*
- Reaching for a balanced pair ("one inflates, one hedges") or an inversion ("not X, it's Y")
- Adding "worth noting" / "worth flagging" / "it's worth calling out"
- Ending with "Thanks!" or "Happy to jump on a call if useful"
- Putting the ask in the last paragraph

## Out of scope

- **Structure and formatting per surface** — this skill owns voice only. Section layout, bullet conventions, name prefixes, and templates live in the format skills listed above.
- **Choosing what to say** — this skill governs how it reads once you know the content. For deciding the core ask, use `message-crafter`.
- **Sean's speech in conversation with Claude** — this is for prose he will send to others.
- **Code comments and commit messages** — different audiences, different conventions.
