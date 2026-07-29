---
name: eli5
description: Use when Sean explicitly asks to simplify or re-explain the previous message — "/eli5", "eli5 that", "break that down", "simpler please", "I can't absorb this", "my brain is fried", "too dense". Manually triggered only; never auto-apply after a dense message.
---

# ELI5 — Re-explain the Last Message Simply

## Overview

Translate the last substantive assistant message into a short, plain-language version Sean can absorb when his attention is flagging. The job is **selection and translation, not compression**: drop most of the detail, keep only what changes what he does next.

## Read First

Re-read the last substantive assistant message in this conversation (skip trivial acks). That message is the ONLY source. Do not pull in earlier context, re-run analysis, or fetch anything new.

## Output Format (exact — use every time)

```
**In one line:** <the single most important thing from the message>

**What happened**
- <bullet>
- <bullet>
(3–6 bullets)

**Key takeaways**
- <bullet>
(1–3 bullets — what Sean should remember even if he forgets everything else)

**Next action**
→ <exactly one concrete step>
```

Nothing outside these four sections. No tables, no nested bullets, no headers beyond these, no ★ Insight blocks.

## Rules

1. **Bullets are ≤ 12 words.** One idea per bullet. If a bullet needs a second clause, split it or cut it.
2. **Total output fits one screen** (~150 words). If it's longer, cut detail — don't shrink the wording.
3. **Cut, don't compress.** Drop anything that doesn't change a decision or the next action. Six findings in the original does not mean six bullets here.
4. **No jargon.** Replace technical terms with plain words. If a term is unavoidable (a table name, a ticket ID), gloss it in parentheses once.
5. **Never add facts.** Simplify wording, not meaning. Do not upgrade "sent a sample" to "accidentally sent," or hedges into certainties. When simplifying would change the claim, stay vague instead.
6. **Exactly one next action.** Not a menu, not a list. If the original had several, pick the blocking one.
7. **Keep only load-bearing links/IDs** — the ones the next action needs. Drop the rest.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Restating every point in simpler words | Select 3–6 points; delete the rest |
| Paragraphs between sections | Bullets only, in the fixed format |
| Adding causal claims ("accidentally", "because") | Only claims present in the original |
| Multiple next steps | One. The blocking one. |
| Simplifying so much the takeaway is wrong | Vague-but-true beats simple-but-false |

## Out of Scope

- Code simplification or refactoring — that's the `/simplify` skill, not this one.
- Summarizing the whole conversation or a document — this covers the last message only.
- Re-running analysis, fetching data, or answering new questions.
- Auto-triggering: only run when Sean explicitly asks.
