---
name: work-sweep
description: Sweeps across Slack, Linear, Notion, GitHub, Things 3, and personal Gmail to produce a full prioritized inventory of open work, pending follow-ups, and next actions. Use this skill whenever the user wants to get up to speed on everything they have going on — even if they don't use the phrase "work sweep". Trigger on phrases like "what do I have open", "get me up to speed", "what should I work on", "show me everything I'm working on", "I've lost track of my threads", "what are my priorities", "catch me up", "what's on my plate", "end of day check-in", "start of week check-in", or any variant of "what do I need to follow up on". Also trigger if the user asks to look across multiple tools (Slack + Linear, GitHub + Notion, etc.) for a status summary.
---

# Work Sweep

A parallel sweep across six sources — Slack, Linear, Notion, GitHub, Things 3, and personal Gmail — to give you a complete, prioritized picture of everything open in one shot.

## Why this works

Your work is spread across systems that don't talk to each other. A Linear issue might have an open Slack thread, a GitHub PR, and a related Things task. Personal Gmail has commitments that never make it into work tools. This skill gathers all six simultaneously and synthesizes them into a single prioritized view organized by what needs action — not by which tool it came from.

It also bookends the sweep with the user's own framing — a top-of-mind brain-dump up front (Phase 0) and a Things Today reconciliation at the end (Phase 5). The brain-dump becomes a prior the synthesis uses to merge "different cuts at the same big thing" into one entry. The Today reconciliation makes Things the canonical record of the agreed-upon plan, so the sweep's output doesn't evaporate the moment the conversation ends.

## Phase 0: Top-of-Mind Briefing

**Run this before launching the sweep agents.** Skip only if the user explicitly says "just sweep" or has already given a brain-dump in the immediate prior turn.

Ask one open-ended question and stop:

> "Before I sweep — what's top of mind right now? What are you hoping to work on today, or anything weighing on you that we should make sure to capture?"

Wait for the response. Treat it as a free-form brain-dump — do not push for structure or completeness. The user may give one item or fifteen.

For each item the user mentions, capture:
- **Their phrasing** (use their words verbatim — this becomes the merge anchor in Phase 2 and the Things task title in Phase 5 if capture is needed)
- **Type signal** — project (multi-step initiative), task (single action), or concern (worry/open question, not necessarily actionable)
- **Urgency hint** — "today", "this week", "looming", "no rush" — only if the user actually said something about timing

Do NOT ask follow-up questions yet. The sweep will fill in most context. The only exception: if an item is genuinely ambiguous AND would change which tool the sweep agent should focus on (rare), ask one quick clarifier. Otherwise defer questions to Phase 2 synthesis when you have the sweep results in hand.

Acknowledge the brain-dump in one line ("Got it — N items noted. Sweeping now."), then proceed to Phase 1.

**Why this comes first:** The sweep returns dozens of items across six sources. The user's top-of-mind list tells you which sweep items are facets of the same mental project vs genuinely separate concerns. Without this prior, the report fragments one initiative into three entries because they came from three tools.

## Phase 1: Launch All Six Agents in Parallel

Dispatch all six background agents **in a single message** (parallel, not sequential). Announce to the user: "Sweeping across Slack, Linear, Notion, GitHub, Things, and personal Gmail in parallel — this will take 2-3 minutes."

**Model:** Always use `model: "sonnet"` for all agents — never Haiku. These agents make nuanced judgment calls (filtering noise, identifying follow-ups, reading context across threads). Haiku has demonstrated hallucinating PRs that don't exist, missing permalinks entirely, and misapplying filter logic. Sonnet is required, no exceptions.

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

Return a structured summary with these categories (so the synthesis step can route each item to the right output section):
- **Ball in user's court** — threads where the user owes a reply, a commitment they made, or an open question directed at them. Include permalink and a one-sentence summary of what's needed.
- **Bookmarked / saved** — pending follow-ups the user flagged. Note how old each one is (recent = action item, weeks old = background reminder).
- **Project context** — open threads in team/project channels that feel like active initiatives, not one-off items. Include permalink and which project it relates to if clear.
- **Stale bookmarks** — saved/bookmarked items older than ~2 weeks that may just need dismissal or a quick nudge.

For every item, include a direct Slack permalink.

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

