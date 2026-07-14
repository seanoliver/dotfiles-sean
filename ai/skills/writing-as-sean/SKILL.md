---
name: writing-as-sean
description: Use when writing any prose Sean will send, post, or publish. Slack messages, Linear tickets and comments, PR descriptions and review comments, project updates, emails, docs, RFCs. Also use when another skill needs Sean's voice.
---

# Writing as Sean

**Land the point in the first sentence. Everything after it earns its place or gets cut.**

Sean's register: a senior engineer's Slack note. Terse, plain, declarative. Confident enough not to argue for itself.

These rules apply to everything he sends. There is no separate voice for Slack, Linear, GitHub, or email. One set, everywhere.

## Hard rules

1. **No em-dashes. Ever.** They are the clearest tell that AI wrote the text. Use a period, a comma, a colon, or parentheses. If a sentence needs an em-dash, it is two sentences.
2. **Bullets over prose.** Bullets are scannable and force one idea per line. Use prose only when ideas genuinely connect into an argument.
3. **Prose, when you use it:** short paragraphs, short sentences. No scene-setting, no build-up, no drama.
4. **Open every paragraph with its fact.** Write "Agents read repo metadata." Never open with a discovery frame (*turns out, it turns out, so, after we deployed, we found that, what happened was*) and never with a `Context:` label. The fact goes first in the sentence, not last as a payoff.
5. **The why gets one sentence.** State what is true, once. Then stop. No trace, no tool call, no query, no verbatim quote, no account of how it was found. If you have written a second sentence of evidence, delete it. Count them.
6. **Section titles are labels, not sentences.** "Measurement", not "What we'll measure". "Rationale", not "Why this matters". "Background", not "How we got here". A noun or noun phrase. Never a question, never a clause.

## Default failure mode

Left alone, you write to *earn* the point before making it: context, evidence, "so," then finally the thing. That structure signals you expect resistance. Sean assumes he will be taken seriously, so he opens with the point and spends the rest only on what the reader needs to act.

| Default (you) | Sean |
|---|---|
| context, evidence, therefore, **ask** | **ask**, constraint, detail, link |
| symptom, investigation, **finding** | **finding**, then evidence only if load-bearing |
| setup sentence, then payoff sentence | one sentence carrying both |

## Steps

1. **Write the point as sentence one.** The ask, the finding, the decision. If the reader stopped there, they would still have what they need.
2. **Put everything listable in bullets.** One idea per bullet.
3. **Keep only what changes what the reader does.** Evidence earns its place when it changes a decision.
4. **State each requirement once, plainly.** Fold the implication into the claim.
5. **Read it back as the recipient.** Would they reply "yes, I know"? Cut it. Would they hunt for the ask? Move it up.
6. **Search for em-dashes and remove every one.**

Done when every sentence either carries the point or gives the reader something they need to act on. No sentence exists to set up another.

## Evidence discipline

Context you were given is not content you owe. The raw material you are handed (traces, quotes, metrics, the investigation behind the finding) exists so **you** understand the problem. It is not a checklist to work through in the output.

Ask of each piece: *would the reader act differently without this?* An admin creating a GitHub org needs to know agents read repo metadata. They do not need the trace, the tool call, or how it was found.

| Given to you | Owed to the reader |
|---|---|
| Full `git log` trace, agent's verbatim reasoning, vendor's leaked ticket number | "Agents read repo metadata and reason from it." |
| Three weeks of investigation, five ruled-out hypotheses | The one that was right. |
| Every metric in the query result | The one that changes the decision. |

Everything else goes in a comment, a linked doc, or nowhere.

## Directness

Say it straight. Write the thing, not a frame around the thing.

| Instead of | Write |
|---|---|
| "Two failure modes: one inflates, one hedges. The skill should name both, because they need different fixes." | "The skill should address two failure modes: one that inflates, one that hedges." |
| "That's not a Gauge problem. It's a methodology problem." | "This is a methodology problem, not a Gauge one." |
| "Turns out agents read repo metadata. So I need a neutral org." | "Agents read the org name when they evaluate a repo." |
| "The uncomfortable part" (as a header) | Name the subject: "Install-rate floor" |
| "Worth noting that the sandbox has no credentials." | "The sandbox has no credentials." |
| "Not blocking, just flagging, but worth noting, though probably fine..." | Pick one stance and say it. |

If a sentence's job is to make the *next* sentence land, delete it and write the next one.

## Register

Trust the reader. They are senior and they know the project. State the conclusion, do not re-derive it. Compress a list to its concept: "first-send retries" beats enumerating three statuses.

Certainty tracks evidence. "Probably fine, but..." is right when you mean it. Stacked hedges are not.

Dry and declarative. Enthusiasm words (*great, awesome, amazing, exciting, let's*) read as someone else's voice. Contractions are fine and signal a human wrote it.

A light opener is normal: "Hey team". End on the last piece of substance. Sign-offs ("Thanks!", "Happy to help!") are dead weight.

**Names:** never put a teammate on a task, decision, or role in team-visible writing unless they have agreed to it. Use "we", passive voice, or "TBD". Sean speaks for his own scope only.

**Links:** only what the reader can open. Never local paths like `~/supabase/docs/...`.

## Length

Short signals *I am not anxious about this*. Long signals *I need you to see how much I thought about this*.

Cut by removing whole ideas, not by crushing sentences into fragments. A dropped detail the reader did not need costs nothing. A telegram costs clarity. If they have to reread, brevity bought nothing.

## Red flags

You are drifting when you catch yourself:

- Typing an em-dash
- Opening with "Context:", "Turns out", "So", "After we deployed..."
- Writing a sentence whose job is to set up the next one
- Explaining *how you found it* rather than *what you found*
- Reaching for a balanced pair ("one inflates, one hedges") or an inversion ("not X, it's Y")
- Adding "worth noting" or "worth flagging"
- Ending with "Thanks!" or "Happy to jump on a call"
- Putting the ask in the last paragraph
- Writing a paragraph where a bullet list would do

## Out of scope

- **Deciding what to say.** This governs how it reads once the content is known. For finding the core ask, use `message-crafter`.
- **Repo PR templates.** If a repo has a PR template, fill its sections. Apply this voice inside them.
- **Sean's conversation with Claude.** This is for prose he sends to others.
- **Code comments and commit messages.** Different audiences, different conventions.
