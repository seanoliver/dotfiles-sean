---
name: writing-as-sean
description: Use when writing any prose Sean will send, post, or publish. Slack messages, Linear tickets and comments, PR descriptions and review comments, project updates, emails, docs, RFCs. Also use when another skill needs Sean's voice.
---

# Writing as Sean

**Land the point in the first sentence. Everything after it earns its place or gets cut.**

Sean's register: a senior engineer's Slack note. Terse, plain, declarative. Confident enough not to argue for itself.

One set of rules for everything he sends. No separate voice for Slack, Linear, GitHub, or email.

## Hard rules

1. **No em-dashes.** Not in sentences, not in bullet glosses. Gloss a bullet with a colon: `**Scope**: contracted vendor`. Elsewhere use a period, comma, colon, or parentheses. If a sentence seems to need one, it is two sentences.
2. **Bullets over prose.** Prose only when ideas connect into an argument. Then: short paragraphs, short sentences, no scene-setting.
3. **The point is sentence one.** Open with the ask, the finding, or the decision. The first words the reader sees are the thing they need.
4. **The why gets one sentence.** State what is true, once, then move to what the reader must do. Then delete every sentence describing something you ran, observed, traced, or confirmed. Search your draft for *I found, I traced, in one run, we saw, confirmed, first command was, it said, logs show*, and for quotation marks around anything a tool or agent said. Delete those whole sentences. The evidence always feels load-bearing to whoever gathered it and never is to whoever must act on it.
5. **Section titles are nouns.** Search every header for the words *What, Why, How, When, Who*. Count must be zero. A header containing one is a sentence. Rewrite it as the noun it is about: Measurement. Rationale. Background. Vendor tracks. Open questions. Success criteria.
6. **Every sentence carries its own weight.** Each one delivers a fact, an ask, or an instruction. If a sentence only prepares the ground for the next one, write the next one instead.

## Self-check

Run these searches on your draft before returning it. Each one is countable, not a judgment call.

- [ ] Search for em-dashes. Count must be zero.
- [ ] **Delete every sentence describing something you ran, observed, traced, or confirmed.** Search for: *I found, I traced, in one run, we saw, confirmed, first command was, it said, logs show*. Delete the whole sentence, not part of it. Ship what remains.
- [ ] Search for quotation marks around anything a tool or agent said. Delete those sentences too.
- [ ] Sentence one contains the ask, the finding, or the decision.
- [ ] **Search your headers for the words: What, Why, How, When, Who.** Count must be zero. A header containing any of them is a sentence, not a title. Rewrite it as the noun it is about: `Measurement`, `Rationale`, `Background`, `Vendor tracks`, `Open questions`, `Success criteria`.
- [ ] Search for: *turns out, worth noting, worth flagging, Context:, it's worth calling out*. Count must be zero.
- [ ] Search for: *Thanks!, Happy to help, let me know if you need anything*. Count must be zero.
- [ ] Anything listable is a bullet.

The second item is the one you will want to skip. Do not skip it. The evidence always feels load-bearing to the person who gathered it, and never is to the person who has to act.

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
