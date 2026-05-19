# Skill Ideas Backlog

Append-only log of opportunities to create new skills, improve existing ones, or split / merge skills. Triage periodically — promote to action or move to Archived.

**Format:** `- YYYY-MM-DD — short description (type: new | improve | split | merge). Why this matters.`

Keep entries to a single line where possible. Link to relevant context (X posts, conversations, files) inline.

## Active

- 2026-04-27 — Audit all existing skills under `~/dotfiles/ai/skills/` for an explicit `## Out of Scope` section (type: improve). Per [Anatomy of a Perfect Skill](https://x.com/zodchiii/status/2048345453096313005) pattern 5 — most skills lack this and it's the highest-impact addition. Pattern: explicitly list what the skill does NOT do.
- 2026-04-27 — Audit all existing skills against the six Anatomy patterns broadly (type: improve). Especially patterns 2 (directive imperative language), 3 (explicit output format), and 4 ("read first" step). Reference: writing-skills SKILL.md → "Six Anatomy Patterns" section.
- 2026-04-28 — Audit `weekly-update-formatter` and `message-crafter` for the same fabrication loophole as writing-pr-descriptions (type: improve). Why: confident-voice constraints + AI agent producing artifacts about events the AI didn't witness = high risk of plausibly-wrong past-tense claims. Apply the same fix pattern: require unchecked checklists / "haven't verified" disclaimers when the writer didn't observe the event firsthand.
- 2026-05-18 — Add a `humanizer` skill (type: new). Why: even after invoking writing-pr-descriptions, AI-authored PR bodies leak tells — parallel construction, balanced sentence rhythm, "Reasoning:"-style preambles, every paragraph landing on a complete thought, etc. A focused post-pass skill should diff the draft against Sean's voice (SOUL.md + PR Description Guidelines) and call out specific AI-tells with proposed edits. Should also work on Slack messages, Linear comments, and other async written outputs — not just PRs. Triggered by phrases like "humanize this", "make this sound human", "AI-tell check", or applied automatically as a final pass on writing-pr-descriptions / message-crafter / weekly-update-formatter outputs.

## Archived

_(items completed or no longer relevant)_

- 2026-05-19 — `slack-mention-triage` skill (type: new). **Shipped same day.** Required output is summary → verdict → one next action → optional handoff to message-crafter. RED baseline came from the 2026-05-19 Scope/AEO triage where the first-pass response skipped the summary on the implicit rationalization "Sean shared the URL so he knows what's in it" — Sean explicitly corrected this. Skill encodes "summary always, regardless of verdict" as the core insight.
- 2026-04-28 — `writing-pr-descriptions` should require honesty about untested verification (type: improve). **Shipped same day.** Patched principle #8, Testing template, Common Mistakes, and Red Flags to require unchecked `- [ ]` checklists for unverified items and forbid fabricated past-tense. GREEN-verified against /tmp/pr-45173.diff. **Open follow-up:** confirmed-similar loophole likely exists in `weekly-update-formatter` and `message-crafter` (both have confident-voice constraints) — not yet audited.
