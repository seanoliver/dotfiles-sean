---
name: work-sweep
description: Sweeps across Slack, Linear, Notion, and GitHub to produce a full prioritized inventory of open work, pending follow-ups, and next actions. Use this skill whenever the user wants to get up to speed on everything they have going on — even if they don't use the phrase "work sweep". Trigger on phrases like "what do I have open", "get me up to speed", "what should I work on", "show me everything I'm working on", "I've lost track of my threads", "what are my priorities", "catch me up", "what's on my plate", "end of day check-in", "start of week check-in", or any variant of "what do I need to follow up on". Also trigger if the user asks to look across multiple tools (Slack + Linear, GitHub + Notion, etc.) for a status summary.
---

# Work Sweep

A parallel sweep across all four work platforms to give you a complete, prioritized picture of everything open — in one shot.

## Why this works

The key insight is that your work is spread across four systems that don't talk to each other. A Linear issue might have an open Slack thread and a GitHub PR attached — but you'd have to check three places to know the full picture. This skill gathers all four simultaneously and synthesizes them into a single prioritized view so nothing slips through.

## Phase 1: Launch All Four Agents in Parallel

Dispatch all four background agents **in a single message** (parallel, not sequential). Announce to the user: "Sweeping across Slack, Linear, Notion, and GitHub in parallel — this will take 2-3 minutes."

---

### Agent 1: Slack

```
Search across Slack to find everything the user has open or pending to follow up on.

1. Search for bookmarked/saved messages that appear to be pending follow-ups. Try queries like "is:saved", "is:bookmarked", "has:star". If those don't work, try searching for messages the user recently interacted with.
2. Search for recent threads where the user was mentioned or asked a question but there's no reply from them yet. Try "to:[username]", "mentions:[username]".
3. Search for threads where the user promised to do something or follow up — phrases like "I'll", "I will", "I can", "I'll send", "let me", "I'll follow up".
4. Look for any DMs or threads where someone appears to be waiting on the user.
5. Search #team-growth-eng and similar team channels for any open threads with the user's involvement.
6. Look for any cross-team channels (#project-*, #partner-*) with recent activity involving the user.

Return a structured summary with:
- Bookmarked/saved messages that appear to be pending follow-ups (with permalinks)
- Threads where someone is waiting on the user (with context on what they're waiting for, plus permalink)
- Commitments the user made that don't appear to have been completed yet (with permalink to the relevant thread)
- Any open decisions or questions in project channels (with channel name and permalink)

For every item, include a direct Slack permalink so the user can jump straight to the thread.

Use mcp__claude_ai_Slack__ tools.
```

---

### Agent 2: Linear

```
Pull a comprehensive picture of everything open in Linear for the user.

1. Use list_teams to get all teams.
2. Use list_projects to find all active/in-progress projects the user is involved in.
3. Use list_issues to find all issues assigned to the user — filter by state to get: In Progress, Todo, In Review, Triage.
4. Look for issues with high priority or urgent flags.
5. Look for any issues that appear blocked (check for "blocked" labels or comments).
6. Check for overdue issues — any where target date is in the past.
7. Look for issues the user recently commented on but didn't close out.

Return a structured summary with:
- All active projects the user is involved in (with current status, target dates, any overdue indicators, and Linear project URL)
- Issues by status: In Review, In Progress, Todo, Triage — with priority flags and Linear issue URLs
- Blocked or overdue items called out explicitly, with links
- Any issues with recent activity suggesting a follow-up is needed, with links

For every issue and project, include the Linear URL so the user can jump directly to it.

Use mcp__linear-server__ tools.
```

---

### Agent 3: Notion

```
Search Notion to identify everything actively in flight.

1. Use notion-search with an empty query to get recently edited pages.
2. Search for pages containing "TODO", "action items", "next steps", "in progress", "blocked".
3. Search for recent meeting notes or sync docs that may have open action items.
4. Search for any spec or design documents that appear to be in-progress work (not finalized).
5. Look at any team catch-up or standup docs from the last 2 weeks.

Return a structured summary with:
- Recently active pages that appear to represent active projects (with Notion URLs)
- Meeting notes with explicit action items or open questions (with Notion URLs)
- Spec/design docs that suggest active work in progress (with Notion URLs)
- Any pages with TODOs or "next steps" sections that look unresolved (with Notion URLs)

For every item, include the Notion page URL so the user can jump directly to it.

Use mcp__notion__ tools.
```

---

### Agent 4: GitHub

