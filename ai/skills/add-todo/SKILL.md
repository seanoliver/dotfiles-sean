---
name: add-todo
description: Use when the user says "add a task", "remind me to...", "create a todo", "put this in Things", "things 3 task", or similar Things-capture intent. Also use when the user pastes a bare link or article to save for later, since routing that away from Things is part of this skill's job.
argument-hint: <task description>
allowed-tools: mcp__things__add_todo, mcp__things__get_tags, mcp__things__get_projects, mcp__things__get_areas, mcp__things__get_todos, Bash
---

# Add a Things 3 Task

Capture tasks into Things 3 with rich context, correct routing, and **no encoding bugs**. This skill exists to prevent recurring failure modes: `+`-encoded spaces in titles, wrong-area placement, non-tasks polluting the list, and crowded Today views from unscoped defaults.

**Today is a commitment, not an inbox.** Sean completes a median of 2 substantive tasks per day. Anything this skill puts on Today displaces something he actually planned to do. Capture is cheap; Today is scarce.

## Hard rules (do not skip)

1. **Never schedule to Today unless the user explicitly committed to today.** Default is `anytime`. See Scheduling below. This rule has no "seems urgent" exception — urgency goes in the `deadline` field, not the start date.
2. **A bare link is not a task.** Route it to Readwise Reader instead. See Link routing below.
3. **Every task gets a container** — a project or an area. Never leave a task in Inbox as the final state unless the user is genuinely ambiguous about what it belongs to.
4. **Always discover the user's current areas/projects/tags before creating.** They evolve; never hard-code names.
5. **Never use `quote_plus` or `urlencode`** when building Things URLs. Use `urllib.parse.quote(value, safe='')` per parameter so spaces become `%20`, not `+`. Things treats `+` literally and you get titles like `Submit+PR+review+on+Pam`.
6. **Open the URL from a shell variable**, not by passing it inline to `open`. Some characters (`#`, `&`) trip zsh globbing.
7. **Verify the task landed** before reporting success. Query Things via AppleScript and confirm title + container match what you intended.

## Link routing — is this a task or a thing to read?

Run this check **before** anything else. Getting it wrong is how 28 unread links accumulated in Things over nine months.

| Input | Destination |
|---|---|
| Bare URL, no verb ("check this out", "cool", or nothing) | **Readwise Reader** via `reader_create_document` |
| URL + an action on the content ("read X and summarize for the team") | Things, with the URL in notes |
| URL + an action on a system ("fix the bug in this PR") | Things, with the URL in notes |
| Article, video, blog post, tweet the user wants to consume later | **Readwise Reader** |

When routing to Reader, say so in one line: `→ Reader (not Things — it's a read, not an action).` Do not create a Things task as well.

## Step 1 — Discover current Things 3 structure

Run all three; cache results in conversation context:

```bash
osascript -e 'tell application "Things3" to get name of every area'
osascript -e 'tell application "Things3" to get name of every project whose status is open'
osascript -e 'tell application "Things3" to get name of every tag'
```

Areas and tags include emoji — preserve them exactly when passing back to Things.

## Step 2 — Decide routing

### Container assignment (required — rule 3)

**Always prefer a project over a bare area.** Projects are what make the weekly review tractable; area-only tasks are the ones that go stale unnoticed. Check the discovered project list for a match before falling back to an area.

**Work signals** (any of: Supabase, Growth Eng, a github.com/supabase URL, a Linear ticket ID, Customer.io, PostHog, work-Slack thread URL, named teammates, Hex thread, anything from `~/supabase/`) → a Supabase-area project if one matches (`🤖 Agent-Led Growth`, `📈 Instrumentation`, `🔐 Default Grants`, `🇨🇦 Banff Supafest`), else the **Supabase** area.

