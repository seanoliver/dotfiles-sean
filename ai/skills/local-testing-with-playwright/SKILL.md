---
name: local-testing-with-playwright
description: Use when testing any feature locally, verifying a bug fix, or doing browser-based QA. Always applies when the user asks to "test this locally" or "verify this works".
---

# Local Testing with Playwright MCP

## Overview

Use the Playwright MCP for live, manual browser control — navigate pages, inspect cookies, click UI elements, and observe network behavior directly in a real browser. Do NOT write automated test files.

## Starting the Stack

### Always start the full stack first

```bash
cd ~/supabase/platform && mise fullstack
```

This starts backend services + Studio at **localhost:8082**. Wait for it to be ready.

### For WWW or Docs testing (while fullstack is running)

```bash
# In a separate terminal
cd ~/supabase/supabase && pnpm dev:www    # → localhost:3000
cd ~/supabase/supabase && pnpm dev:docs   # → localhost:3001/docs
```

## Testing with the Playwright MCP

Use the Playwright MCP tools to control a browser directly:

| Tool | Purpose |
|------|---------|
| `browser_navigate` | Go to a URL |
| `browser_snapshot` | Inspect the page (accessibility tree, visible elements) |
| `browser_take_screenshot` | Visual check of current state |
| `browser_evaluate` | Run JS in the page (read cookies, inspect state) |
| `browser_click` | Click a button or element |
| `browser_network_requests` | Inspect outgoing network calls |
| `browser_console_messages` | Check console logs |

## Common Testing Patterns

### Check cookies

```js
// Via browser_evaluate
document.cookie
```

Or use `browser_network_requests` to observe what cookies are sent.

### Verify no cookie was set

1. `browser_navigate` to the URL
2. `browser_evaluate` → `document.cookie` and confirm the cookie is absent
3. Interact with the page (e.g. accept consent)
4. `browser_evaluate` again to confirm it's still absent

### Inspect in-memory state

```js
// browser_evaluate — read module-scoped state exposed on window or via console
window.__someDebugState
```

### Observe PostHog / analytics calls

Use `browser_network_requests` after navigating to see outgoing requests to PostHog or other analytics endpoints and verify payload content.

### Simulate user interactions

Use `browser_click`, `browser_fill_form`, `browser_press_key` to interact naturally with the UI.

## Key Rules

- **Always start fullstack first** — never test frontend in isolation
- **Use Playwright MCP tools** — don't write test files; control the browser directly
- **Use `browser_evaluate` for cookie and state inspection** — it's the fastest way to read JS state
- **Take screenshots** when reporting results to the user