Return a structured summary with these categories:
- **Active projects** — all active projects the user is involved in (with current status, target dates, any overdue indicators, and Linear project URL). These become top-level project entries in the output.
- **Ball in user's court** — issues assigned to the user in In Progress, Todo, or Triage states. Flag which have high priority, which are overdue, which are blocked.
- **In review** — issues the user has in review state (context that a PR/decision is pending).
- **Recent activity follow-ups** — issues where the user commented but didn't close out; include what the open question or next step appears to be.

For every issue and project, include the Linear URL.

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

Return a structured summary with these categories:
- **Active project docs** — pages that represent ongoing projects/specs/designs the user is driving (with Notion URLs). These feed into the Active Projects section.
- **Open action items** — meeting notes, standup docs, or TODO lists with explicit unresolved action items assigned to or involving the user (with Notion URLs). These feed into Your Move.
- **Background context** — recently edited pages that aren't actionable but are worth surfacing (e.g., a spec someone else is driving, a planning doc for next quarter).

For every item, include the Notion page URL.

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

IMPORTANT: When listing PRs awaiting the user's review, EXCLUDE the following noise from the platform repo:

Filter out a platform repo PR if it meets ANY of these conditions:
1. The author is a bot (renovate[bot], dependabot[bot], github-actions[bot], etc.)
2. The PR title starts with a routine CI/infra prefix: `ci:`, `chore(deps):`, `chore:`, `fix(deps):`, or matches patterns like "Update X to vY.Z" — even if the author is a human
3. The PR appears to be a CODEOWNERS blanket request (requested of many teams, not specifically Growth Eng) with no Growth Eng code in the diff

Examples of PRs to EXCLUDE: "ci: workflow to update supabase-js" (human author, ci: prefix, platform repo = exclude), "chore(deps): bump lodash" (bot author = exclude).

Only include platform repo review requests that are clearly directed at Growth Eng specifically, or that touch code the user actually owns.

Return a structured summary with:
- **Authored PRs** — for each open PR include: title, URL, approval status, reviewer names, summary of most recent comments, any merge conditions, and whether it's ready / blocked / needs action from the author. Flag stale and security PRs.
- **Review requests** — PRs where the user is a pending reviewer (after filtering CODEOWNERS noise). Include URL and urgency indicators.
- **Assigned issues** — open issues assigned to the user, with URLs.

The goal is a complete, actionable picture of every open PR — surface approval state AND comments together so the user knows exactly what needs to happen next for each one.

Use mcp__plugin_github_github__ tools.
```

---

### Agent 5: Things 3

```
Pull everything the user has queued in Things 3. Priority order of lists: Today > Upcoming > Inbox > Someday.

1. Use get_today to pull all tasks scheduled for today (this is the highest priority section).
2. Use get_upcoming to pull all scheduled/upcoming tasks with their due or start dates.
3. Use get_inbox to pull untriaged inbox items.
4. Use get_someday to pull the Someday list for background awareness.

For each task, capture:
- Title
- Notes/description if present (helps synthesize what the task is about)
- Due date or scheduled date if present
- Tags if present
- Project or area it belongs to
- The Things deep link: `things:///show?id=<uuid>` where uuid is the task's id

Return a structured summary with these categories (preserve the list each task came from):
- **Today** — tasks scheduled for today. These go straight into Your Move.
- **Upcoming** — tasks with future dates. These go into Upcoming. Call out any due within the next 3 days.
- **Inbox** — untriaged items. These go into Your Move if they look like active work, or Background Reminders if they've been sitting a while.
- **Someday** — background list. These go into Background Reminders as brief one-liners.

For each task include the `things:///show?id=<uuid>` deep link so the user can jump straight to it in the Things app.

Use mcp__things__ tools.
```

---

### Agent 6: Personal Gmail

```
Search the user's personal Gmail (helloseanoliver@gmail.com) for anything unread or stale in the inbox. This is personal email, not work — adjust the noise filter accordingly.

All google_workspace Gmail tool calls require the `user_google_email` parameter. Always pass `user_google_email: "helloseanoliver@gmail.com"`.

