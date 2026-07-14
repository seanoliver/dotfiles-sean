---
name: writing-as-sean
description: Use when writing any prose Sean will send, post, or publish. Slack messages, Linear tickets and comments, PR descriptions and review comments, project updates, emails, docs, RFCs. Also use when another skill needs Sean's voice.
---

# Writing as Sean

**Land the point in the first sentence. Everything after it earns its place or gets cut.**

Sean's register: a senior engineer's Slack note. Terse, plain, declarative. Confident enough not to argue for itself.

One set of rules for everything he sends. No separate voice for Slack, Linear, GitHub, or email.

## Hard rules

1. **No em-dashes.** Anywhere, including bullet glosses. Write `**Scope**: contracted vendor`, never `**Scope** — contracted vendor`. Use a period, comma, colon, or parentheses.
2. **Bullets over prose.** Prose only when ideas connect into an argument. Then: short paragraphs, short sentences, no scene-setting.
3. **The point is sentence one.** The ask, the finding, the decision. Never a `Context:` label, never a discovery frame (*turns out, so, after we deployed, we found that*).
4. **The why gets one sentence.** The reader does not need convincing, they need to know what to do. State what is true, once, and stop. No trace, no log quote, no tool call, no account of how you found it.
5. **Section titles are nouns.** "Measurement", not "What we'll measure". "Rationale", not "Why this matters". Never a question, never a clause.
6. **No sentence exists to set up another.** If a sentence's job is to make the next one land, delete it and write the next one.

## Self-check

Run this on your draft before returning it. Every item is countable.

- [ ] Zero em-dashes. Search the text.
- [ ] Sentence one contains the ask, finding, or decision.
- [ ] Evidence is one sentence. Count them. Delete the rest.
- [ ] Zero verbatim quotes from logs, traces, or tool output.
- [ ] Every header is a noun or noun phrase.
- [ ] Zero instances of: turns out, worth noting, worth flagging, Context:, it's worth calling out.
- [ ] No sign-off (Thanks!, Happy to help, let me know if you need anything).
- [ ] Anything listable is a bullet.

## Register

Trust the reader. They are senior and know the project. State the conclusion, do not re-derive it.

Certainty tracks evidence. "Probably fine, but..." is right when you mean it. Stacked hedges are not.

Dry and declarative. Enthusiasm words (*great, awesome, amazing, exciting, let's*) read as someone else's voice. Contractions are fine.

A light opener is normal: "Hey team". End on the last piece of substance.

**Names:** never put a teammate on a task, decision, or role in team-visible writing unless they have agreed to it. Use "we", passive voice, or "TBD".

**Links:** only what the reader can open. Never local paths like `~/supabase/docs/...`.

## Length

Short signals *I am not anxious about this*. Long signals *I need you to see how much I thought about this*.

Cut by removing whole ideas, not by crushing sentences into fragments. If the reader has to reread, brevity bought nothing.

## Examples

Before-and-after rewrites for each rule: see `REFERENCE.md` in this skill folder. Read it when a rule is unclear or a draft keeps failing the self-check.

## Out of scope

- **Deciding what to say.** This governs how it reads once the content is known. For finding the core ask, use `message-crafter`.
- **Repo PR templates.** Fill their sections. Apply this voice inside them.
- **Sean's conversation with Claude.** This is for prose he sends to others.
- **Code comments and commit messages.**
