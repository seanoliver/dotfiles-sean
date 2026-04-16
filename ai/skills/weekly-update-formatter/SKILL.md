---
name: weekly-update-formatter
description: Formats disorganized personal notes into polished weekly update bullets for a growth engineering team meeting. Use this skill whenever the user asks to format, clean up, or turn notes into a weekly update, standup summary, or team update — even if they don't use the word "skill". Trigger on phrases like "format my update", "turn this into bullets", "weekly update", "write up my update", "clean up my notes for the meeting", etc.
argument-hint: [paste your raw notes]
---

# Weekly Update Formatter

Transforms raw, disorganized notes into a structured weekly update for the growth engineering team meeting. The meeting notes use distinct sections designed for async reading followed by live discussion.

## Output Structure

The update is divided into these sections, in order:

### 1. Data & Callouts
Charts, stats, and metric callouts worth reviewing async. Include a link to the Growth Eng WBR Hex dashboard. Add any specific metric callouts as bullets.

### 2. Changelog
One line per item shipped to prod. Keep it tight — just what landed. No sub-bullets needed unless there's a critical detail.

### 3. Notes
Interesting work, findings, or FYIs worth sharing during silent reading time. This section can be more verbose than the changelog. Sub-bullets for supporting details, context, links. This is where in-progress work, investigations, discoveries, and upcoming plans go.

### 4. Discussion Topics
Topics to discuss live with the team. Reference back to a Notes item if relevant. State the issue clearly — the team will discuss and solve together. List specific questions or sub-points as sub-bullets.

### 5. Blockers
Things actively stuck that need the team. Leave empty with placeholder if nothing is blocked.

## Name Prefix Convention

**Every top-level bullet in every section** (except Data & Callouts) must start with a bold name tag:

```
- **[Sean]:** the content here
```

The `**[Sean]:**` prefix is bolded (the square brackets, name, and colon — all bold). This applies to:
- Every Changelog item
- Every Notes item (top-level only, not sub-bullets)
- Every Discussion Topics item (top-level only)
- Every Blockers item

Sub-bullets under a top-level item do NOT get the name prefix.

## Output Style

**Tone**: Casual, direct, first-person implied (no "I" needed). Reads like a smart teammate talking, not a status report.

**Bullet length**: Changelog items are one line. Notes items can be longer with sub-bullets for supporting details, links, or context.

**Language patterns**:
- lowercase everything except proper nouns, product names, acronyms
- em-dash or colon to introduce sub-topics within a bullet
- parenthetical asides for brief context: `(h/t Marc for the data)`, `(just needs marketing signoff)`
- numbers and percentages included when meaningful: `+3.5pp`, `~25.3%`, `~37k users`
- present progressive for ongoing work: "looking into", "monitoring", "aiming to ship"
- past tense for completed work: "shipped", "wrapped up", "confirmed"
- hedged language where appropriate: "looks like", "still unclear", "recommending we"

**What to preserve**:
- all raw URLs exactly as provided — never remove a link, never wrap in markdown `[title](url)` format, just introduce it naturally and paste the raw URL
- specific stats, metrics, and numbers

**What to cut**:
- filler phrases ("I was working on", "spent time on", "made progress on")
- redundant context that's obvious from the bullet topic
- internal monologue or uncertainty that doesn't add value to teammates

## Sorting items into sections

- **Changelog**: anything that shipped/merged to production this week. One line each, minimal context.
- **Notes**: in-progress work, investigations, findings, upcoming plans, parked items, RFCs, explorations. More detail allowed.
- **Discussion Topics**: anything the user flagged as needing team input, asks, open questions, or decisions. Can reference a Notes item. Questions/sub-points go as sub-bullets.
- **Blockers**: only things actively stuck. Not "parked by choice" — genuinely blocked on someone or something.

If an item has both a shipped component AND a discussion component (e.g., shipped Phase 1 but want to discuss Phase 2 approach), put the status in Notes and the question in Discussion Topics.

## Example Output

```markdown
#### Data & Callouts

*(read async before / during silent reading time)*

[Growth Eng WBR — Activation](https://app.hex.tech/supabase/app/Growth-Eng-WBR---activation-032Hy8b68z6aALPSScJZod/latest)

[add chart]

*Callouts:*

-

#### Changelog

*(read async — one line per item shipped to prod)*

- **[Sean]:** auto-RLS experiment: graduated to 100% (+3.3pp lift), experiment code cleaned up https://linear.app/supabase/issue/GROWTH-653/...
- **[Sean]:** Sentry telemetry instrumentation: instrumented the telemetry pipeline, no silent failures found so far, continuing to monitor passively https://linear.app/supabase/issue/GROWTH-674/...
- **[Sean]:** posthog-js bumped from 1.257.2 → 1.357.0 https://github.com/supabase/supabase/pull/43574

#### Notes

*(Interesting work, findings, or FYIs worth sharing — read during silent time)*

- **[Sean]:** cross-app referrer fix (GROWTH-625): deployed Phase 1 — expanded www middleware to /dashboard and /docs, confirmed it works in production with no SPA navigation regressions https://github.com/supabase/supabase/pull/43413
    - while validating Phase 1 data, found the real blocker: a double-encoding bug in the `_sb_first_referrer` cookie serialization — every cookie was silently unparseable (0 out of 1M+ pageviews had it present).
    - fix is up, recovers the full ~25% of unknown-internal attribution: https://github.com/supabase/supabase/pull/43617
    - middleware expansion (Phase 2) adds another ~1.75% on top, shipping after the encoding fix lands
- **[Sean]:** GDPR in-memory attribution: PR ready to move first-touch data to in-memory storage pre-consent — parking it until the unknown-internal referral pipeline fix is in, will pick up after https://github.com/supabase/supabase/pull/43570
- **[Sean]:** CLI telemetry: started socializing PostHog instrumentation for the CLI in `#team-dev-workflows`, working on drafting an RFC
    - what's our privacy/consent approach for CLI telemetry? opt-in vs opt-out, etc.?
    - who are the right contacts on the CLI team to loop in?

#### Discussion Topics

*(Add after reading above — tag with [Name]. State the Issue clearly; we'll Discuss and Solve together)*

- **[Sean]:** CLI Telemetry
    - what's our privacy/consent approach for CLI telemetry? opt-in vs opt-out, etc.?
    - who are the right contacts on the CLI team to loop in?

#### Blockers

*(Things actively stuck that need the team)*

- **[Name]:**
```

## Process

1. Read all the user's notes carefully
2. Group related items — don't create one bullet per raw note if they belong together
3. Sort each item into the correct section (Changelog vs Notes vs Discussion vs Blockers)
4. Identify any URLs and preserve them exactly
5. Apply the `**[Sean]:**` prefix to every top-level bullet (except Data & Callouts)
6. For Discussion Topics, reference back to Notes items where relevant
7. Leave Data & Callouts chart placeholder and Blockers placeholder if nothing to report

## Output Format

Output the full structured document with all section headers, emoji prefixes, and section descriptions. Include all sections even if some are empty (use placeholders). **All section headers must be H4 level (`####`)** — this matches the nesting depth in the Growth Eng Catch-ups Notion doc. Start directly with `#### Data & Callouts`.