```
Find everything open on GitHub for the user. Be exhaustive — check every open PR in detail.

1. Use get_me to find the user's GitHub username.
2. Search for open PRs authored by the user in the supabase org only (use "is:open author:[username] org:supabase"). Do not include personal repos or other orgs. Do not filter by draft status initially — include everything.
3. For EACH open PR authored by the user, fetch:
   a. Current review status: approved, changes requested, dismissed, or pending.
   b. The most recent review comments and issue comments — look for conditions on approval, follow-up feedback, formatting/linting requests, or anything the author needs to do before merging.
   c. CI/check status if available.
   d. Whether it's a draft.
4. Search for PRs where the user is a requested reviewer (review-requested:[username]).
5. Search for open issues assigned to the user across the supabase org.
6. Flag any stale PRs (open > 2 weeks) and security-related PRs.

IMPORTANT: When listing PRs awaiting the user's review, EXCLUDE the following noise:
- PRs in the platform repo authored by bots or automated services (renovate[bot], dependabot[bot], github-actions[bot], etc.)
- PRs in the platform repo that are CI/infrastructure updates (package bumps, dependency updates, workflow changes) where the user was tagged only via CODEOWNERS and the PR is requested of many teams, not specifically Growth Eng
- The signal to filter these out: the author is a bot, OR the PR title indicates a routine dependency/CI update (e.g., "chore(deps):", "ci:", "Update X to vY.Z"), AND it's in the platform repo

Only include platform repo review requests that are clearly directed at the user or Growth Eng specifically, or that involve code the user actually owns.

Return a structured summary with:
- Open PRs authored by user — for each PR include:
  - Title and URL
  - Approval status (approved / changes requested / pending / none) and reviewer name(s)
  - Summary of most recent comments and any conditions on merge (e.g., "approved but needs code formatting fixed before merging", "approved pending marketing sign-off", "needs rebase")
  - Whether it's ready to merge, blocked, or needs action from the author
- PRs where the user is a pending reviewer (after filtering out CODEOWNERS noise per above) — include GitHub PR URL and any urgency indicators
- Open issues assigned to the user — include GitHub issue URL
- Stale or blocked PRs worth attention — include GitHub PR URL

The goal is a complete, actionable picture of every open PR — not just a list. Surface the approval state AND the comments together so the user knows exactly what needs to happen next for each one.

Use mcp__plugin_github_github__ tools.
```

---

## Phase 2: Wait, Filter, and Synthesize

Once all four agents complete, cross-reference their results. The same piece of work often shows up in multiple places — a Linear issue might have a GitHub PR and a Slack thread. Where you see these connections, group them together rather than listing them separately.

### Filtering dismissed items

Before producing the report, read the dismissed items file at:
`~/.claude/projects/-Users-seanoliver-supabase/memory/work-sweep-dismissed.md`

For each candidate item in the report, check if any of its URLs match a URL in the dismissed list. If so, **silently drop it** — do not include it in the output or mention that it was filtered. At the end of the report (after the Priority Order section), add a single line noting how many items were filtered, e.g.: *"(3 previously dismissed items filtered out)"* — only if the count is > 0.

## Phase 3: Output Format

Produce the report in this structure. **Every item must include at least one link** — a GitHub PR URL, Linear issue URL, Slack permalink, or Notion page URL. The report should be immediately actionable: the user reads it and clicks directly into the thing that needs attention.

### Item numbering

**Every item across all sections gets a sequential number: `[1]`, `[2]`, `[3]`, etc.** The numbering is continuous across sections (Active Projects, PRs Awaiting Your Review, Miscellaneous Follow-Ups). The Priority Order section references these same numbers rather than assigning new ones.

---

### Active Projects

For each project, provide: name, what it is (1 sentence), current status, **Next action** (specific, concrete, one sentence), and all relevant links (e.g., Linear project, GitHub PR, Notion spec, Slack thread — whatever applies).

Example format:
> **Cross-App Attribution Fix** — Recovering ~25% of users misattributed as "unknown-internal". Phase 1 PR is open waiting on Ivan.
> **Next:** Coordinate with Ivan to merge [#43413](https://github.com/supabase/supabase/pull/43413) then monitor for 24h.
> Links: [GROWTH-668](https://linear.app/...) · [PR #43413](https://github.com/...)

---

### PRs Awaiting Your Review

A table with direct links: `[#NNNNN Title](url)` | Repo | Notes (e.g., "security CVE", "active discussion", "stale 3 weeks")

---

### Miscellaneous Follow-Ups

Smaller items that don't belong to a named project: promises made in Slack, DMs with open questions, one-off tasks. Each item includes a link to the relevant Slack thread, Linear ticket, or doc.

---

### Priority Order

A numbered list combining everything above — Active Projects, PRs, and Follow-Ups — ranked by urgency/impact. Each entry is one line with the item name and its primary link. Be direct about what deserves attention first and why.

---

## Phase 4: Post-Sweep Dismissals

After presenting the report, tell the user:

> You can dismiss items by saying **"cut 1, 3, 5"** (with optional reasons like "cut 3 — shipped last week"). Dismissed items won't appear in future sweeps.

When the user dismisses items:

1. Look up the numbered items they referenced
2. For each item, extract the **primary URL** (the most stable identifier — prefer Linear issue URLs > GitHub PR URLs > Notion URLs > Slack permalinks)
3. Append each to the dismissed items file at `~/.claude/projects/-Users-seanoliver-supabase/memory/work-sweep-dismissed.md` using the format:
   ```
   - YYYY-MM-DD | <primary URL> | "<short label>" | <reason if provided>
   ```
4. Confirm what was dismissed: "Dismissed [1] Cross-App Attribution Fix, [3] Legacy auth PR, [5] Slack thread with Ivan. These won't appear in future sweeps."

The user may dismiss items across multiple messages. Keep the numbered references stable for the duration of the conversation — don't renumber after dismissals.

## Tone

Be concrete and specific, not vague. Instead of "check on PR #43413", say "coordinate with Ivan to merge #43413 — it's been open since March 4 and is blocking Phase 2." The user is trying to orient quickly after being heads-down; every item should be immediately actionable.