**Personal signals** (home, errand, family, personal finance, mom, Tina) → match an open project first (`💰 Finance`, `🏡 41 Westwood`, `❤️ Mom`, `🎿 Skiing`, `🇩🇪 Germany`, `🇨🇳 China`, `🌍 Travel Ideas`, `🔄 Rituals`), else the **Personal** area.

**Indie / side-project signals** (own product names, `~/indie/`, "my side project") → a matching project (`☀️ Solstice`, `🧠 TheraGPT`, `💡 Project Ideas`), else the **Indie Hacking** area.

**Genuinely ambiguous** → Inbox, and say so explicitly in the report so it gets triaged rather than silently lost. "I couldn't tell which area this belongs to" is a valid outcome; guessing wrong is not.

**Never create a new project to hold a single task.** Use the area.

### Scheduling

**Default `when: "anytime"`.** The task lands in its project, visible in Anytime, and gets scheduled later by `/shape` or `/things-review`. This is the correct outcome for the large majority of captures.

Escalate to `today` **only** on an explicit same-day commitment from the user:

| User says | `when` |
|---|---|
| "today", "this morning", "before EOD", "right now" | `today` |
| "tomorrow" | `tomorrow` |
| "this evening" / "tonight" | `evening` |
| a named day or YYYY-MM-DD | that date |
| "next week" | the specific date if given, else `anytime` |
| "someday", "eventually", "if I ever get to it" | `someday` |
| **anything else, including no timing signal at all** | **`anytime`** |

A **deadline** is not a start date. "This is due Friday" sets `deadline: <Friday>` and leaves `when: "anytime"` — the task surfaces in review with its deadline visible, and gets a start date when there's actually room for it.

**Rationalizations that mean you are about to break rule 1:**

| Thought | Reality |
|---|---|
| "This seems urgent, so Today" | Urgency is the `deadline` field. Today is capacity. |
| "It's quick, it won't crowd anything" | Twenty-five "quick" items is the current Today. |
| "He'll want to see this immediately" | He will see it in Anytime at next `/shape`. |
| "It's already late, so it belongs on Today" | Late means it needs a decision in review, not a slot today. |
| "The source (work sweep, ticket) implies today" | Only the user's own words about timing count. |

### Tags

**There are only three tags.** Anything else you remember seeing has been retired. Apply only when explicitly inferable from the user's language; otherwise leave untagged. Untagged is the normal case.

| Signal | Tag |
|---|---|
| "blocked on X" / "waiting for X" / "waiting to hear back" | `🟡 Waiting` |
| "with Tina" / "ask Tina" / "Tina needs to" | `🔵 Tina Required` |
| "most important" / "MIT" / "the one thing" | `🌟 MIT` |

Max 1 tag in practice. **Do not invent priority tags** — no Urgent, no Important, no In Progress, no context tags (Home/Office/Errand/Laptop). Priority is expressed by what `/shape` puts on Today; urgency by the `deadline` field. If the user says "urgent", set a deadline and mention it, don't tag it.

## Step 3 — Notes format (scale to complexity)

**Atomic task** (one verb, one object, no context to carry): one-line note or no note at all.

> Example: "buy birthday card for Mom" — no notes needed.

**Has context** (PR review, follow-up, decision pending, references a URL/file): structured notes.

```markdown
[One-line why-this-matters.]

## Context
- Related to: [PR, ticket, file, person]
- Source: [link or path]

## Details
[Anything specific the future-you needs to act: the draft message, the verdict, the constraint.]

## Resources
- [Description](url)
- `file/path/here.ext`
```

**Heavy context** (debugging session, drafted message ready to paste, multi-step recovery): keep the structure, add a `## Draft` or `## Next Steps` section with the ready-to-execute content.

Never force the template. If a section would be empty, omit it.

## Step 4 — Create the task

**Prefer the Things MCP if available** in the session (`mcp__things__add_todo`). It bypasses URL encoding entirely:

```python
mcp__things__add_todo(
    title="Submit PR review on growth-eng#9 (Pam)",
    notes="...",
    when="today",
    list_title="❇️ Supabase",
    tags=["🟢 Laptop"],
)
```

