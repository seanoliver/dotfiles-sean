---
name: weekly-update-interviewer
description: Conducts an interview to pull out details for a weekly growth engineering update. Use this skill when the user gives a rough list of topics, areas, or project names they've been working on and wants help fleshing them out into a full update — even if they don't say "interview". Trigger on phrases like "interview me about my week", "help me remember what I did", "I worked on X and Y this week", "ask me about my update", "jog my memory", or when the user provides a loose bullet list of work areas without details. After the interview, automatically format the collected answers using the weekly-update-formatter skill to produce finished bullets.
argument-hint: [rough list of topics you worked on]
allowed-tools: mcp__claude_ai_Linear_2__list_issues, mcp__claude_ai_Linear_2__get_issue, mcp__claude_ai_Linear_2__search_documentation, mcp__claude_ai_Linear_2__list_comments, mcp__claude_ai_Slack__slack_search_public_and_private, mcp__claude_ai_Slack__slack_read_channel, mcp__claude_ai_Slack__slack_read_thread, mcp__plugin_github_github__search_pull_requests, mcp__plugin_github_github__list_commits, mcp__notion__notion-search, mcp__claude_ai_Notion__notion-search, mcp__claude_ai_Hex__search_projects, AskUserQuestion, Skill
---

# Weekly Update Interviewer

Conducts a focused, conversational interview to extract the details needed for a polished weekly update. The user gives you a rough list of topics — you ask smart follow-up questions one topic at a time, then feed everything into the weekly-update-formatter.

## Phase 1: Research Before the Interview

Before asking any questions, silently pull context from **all available sources** to:
1. Get details on topics the user mentioned
2. Surface things they *didn't* mention that might deserve an update

Run these searches **in parallel** to save time:

**Linear:** Search for issues assigned to the user updated in the last 7 days. Look for: recently updated issues, comments, status changes, new issues created.
- Use `mcp__claude_ai_Linear_2__list_issues` filtering for the user's issues updated recently
- Also search for issues the user commented on or created recently

**Slack:** Search for messages sent by the user in the last 7 days.
- Use `mcp__claude_ai_Slack__slack_search_public_and_private` with `from:me after:<7-days-ago>`
- Look for threads they started, substantive replies, anything that sounds like work updates
- Focus on channels like #team-growth-eng, #growth-eng

**GitHub:** Search for PRs the user authored or reviewed in the last 7 days.
- Use `mcp__plugin_github_github__search_pull_requests` with query `author:seanoliver created:>YYYY-MM-DD` across relevant repos (supabase/supabase, supabase/platform)
- Also search for PRs reviewed: `reviewed-by:seanoliver created:>YYYY-MM-DD`
- Look for: PRs opened, merged, reviewed, or with active discussion

**Notion:** Search for docs the user created or updated recently.
- Use `mcp__notion__notion-search` (or `mcp__claude_ai_Notion__notion-search`) with queries related to the user's known project areas
- Look for: specs, RFCs, meeting notes, design docs updated in the last 7 days
- Filter by creation date when possible using `filters.created_date_range`

**Hex:** Search for dashboards or notebooks the user may have worked on.
- Use `mcp__claude_ai_Hex__search_projects` with queries related to the user's known project areas (e.g. "attribution", "growth", "activation")
- Look for: recently created or updated analysis notebooks, dashboards shared in Slack threads

**After researching**, compare what you found across all sources against the user's topic list. Identify:
- Topics the user mentioned → gather context to ask smarter questions about them
- Things you found that weren't mentioned → flag these as "I also noticed X — worth including?"

Then say something like: *"Great, let's go through these one at a time. I also pulled your recent activity from Linear, Slack, GitHub, Notion, and Hex — spotted a couple things you didn't mention, and I'll ask about those too."*

## Phase 2: Receive the Topic List + Surface Gaps

The user gives you their rough list. You've already done your research — now mention anything you found across Linear, Slack, GitHub, Notion, or Hex that's *not* on their list and ask if they want to include it. Keep it brief: *"I also noticed [X] in [source] — want to include that?"*

## Phase 3: Interview — One Topic at a Time

For each topic, ask 2–4 targeted questions in a single message. Don't ask one question at a time — batch the questions per topic so the user can answer them all at once before you move on.

**Always probe for:**
- Current status: shipped, in-progress, blocked, or upcoming?
- The most important detail or result (metric, decision, outcome)
- Any relevant links: PR, Linear issue, Hex dashboard, Notion doc, Slack thread — ask specifically for these
- Any handoffs, collaborators, or shoutouts worth mentioning
- Any blockers, asks, or things waiting on someone else

**Good question patterns:**
- "What's the latest on [topic]? Where does it stand?"
- "Any numbers or results worth sharing — lift, adoption rate, user count?"
- "Do you have a link for this? PR, Linear issue, dashboard?"
- "Anything blocked or waiting on someone?"
- "Anyone to give credit to on this one?"

**Tone:** Conversational, efficient, like a smart colleague asking "so what's the deal with X?" — not a formal survey. Keep questions short and casual.

**After each topic:** Briefly confirm what you captured in 1–2 lines, then move to the next topic. Example: *"Got it — RLS experiment at +3.5pp, recommending ship. Moving on to the outage follow-up..."*

## Phase 4: Wrap Up

Once all topics are covered, say something like: *"Okay, I think I've got everything. Let me turn this into your update."*

Then invoke the weekly-update-formatter skill via `Skill` tool to produce the final polished bullets — no name header, just the bullets, all links preserved raw.
