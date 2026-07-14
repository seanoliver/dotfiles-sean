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
4. **The why gets one sentence.** State what is true, once, then move to what the reader must do. Then delete the work you did to get there. This covers three things that all feel different and are the same:
    - **Evidence.** Search for *I found, I traced, in one run, we saw, confirmed, first command was, it said, logs show*, and for quotation marks around anything a tool or agent said. Delete those whole sentences.
    - **Rejected alternatives.** The options you considered and discarded. The reader is not re-making the decision, so the shortlist is yours, not theirs. Give them the choice, not the bracket.
    - **Reasoning.** The chain that got you from the evidence to the conclusion. Give the conclusion.

    The test for all three, and for rule 9: **would the reader act differently without this sentence?** If not, it is there for you. Keep only what is a guardrail against a wrong action, and cut what is a defense of a right one.
5. **Section titles are nouns.** Search every header for the words *What, Why, How, When, Who*. Count must be zero. A header containing one is a sentence. Rewrite it as the noun it is about: Measurement. Rationale. Background. Vendor tracks. Open questions. Success criteria.
6. **Every sentence carries its own weight.** Each one delivers a fact, an ask, or an instruction. If a sentence only prepares the ground for the next one, write the next one instead.
7. **A header must name its contents precisely enough to sort by.** Given the header alone, a reader should be able to say whether any given bullet belongs under it. `Ground rules`, `Notes`, `Details`, `Considerations`, `Context`, and `Misc` all fail this: they are nouns, but they name nothing, so wrong items hide under them. Ask what the list is actually for, then title it that: `Vendor requirements`, `Success criteria`, `Open questions`.
8. **Prose is complete sentences. Bullets and labels can be fragments.** Every sentence in a paragraph needs a subject and a verb. Terse means few sentences, not broken ones. If a fragment is carrying meaning, fold it into the sentence before it or write it out.
9. **Ask the question, then stop. Show the material, then stop.** Do not supply candidate answers to your own question. Do not describe the contents of a list, a quote, or a block that follows immediately. The reader can see it. Anything added is you predicting their reaction, and it reads as padding.
    - Ask: "What do you need from us?" Not: "What do you need from us? I'm assuming prompt format and repo specification, but tell me if there's more."
    - Introduce: "Here are the six prompts we'd like to run in the next wave." Not: "Here are the six prompts. Four leave the choice to the agent, two name Supabase as controls."
    - Facts stand on their own. Questions stand on their own. Material speaks for itself.

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
- [ ] For each header, ask: could a reader tell from this title alone whether a given bullet belongs under it? If not, retitle it after what the list is for.
- [ ] Read every paragraph sentence by sentence. Each one needs a subject and a verb. A fragment in prose is a rewrite, not a style.
- [ ] Find every question mark. If the next sentence answers the question, delete it.
- [ ] Find every list, quote, or block. If the sentence before it describes what is in it, delete that description.
- [ ] Find any list of options you considered and rejected. Delete it. State the choice.
- [ ] For every sentence that survived a cut: would the reader act differently without it? If not, cut it now.

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

## Critic loop

Your self-check catches the obvious. It does not catch what you cannot see, because you wrote it. Every draft that leaves this skill goes through a critic in a **fresh context**.

1. Draft, and run the self-check above.
2. **Dispatch `writing-critic` as a subagent** (Agent tool, `general-purpose`). Give it the rules path and the full draft verbatim. A subagent is required: a critic sharing your context inherits your rationalizations and returns `CLEAN` on your worst habits.
3. It returns `CLEAN`, or numbered findings with the offending text quoted.
4. If findings: apply them. Do not argue with a grep hit. For a judgment finding, apply it unless you can say what the reader would do differently without the sentence.
5. Dispatch the critic again on the revised draft.
6. Repeat until `CLEAN`, or three rounds. Three is the cap. A draft that survives three rounds is either clean or the critic is relitigating taste.

Report to Sean what the critic caught. He is calibrating these rules, and a finding you fixed silently is a finding he never sees.

## Examples

Before-and-after rewrites for each rule: see `REFERENCE.md` in this skill folder. Read it when a rule is unclear or a draft keeps failing the self-check.

## Out of scope

- **Deciding what to say.** This governs how it reads once the content is known. For finding the core ask, use `message-crafter`.
- **Repo PR templates.** Fill their sections. Apply this voice inside them.
- **Sean's conversation with Claude.** This is for prose he sends to others.
- **Code comments and commit messages.**