**Fallback: `things://` URL scheme.** Use this Python helper exactly — the `quote(safe='')` and tempfile-via-variable pattern are both load-bearing:

```bash
python3 <<'PY' > /tmp/things_url.txt
from urllib.parse import quote
params = {
    "title": "Submit PR review on growth-eng#9 (Pam)",
    "notes": "...",            # raw string, newlines OK
    "when": "today",
    "tags": "🟢 Laptop",       # comma-separated for multiple
    "list": "❇️ Supabase",     # area OR project name
}
encoded = "&".join(f"{k}={quote(v, safe='')}" for k, v in params.items())
print(f"things:///add?{encoded}")
PY
URL=$(cat /tmp/things_url.txt) && open "$URL"
```

**Things URL parameters reference:**

| Param | Notes |
|---|---|
| `title` | Required. Plain string. |
| `notes` | Plain string with `\n` for newlines. Markdown rendered in Things. |
| `when` | `today`, `tomorrow`, `evening`, `anytime`, `someday`, or `YYYY-MM-DD`. |
| `deadline` | `YYYY-MM-DD`. Only set if user explicitly named a deadline. |
| `tags` | Comma-separated. Must match existing tags exactly (including emoji). |
| `list` | Area OR project name. Exact match against discovered list. |
| `heading` | Section within a project. Use only if user named one. |
| `checklist-items` | Newline-separated. For tasks with natural sub-steps. |

### Anti-patterns (this is why this skill exists)

- `urllib.parse.urlencode(params)` — defaults to `quote_plus`, encodes spaces as `+`. Don't.
- `urllib.parse.quote_plus(...)` — same problem.
- `quote(v)` without `safe=''` — leaves `/` unencoded; fine for most fields but inconsistent with the rule. Always pass `safe=''`.
- Building `things:///add?title=...` inline in `bash -c` or `open` — special characters (`#`, `&`, `(`, `)`) break. Always go through a file or shell variable.
- Hard-coding area names like `"Supabase"` instead of the exact `"❇️ Supabase"` — silent failure, task lands in Inbox.

## Step 5 — Verify

After creating, query Things to confirm. The just-added task should appear in its destination list:

```bash
osascript -e 'tell application "Things3" to get name of to dos of list "Today"'
osascript -e 'tell application "Things3" to get name of to dos of list "Inbox"'
```

For an area:

```bash
osascript <<'AS'
tell application "Things3"
    set theArea to area "❇️ Supabase"
    return name of to dos of theArea
end tell
AS
```

If the title isn't there with the expected wording (especially no `+` in place of spaces), report the mismatch — don't claim success.

## Step 6 — Report back

```markdown
**Task created in Things**

**Title**: [exact title as it landed]
**Scheduled**: [today / tomorrow / etc.]
**Area / Project**: [❇️ Supabase / etc., or "Inbox"]
**Tags**: [list, or "none"]

**Notes preview**:
> [first 1-2 lines]
```

Skip the closing pleasantries.

## Special cases

- **Multiple tasks in one request**: ask whether to create one task with a checklist or several separate tasks. Don't guess.
- **Vague request** ("remind me about that thing"): capture with best interpretation; add a `Note: [aspect needs clarification]` line in the notes. Don't block on ambiguity.
- **User wants this in Linear/GitHub, not Things**: skip this skill. This is Things-specific.
- **Recurring task**: the Things URL scheme doesn't natively support recurrence. Create the task and add a note `Note: set repeat in Things UI after capture` — recurrence is configured in the app.

## When not to use this skill

- The user is asking *about* tasks ("what's on my list?") — that's a query, not a capture. Use AppleScript directly.
- Creating tasks in another system (Linear, GitHub, the conversation's TaskCreate tool) — this skill is Things-only.
- Bulk-importing many tasks from a list — fine to invoke once per task, but check whether the user actually wants them all in Today (usually not).
