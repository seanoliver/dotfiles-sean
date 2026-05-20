---
name: daily-update
description: Use when the user wants to generate a daily HTML status report of their own recent work activity (rolling 7-day window) across Linear, GitHub, Slack, Notion, PostHog, Things 3, and local docs. Trigger on phrases like "daily update", "generate today's update", "morning standup", "what have I done this week", "daily report", "what did I ship", "rundown of my week".
---

# Daily Update

Single-page HTML report of Sean Oliver's work activity over the last 7 days, pulling from 7 data sources in parallel and synthesizing into a dark-themed dashboard modeled on Marc Stone's weekly team report.

## Out of Scope

This skill does NOT:

- Generate updates for anyone other than Sean (use Marc's weekly-status prompt for team reports).
- Cover Personal or Indie Hacking work — only Supabase-area activity.
- Schedule itself — pair with `/schedule` for automated daily runs.
- Edit, follow up on, or act on the items it surfaces — this is a read-only report.
- Backfill more than 7 days; the window is fixed.
- Push the report anywhere (Slack, Notion, Linear) — output is local HTML only.

## Identity Constants

Use these verbatim; do not look them up at runtime.

| Field | Value |
|-------|-------|
| Name | Sean Oliver |
| Role | Growth Engineer |
| Team | Growth Eng |
| GitHub handle | `seanoliver` |
| Email | `sean.oliver@supabase.io` |
| Slack user ID | `U094379BQLB` |
| Slack subteam (Growth Eng) | `S054BE00M8F` |
| Linear team UUID (Growth Eng) | `a2feb365-231c-4bd2-9be7-b40217f8ad33` |
| Things 3 Supabase area UUID | `GguAn2gpEuEbSCi59RhJ4W` |

## Phase 1: Compute Window

Work in Pacific Time. Compute:

- `TODAY` — invocation date as `YYYY-MM-DD` (e.g., `2026-05-20`).
- `WINDOW_START` — `TODAY` minus 7 days (e.g., `2026-05-13`).
- `YESTERDAY` — `TODAY` minus 1 day.
- `GENERATED_AT` — current timestamp, formatted `YYYY-MM-DD HH:MM PT`.

Then:

```bash
mkdir -p ~/Documents/daily-updates
```

Check if `~/Documents/daily-updates/daily-update-${YESTERDAY}.html` exists. If yes, capture the filename for the footer "Yesterday's report" link.

## Phase 2: Parallel Intelligence

Dispatch seven subagents in a SINGLE message to maximize parallelism. Each agent uses `subagent_type: general-purpose` and `model: sonnet`. Haiku is appealing on cost but several sources (PostHog, Slack ranking, Things filtering) need light reasoning + iterative tool loading via ToolSearch — Sonnet is the reliable default. Downgrade individual agents to Haiku only after they're observed to work consistently.

**REQUIRED PATTERN:** Follow `dispatching-parallel-agents` — all seven Agent calls in one tool-use block.

Each subagent receives a prompt of the form:

> Pull Sean Oliver's activity from {SOURCE} between {WINDOW_START} and {TODAY} (Pacific Time). Return ONLY a JSON object matching the "Subagent Output Format" below. Do NOT write narrative. Use MCP tools directly. If the source has no activity in the window, return the schema with empty arrays and `summary: "No activity in window"`. If the source errors out, return the schema with `error: "<message>"` populated and other fields empty.

### Per-source instructions

**1. Linear** — Use `mcp__claude_ai_Linear__list_issues` with filter on team `a2feb365-231c-4bd2-9be7-b40217f8ad33` and assignee containing "Sean Oliver", updated since `{WINDOW_START}`. For each issue capture: `identifier` (e.g., GROWTH-123), `title`, `state.name`, `state.type`, `project.name`, `url`, `updatedAt`, AND `description` (first sentence of the issue body, max 120 chars, or empty string if no body). Issues with `state.type = completed` go to `shipped`; others to `in_progress`. Issues untouched for 5+ days but still open go to `flags` with context "stalled".

**2. GitHub** — Use `mcp__plugin_github_github__search_pull_requests` twice:
  - `is:pr author:seanoliver org:supabase updated:>={WINDOW_START}` → authored PRs
  - `is:pr reviewed-by:seanoliver org:supabase updated:>={WINDOW_START}` → reviewed PRs
  
  Authored merged PRs → `shipped`. Authored open PRs → `in_progress` (skip drafts older than 5 days; flag those). Reviewed PRs → `discussions` (collaboration signal). Capture: `repo`, `number`, `title`, `state`, `merged_at`/`updated_at`, `html_url`, AND `description` (first sentence of PR body, max 120 chars; for reviewed PRs this is usually unnecessary — leave empty if the title is self-explanatory).

**3. Slack** — Use `mcp__claude_ai_Slack__slack_search_public` with query `from:<@U094379BQLB> after:{WINDOW_START}`. Then a second search: `<@U094379BQLB> after:{WINDOW_START}` (where Sean was mentioned). Rank threads by reply count + decision-weight signals (words like "decision", "ship", "block", "RFC", "?"). Top 3-5 go to `discussions`. Capture: `channel`, `one_line_summary`, `reply_count`, `permalink`. If rate-limited (429), put a single item in `flags` with text "Slack rate-limited" and do NOT retry.

**4. Notion** — Use `mcp__claude_ai_Notion__notion-search` with query "Sean Oliver" filtered to pages edited after `{WINDOW_START}`. Pages Sean created or edited in the window. Recently-published pages → `shipped`. Draft/in-progress pages → `in_progress`. Capture: `title`, `url`, `last_edited_time`, `brief` (first sentence of summary).

**5. PostHog** — Use `mcp__posthog__exec` to query for experiments and feature flags Sean created or modified in the window. Filter the experiment + feature flag lists by `created_by.email = sean.oliver@supabase.io` OR `updated_at >= {WINDOW_START}` with `created_by.email = sean.oliver@supabase.io`. Experiments transitioning to "running" state in window → `launched`. Feature flags rolled to 100% in window → `launched`. New draft experiments → `in_progress`. Capture: `name`, `type` (experiment/flag/insight), `status`, URL. If query returns 0, double-check by listing recent items and filtering client-side before declaring empty.

**6. Things 3** — Use `mcp__things__get_logbook` to fetch completed tasks. Client-side filter to `area = "GguAn2gpEuEbSCi59RhJ4W"` (Supabase area only — explicitly exclude Personal `2kxr1cEK38g34vUrxTUEVx` and Indie Hacking `8e4tgjvV8zVLRurmBdXqnn`) AND `completion_date >= {WINDOW_START}`. All matched items → `shipped` (personal-tracking work that may not have a PR). Capture: `title`, `completed_at`, `project` (if any), `tags`.

**7. Local docs** — Run the following bash via the agent:

```bash
find ~/supabase/docs/bugs ~/supabase/docs/investigations -type f -name "*.md" -newermt "{WINDOW_START}" 2>/dev/null | grep -v TEMPLATE
```

For each file, read the first `# ` heading (title) and the `Repo` line if present. Bug journal entries → `flags` (recurring issue signal). Investigation entries → `shipped` (knowledge artifact). Capture: `file_path`, `title`, `type` (bug/investigation), `mtime`.

### Subagent Output Format

Each subagent MUST return RAW JSON only. The FIRST character of the response must be `{`. No prose before, no prose after, no markdown code fences. Do not narrate your classification reasoning — apply rules silently and emit JSON.

**Wrong** (will break synthesis):
```
Now I have the data. Let me classify...
{"source": "linear", ...}
```

**Right** (parseable):
```
{"source": "linear", ...}
```

Schema:

```json
{
  "source": "linear|github|slack|notion|posthog|things|docs",
  "summary": "<one-line headline, max 100 chars>",
  "shipped": [{"headline": "...", "title": "...", "url": "...", "description": "...", "context": "...", "timestamp": "..."}],
  "in_progress": [{"headline": "...", "title": "...", "url": "...", "description": "...", "context": "...", "timestamp": "..."}],
  "launched": [{"headline": "...", "title": "...", "url": "...", "description": "...", "context": "...", "timestamp": "..."}],
  "discussions": [{"headline": "...", "title": "...", "url": "...", "description": "...", "context": "...", "timestamp": "..."}],
  "flags": [{"headline": "...", "title": "...", "url": "...", "description": "...", "context": "...", "timestamp": "..."}],
  "error": null
}
```

Not every source fills every array — that's fine; leave irrelevant ones empty.

**Exclusivity rule:** an item MUST appear in at most ONE section per source payload. `flags` is reserved for problems, risks, and unfinished items only — never as a cross-reference to a launched/shipped success. If a thing both shipped and has a follow-up concern, put it in `shipped` and write a SEPARATE flag item describing the concern, not the same row duplicated. The Slack rate-limit and subagent-error cases are the only exception (those are by definition flag-only).

**Headline field (REQUIRED for every item):** `headline` is a 5–10 word natural-language summary of what the item is or what it does, written for a human skim — NOT the raw PR title, Linear title, or filename. Drop ticket numbers, drop conventional-commit prefixes (`fix:`, `feat:`, `refactor:`), drop scope tags (`(telemetry)`), drop project codes. Strip jargon when possible without losing meaning.

Examples:
- title: `"fix(telemetry): pass org_count and signup_timestamp in flag personProperties"` → headline: `"Wire org_count + signup_timestamp into flag audiences"`
- title: `"GROWTH-853 · Set up 5% rollout of new-default-grants experiment for brand-new dashboard signups"` → headline: `"Activate default-grants experiment at 5% rollout"`
- title: `"Default-grants experiment bucketing at 1.2% instead of 5%"` → headline: `"Default-grants bucketed at 1.2%, not 5%"` (already concise; light rewrite acceptable)
- Things task title `"Send Austin corrected Usercentrics numbers + PostHog projection (Vertice negotiation)"` → headline: same as title (already natural language; pass through unchanged).

For Things tasks and other items where the title is already a natural-language sentence, `headline` MAY equal `title` verbatim. For PR/Linear/insight items with technical prefixes, the headline MUST be a rewrite.

## Phase 3: Synthesize HTML

Merge all seven payloads into a single HTML file using the styling below. The visual language mirrors Marc's weekly report so cross-report familiarity holds.

### Theme tokens (use exactly)

```css
:root {
  --bg: #0f1117;
  --surface: #1a1d27;
  --surface-hover: #232734;
  --border: #2a2e3a;
  --accent: #6366f1;
  --text: #e5e7eb;
  --text-muted: #9ca3af;
  --shipped: #10b981;       /* green */
  --in-progress: #06b6d4;   /* cyan */
  --launched: #a855f7;      /* purple */
  --discussions: #6b7280;   /* gray */
  --flags: #f59e0b;         /* amber */
}
```

Font stack: `system-ui, -apple-system, "Segoe UI", Roboto, sans-serif`. Mono fallback for IDs/code: `"SF Mono", Menlo, Consolas, monospace`.

### Document structure

```
<header>
  Daily Update | {TODAY} | Rolling 7 days from {WINDOW_START} | Generated {GENERATED_AT}

<section.exec-summary>           accent-bordered box, bulleted highlights (NOT a paragraph)
<section.velocity-grid>          5 stat tiles
<section.report-section.launched>       h2 + ul, purple left border   ← top
<section.report-section.shipped>        h2 + ul, green left border
<section.report-section.in-progress>    h2 + ul, cyan left border
<section.report-section.flags>          h2 + ul, amber left border
<section.report-section.discussions>    h2 + ul, gray left border    ← bottom
<footer>                         link to yesterday's report (if file exists)
```

**Section order is intentional:** Launched first because it's the most user-visible outcome and the rarest signal — burying it under "Shipped" hides the headline. Shipped + In Progress next because they're the densest action sections. Flags before Discussions because flags want attention (stalled work, bugs), while discussions are passive awareness signal. Discussions live at the bottom.

### Velocity grid tiles

5 tiles, in order:

1. **PRs Merged** — count from GitHub `shipped`
2. **Linear Closed** — count from Linear `shipped`
3. **Experiments Launched** — count from PostHog `launched`
4. **Things Completed** — count from Things `shipped`
5. **Repos Touched** — distinct count of `repo` across all GitHub items

Each tile: large number + small caption. Tile bg is `--surface`, number color is `--accent`.

### Section item rendering

Each item is a `<li>` with up to three text rows:

1. **Title** (linked to `url` if present) + **source tag** pill (LINEAR / GITHUB / SLACK / NOTION / POSTHOG / THINGS / DOCS, colored to match section accent).
2. **Description** (optional) — one-line explanation of WHAT the item is or what changed, drawn from the `description` field on the source payload. Render in `--text-muted` at 13px. **Omit the row entirely when no description is present** (do not render an empty div). Self-explanatory items — most Things tasks, most reviewed PRs whose title says everything — should have NO description row.
3. **Context line** (smaller, 12px, more muted): `{timestamp 'May 15'}{ · project/repo}{ · state}`.

Items that ARE worth a description row: PRs (pull from PR body first sentence), Linear issues (pull from issue description), Slack threads (pull from `one_line_summary`), investigations and bug journal entries (pull from "Symptom" / "Context" first sentence), PostHog experiments (pull from hypothesis if available).

### Cross-source deduplication

The same underlying piece of work often appears in multiple source payloads — a single shipment shows up as a Linear issue, a merged GitHub PR, AND a completed Things task. Before rendering, collapse these into ONE item with multiple source pills.

**Dedup signals (any one match → collapse):**
- A Linear identifier like `GROWTH-123` appearing in a GitHub PR title or Things task title.
- A GitHub PR number or URL appearing in a Things task title or Linear issue body.
- Two titles with >70% word overlap referencing the same date and the same outcome (e.g. "Ship 5% rollout" Things task + "GROWTH-853 · Set up 5% rollout" Linear issue).

**Collapse rule:** keep the most informative title (usually the Linear or GitHub one — it has the formal identifier), then render all matched source pills inline (`<span class="pill linear">LINEAR</span> <span class="pill github">GITHUB</span> <span class="pill things">THINGS</span>`). Use the earliest timestamp of the group.

**Do NOT dedup across different work items just because they share a project tag** — only merge when the items are clearly the same underlying ship.

### Empty-section behavior

If a section has zero items, render `<p class="empty">No activity in this window.</p>` inside the section. Do NOT omit the section — consistency makes day-over-day diffs scannable.

### Executive summary box

Render as a SHORT bulleted list (3-5 bullets), NOT a dense paragraph. Each bullet is one tight line. Group related items into a single bullet — don't list every PR.

Priority order for bullets:

1. Biggest launch or shipping theme of the window (group related PRs/issues into one bullet, name the user-visible outcome)
2. Other notable shipped work
3. Notable in-progress work that's blocking or about to land
4. Any stalled work or new bugs worth a triage pass

Voice: terse, plain, declarative. No "let's", "great", "awesome", "amazing", "exciting", "we crushed it." Read like a senior eng's slack note to themselves.

### Footer

If `~/Documents/daily-updates/daily-update-${YESTERDAY}.html` exists, append:

```html
<footer><a href="daily-update-{YESTERDAY}.html">← Yesterday's report</a></footer>
```

Otherwise omit the footer entirely.

### Read-first check

Before generating the HTML, if yesterday's report exists, peek at its `<section.exec-summary>` text. This lets the new exec summary acknowledge continuity ("Following yesterday's X push, today's headline is Y") rather than reading like a cold-start every day.

## Phase 4: Save + Open

```bash
OUT="$HOME/Documents/daily-updates/daily-update-$(date +%Y-%m-%d).html"
# write the HTML via Write tool, then:
open "$OUT"
```

**Same-day idempotency (REQUIRED):** the filename is keyed to TODAY's date alone. Running the skill multiple times in a single day OVERWRITES the existing file with the latest synthesis. Do NOT append a timestamp, run-counter, or any uniqueness token to the filename — repeated same-day runs are intentional refreshes, not new artifacts. The `open` call re-focuses the browser tab; the user sees the latest data in place.

Print this terminal one-liner (replace placeholders with actual counts):

```
Daily update saved → ~/Documents/daily-updates/daily-update-{TODAY}.html
{N} shipped · {N} in progress · {N} launched · {N} discussions · {N} flags
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Querying Linear with team name instead of UUID | Pass `a2feb365-231c-4bd2-9be7-b40217f8ad33` directly. MCP rejects non-UUID team values despite docs claiming otherwise. |
| Slack rate-limit retry loop | If a Slack search 429s, surface one item in `flags` and stop. Don't retry. |
| Including Personal/Indie tasks | Things 3 filter MUST be `area = GguAn2gpEuEbSCi59RhJ4W`. Other areas are out of scope. |
| Reporting timestamps in UTC | All rendered times must be Pacific. Convert at format time, not query time. |
| Empty PostHog results unchecked | If PostHog returns 0, retry with a broader list-then-filter approach before declaring empty. |
| Subagent failures rendered as silence | A failed subagent must surface as `⚠️ {source} subagent failed: {error}` in the Flags section. |
| Omitting empty sections | Always render the section with an empty-state placeholder. Skipping sections breaks day-over-day visual diff. |
| Substituting Sean's name when copying Marc's prompt structure | Sean is the subject, not a teammate. There are no per-person cards — only one subject card (Sean's). |

## Verification

After generating, before declaring complete:

1. `ls -la ~/Documents/daily-updates/daily-update-${TODAY}.html` — file exists and is non-empty.
2. Open the file — every section has either items or "No activity" placeholder.
3. Velocity tiles total > 0. If everything is zero, at least one subagent failed silently — investigate.
4. Section accent colors match theme tokens (visual check).
5. Yesterday's report link present only if that file exists.
6. Terminal one-liner printed with accurate counts.

## Automation

**This skill cannot be scheduled via `/schedule`.** `/schedule` creates *remote* agents that run in Anthropic's cloud, but this skill depends on three local-only resources:

- **Things 3 MCP** — runs against the local Things database on the Mac; no remote equivalent.
- **`~/supabase/docs/bugs/` + `~/supabase/docs/investigations/`** — local files at the hub root, not in any git repo.
- **`~/Documents/daily-updates/`** — local output destination.

A remote schedule would silently drop Things + local docs and have nowhere to write the HTML. Run this skill manually (`/daily-update` or trigger from a fresh Claude Code session). If you later want hands-off daily delivery, the right pivot is either:

- A separate, stripped-down "remote-daily-update" skill that uses only cloud sources (Linear, GitHub, Slack, Notion, PostHog) and delivers via Notion/Slack/email; OR
- A local launchd job that opens Claude Code with `/daily-update` primed at a fixed time.

Both are net-new work, not a config change on this skill.
