---
name: add-todo
description: Add a new task to Things 3 with correct area/project routing, tag inference, and URL-safe encoding. Use when the user says "add a task", "remind me to...", "create a todo", "put this in Things", "things 3 task", or similar Things-capture intent.
argument-hint: <task description>
allowed-tools: mcp__things__add_todo, mcp__things__get_tags, mcp__things__get_projects, mcp__things__get_areas, mcp__things__get_todos, Bash
---

# Add a Things 3 Task

Capture tasks into Things 3 with rich context, correct routing, and **no encoding bugs**. This skill exists to prevent recurring failure modes: `+`-encoded spaces in titles, wrong-area placement, and crowded Today views from unscoped defaults.

## Hard rules (do not skip)

1. **Always discover the user's current areas/projects/tags before creating.** They evolve; never hard-code names.
2. **Never use `quote_plus` or `urlencode`** when building Things URLs. Use `urllib.parse.quote(value, safe='')` per parameter so spaces become `%20`, not `+`. Things treats `+` literally and you get titles like `Submit+PR+review+on+Pam`.
3. **Open the URL from a shell variable**, not by passing it inline to `open`. Some characters (`#`, `&`) trip zsh globbing.
4. **Verify the task landed** before reporting success. Query Things via AppleScript and confirm title + area match what you intended.

## Step 1 — Discover current Things 3 structure

Run all three; cache results in conversation context:

```bash
osascript -e 'tell application "Things3" to get name of every area'
osascript -e 'tell application "Things3" to get name of every project whose status is open'
osascript -e 'tell application "Things3" to get name of every tag'
```

Areas and tags include emoji — preserve them exactly when passing back to Things.

## Step 2 — Decide routing

### Area assignment

**Work signals** (any of: Supabase, Growth Eng, a github.com/supabase URL, a Linear ticket ID, Customer.io, PostHog, work-Slack thread URL, named teammates Marc/Pam/Pedro/etc., Hex thread, anything from `~/supabase/`) → land in the **Supabase** area.

If the task references an active *project* (e.g. PostHog renewal, MCP activation push, a named experiment), try to find a matching open project and use that instead. Currently no Supabase-area projects exist in Things — area-only is the practical default.

**Personal signals** (home, errand, family, personal finance, mom, Tina, side projects) → try matching an open project first (`💰 Finance`, `🏡 41 Westwood`, `❤️ Mom`, `🧠 TheraGPT`, `🎿 Skiing`, etc.), then fall back to the **Personal** area, then to Inbox if nothing fits.

**Indie / side-project signals** (own product names, code in `~/indie/` or similar, "my side project") → **Indie Hacking** area, or its matching project if one exists.

**Ambiguous** → Inbox. Don't force a guess.

### Scheduling

Default `when: "today"`. Override only when the user explicitly says otherwise:

| User says | `when` |
|---|---|
| "tomorrow" | `tomorrow` |
| "this evening" / "tonight" | `evening` |
| "next week" / "later" | `someday` (or specific date if given) |
| "someday" | `someday` |
| YYYY-MM-DD or natural date | that date |
| no urgency | `anytime` |

### Tags

**Apply tags only when explicitly inferable** from user language. Otherwise leave untagged. Match against the discovered tag list — use exact strings including emoji:

| Signal | Tag |
|---|---|
| "urgent" | `🔴 Urgent` |
| "important" / "MIT" / "most important" | `🟠 Important` or `🌟 MIT` |
| "blocked on X" / "waiting for X" / "waiting on" | `🟡 Waiting` |
| "at home" / "from home" | `🟣 Home` |
| "at the office" | `Office` |
| "on my laptop" / "needs computer" | `🟢 Laptop` |
| "with Tina" / "ask Tina" / "Tina needs to" | `🔵 Tina Required` |
| "errand" / "while I'm out" | `Errand` |

Max 2-3 tags. Drop anything that doesn't match cleanly.

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