1. Unread in inbox: search `is:unread in:inbox` (page_size ~50). For each unread thread, decide if it's:
   a. Action-required — a human asking a question, a bill/deadline, a personal commitment, something awaiting the user's reply. Include these in "Ball in user's court".
   b. Noise — newsletter, promotional email, automated notification, receipt. Do not surface individually; count them instead (e.g., "~23 unread newsletters and notifications also present").
2. Stale inbox: search `in:inbox older_than:2w`. For each stale thread, check if it's something that was intended to be acted on but got buried. If the subject/snippet suggests it was meaningful (reply from a person, flagged/starred, attached invoice, etc.), surface it as a Background Reminder. Skip obvious newsletters and promotional mail.
3. Starred: search `is:starred`. Include any starred items not already captured above as Background Reminders.

For each surfaced thread, capture:
- Subject
- From (name and email)
- A one-line snippet or summary of what it appears to want
- Approximate age (e.g., "3 days", "2 weeks", "1 month")
- The Gmail web URL returned by the search tool

Return a structured summary with these categories:
- **Ball in user's court** — unread threads from humans that appear to want a reply or action. Each one short: subject, who, what they want, link.
- **Background reminders** — stale inbox items (>2 weeks) that look meaningful but have been sitting. Each one-liner.
- **Starred** — anything starred that isn't already surfaced above.
- **Noise count** — a rough count of unread newsletters/automated mail so the user has a sense of inbox volume without listing each one.

Use mcp__google_workspace__ tools. Always pass `user_google_email: "helloseanoliver@gmail.com"`.
```

---

## Phase 2: Wait, Synthesize, Route

Once all six agents complete, cross-reference their results and route each item into the right output section. The same piece of work often shows up in multiple places (a Linear issue + GitHub PR + Slack thread + Things task). **Group those into a single numbered entry**, not separate entries per source.

### Overlay the top-of-mind list (Phase 0)

Before applying the routing guide, take the brain-dump captured in Phase 0 and use it as the spine of the synthesis:

1. **Match each Phase 0 item to sweep results.** For every brain-dump item, find all sweep items that plausibly relate to it across the six sources (Linear issue, GitHub PR, Slack thread, Things task, Notion doc, Gmail thread). Group them under the user's framing — use the user's phrasing as the entry title. This is how "different cuts at the same big thing" collapse into one numbered entry instead of three.
2. **Elevate priority.** Items the user surfaced in Phase 0 should generally rank higher in the Priority Order — they're signaling these matter today. Don't blindly put them at the top, but use this as a tie-breaker against equally-urgent sweep-only items.
3. **Flag capture candidates.** For each Phase 0 item that has NO matching Things task in the sweep results, mark it as a "needs Things capture" candidate. These get handled in Phase 5. Note: an item may exist in Linear/GitHub/Notion but not Things — that still counts as a capture candidate, since Things is the canonical day plan.
4. **Note unmatched sweep items.** Sweep items that don't relate to anything in Phase 0 still appear in the report — the user can't have everything top-of-mind. They just don't get the elevation bump.

### Routing guide

Use the agent's category hints, but exercise judgment where items overlap:

- **Active Projects** ← Linear active projects, Notion active project docs, any multi-thread initiative with work spread across sources. If you see three items from three sources that are clearly the same project, merge them.
- **Your Move** ← Slack "ball in user's court", Linear assigned + In Progress / Todo / Triage, Notion open action items, Things 3 Today, Things 3 Inbox items that look active, Gmail "ball in user's court".
- **PRs Awaiting Your Review** ← GitHub review requests only.
- **Upcoming** ← Things 3 Upcoming, any near-term deadlines (<1 week) from other sources, scheduled items.
- **Background Reminders** ← Things 3 Someday, Gmail stale inbox + starred, Slack stale bookmarks, Notion background context. One-liners — not full entries.

### Filtering dismissed items

Before producing the report, read the dismissed items file at:
`~/.claude/projects/-Users-seanoliver-supabase/memory/work-sweep-dismissed.md`

For each candidate item in the report, check if any of its URLs match a URL in the dismissed list. If so, **silently drop it** — do not include it in the output or mention that it was filtered. At the end of the report (after the Priority Order section), add a single line noting how many items were filtered, e.g.: *"(3 previously dismissed items filtered out)"* — only if the count is > 0.

## Phase 3: Output Format

Produce the report in this structure. **Every item must include at least one link** — GitHub URL, Linear URL, Slack permalink, Notion URL, Things deep link, or Gmail web URL. The report should be immediately actionable: the user reads it and clicks directly into the thing that needs attention.

### Item numbering

**Every item across all sections gets a sequential number: `[1]`, `[2]`, `[3]`, etc.** Numbering is continuous across all five sections (Active Projects, Your Move, PRs Awaiting Your Review, Upcoming, Background Reminders). The Priority Order section references these same numbers rather than assigning new ones.

---

### Active Projects

Named multi-step initiatives with work spread across multiple sources. For each project, provide: name, what it is (1 sentence), current status, **Next action** (specific, concrete, one sentence), and all relevant links grouped together.

Example format:
> **[1] Cross-App Attribution Fix** — Recovering ~25% of users misattributed as "unknown-internal". Phase 1 PR is open waiting on Ivan.
> **Next:** Coordinate with Ivan to merge [#43413](https://github.com/supabase/supabase/pull/43413) then monitor for 24h.
> Links: [GROWTH-668](https://linear.app/...) · [PR #43413](https://github.com/...) · [Slack thread](https://...)

---

### Your Move

Everything where the ball is in the user's court — tasks to do, questions to answer, commitments to complete, decisions to make. Pulls from Things Today, Linear assigned, Slack replies needed, Gmail replies needed, and Notion action items. Each item is one line: what it is, where it's from (icon or short tag), link.

Example format:
> **[2] Reply to Ivan re: attribution phase 2 timing** — Slack DM, 2 days old. He needs an answer before Friday. [[thread]](https://...)
> **[3] Draft PostHog renewal response** — Things Today. Deadline April 3. [[task]](things:///show?id=...)
> **[4] Bill from Con Edison** — Gmail unread, 4 days old. Due April 30. [[email]](https://mail.google.com/...)

---

### PRs Awaiting Your Review

A table with direct links: `[#NNNNN Title](url)` | Repo | Notes (e.g., "security CVE", "active discussion", "stale 3 weeks")

---

### Upcoming

Things Upcoming list, near-term deadlines from any source, scheduled items. Call out anything due within the next 3 days explicitly. One line per item: what it is, when it's due, link.

Example format:
> **[10] Q2 planning doc sync** — Wednesday, from Things Upcoming. [[task]](things:///show?id=...)
> **[11] PostHog renewal decision deadline** — April 3, tracked in Linear. [[GROWTH-714]](https://linear.app/...)

---

### Background Reminders

Things Someday, stale Gmail inbox (>2 weeks), starred items, dusty Slack bookmarks, Notion background context. These aren't actionable today — they're here so nothing rots. One terse line each. End with inbox-volume counts (e.g., "~23 unread newsletters in personal Gmail").

Example format:
> **[15] Someday: migrate Cortex to Obsidian Sync** — [[task]](things:///show?id=...)
> **[16] Stale: "Your kraken order has shipped" (5 weeks)** — [[email]](https://mail.google.com/...)
> **[17] Bookmark: Anthropic prompt caching docs (3 weeks old)** — [[slack]](https://...)
>
> *Inbox volume: ~23 unread newsletters/automated mail in personal Gmail.*

---

### Priority Order

A numbered list combining everything above — Active Projects, Your Move, PRs, Upcoming, Background Reminders — ranked by urgency/impact. Each entry is one line with the item number, name, and its primary link. Be direct about what deserves attention first and why.

Example format:
> 1. **[1] Cross-App Attribution Fix** — ship this today, Ivan waiting
> 2. **[2] Reply to Ivan** — blocker for #1
> 3. **[11] PostHog renewal** — deadline in 10 days, don't let it slip

---

## Phase 4: Post-Sweep Dismissals

After presenting the report, tell the user:

> You can dismiss items by saying **"cut 1, 3, 5"** (with optional reasons like "cut 3 — shipped last week"). Dismissed items won't appear in future sweeps. When you're done pruning, say **"lock it in"** and I'll capture brain-dump items and reconcile your Things Today list.

When the user dismisses items:

1. Look up the numbered items they referenced.
2. For each item, extract the **primary URL** (the most stable identifier). Preference order:
   Linear issue URL > GitHub PR URL > Notion page URL > Things deep link > Gmail web URL > Slack permalink.
3. Append each to the dismissed items file at `~/.claude/projects/-Users-seanoliver-supabase/memory/work-sweep-dismissed.md` using the format:
   ```
   - YYYY-MM-DD | <primary URL> | "<short label>" | <reason if provided>
   ```
4. Confirm what was dismissed: "Dismissed [1] Cross-App Attribution Fix, [3] Legacy auth PR, [5] Slack thread with Ivan. These won't appear in future sweeps."

The user may dismiss items across multiple messages. Keep the numbered references stable for the duration of the conversation — don't renumber after dismissals.

## Phase 5: Capture & Reconcile Things Today

**Run this only after the user says "lock it in" (or equivalent: "let's lock the day", "looks good", "make it so", "schedule it", etc.).** Don't run it automatically — the user needs a chance to dismiss items first.

This phase makes Things Today the canonical record of the day's plan. Two steps: capture missing items, then reconcile Today.

### Step 1: Capture brain-dump items into Things

Take the "needs Things capture" candidates flagged in Phase 2 (Phase 0 brain-dump items with no matching Things task). Present them as a single batch:

> I noticed N items from your brain-dump that aren't in Things yet:
> - [a] "Draft posthog renewal response" — mentioned with deadline pressure
> - [b] "Look at MCP attribution gap" — surfaced as a concern
> - [c] "Ping Ivan re: phase 2" — follow-up, no Things task
>
> Want me to add all of these? Or pick specific ones (e.g. "add a and c").

For each confirmed item, use `mcp__things__add_todo` with:
- **title** — the user's phrasing from Phase 0
- **notes** — any context the sweep surfaced (related Linear/GitHub/Notion links go here so the task carries the source thread)
- **when** — `"today"` if it's part of the day's priority list, otherwise omit (lands in Inbox) so the user can triage later. Accepted values: `today`, `tomorrow`, `evening`, `anytime`, `someday`, or `YYYY-MM-DD`.
- **list** / **list_id** — only if the task obviously belongs to an existing project or area (this is the project/area name, NOT the scheduling bucket — don't confuse with `when`)
- **tags** — only if obvious from context

**Don't duplicate.** If an item arguably matches an existing Things task that you missed in Phase 2, ask before creating: "There's already a task 'X' in your Inbox — is that the same thing or different?"

### Step 2: Reconcile Things Today

The final agreed-upon priority list (after dismissals) IS the day's plan. Now make Things Today match it.

Pull current Things Today (the data is already in scope from the Phase 1 Things agent — re-fetch only if dismissals or captures changed things substantively).

Build three buckets:

| Bucket | Action |
|---|---|
| **Priority items already on Today** | Leave alone — already correct. |
| **Priority items NOT yet on Today** (have Things task elsewhere — Inbox, Upcoming, Someday, or just-captured in Step 1) | Use `mcp__things__update_todo` with `when: "today"` to schedule for today. |
| **Currently on Today but NOT in priority list** | Ask the user: "Today has these tasks that didn't make the priority list: [titles]. Defer to Anytime, keep on Today, push to a specific date, or move to Someday?" Default suggestion: `when: "anytime"` (clears today's date, leaves task accessible in the Anytime list) unless the user said otherwise. |

**Edge case — priority items with no Things task at all** (e.g., a Slack reply, a GitHub PR review): offer to create a stub Things task pointing to the source URL, scheduled for Today. This is optional — the user may prefer to act on those directly without creating overhead. Ask: "Want stub Things tasks for [N] of these so they're on Today, or are you good acting on the links directly?"

### Step 3: Confirm

End with a concrete summary:

> Things Today now has N tasks:
> 1. [title] — [primary source link]
> 2. [title] — [primary source link]
> ...
>
> Deferred from Today: [titles, if any].
> Captured to Inbox: [titles, if any].
>
> You're set for the day.

This is the loop closure: brain-dump → captured → Today list = canonical plan. The conversation can end here and the day's plan persists in Things, not buried in chat history.

## Tone

Be concrete and specific, not vague. Instead of "check on PR #43413", say "coordinate with Ivan to merge #43413 — it's been open since March 4 and is blocking Phase 2." The user is trying to orient quickly after being heads-down; every item should be immediately actionable.
