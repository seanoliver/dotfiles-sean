---
name: growth-browser
description: Use when verifying analytics events fired correctly, checking what network calls trigger on a user action, inspecting cookies or localStorage for tracking state, debugging PostHog or Segment event payloads, or doing growth engineering browser QA. Trigger on phrases like "did that event fire", "check what PostHog is sending", "verify the tracking", "inspect cookies", "what's in localStorage".
---

# Growth Browser

Drive the Playwright MCP browser to verify analytics events, network calls, cookies, and localStorage — without touching Chrome DevTools manually.

## Setup

The Playwright MCP tools used by this skill are deferred. Load their schemas via ToolSearch before calling:

```
select:mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_evaluate,mcp__plugin_playwright_playwright__browser_snapshot,mcp__plugin_playwright_playwright__browser_click,mcp__plugin_playwright_playwright__browser_console_messages,mcp__plugin_playwright_playwright__browser_take_screenshot
```

## Standard Workflow

1. **Navigate** to the page under test:
   ```
   browser_navigate({ url: "https://localhost:3000/your-page" })
   ```

2. **Inject the network interceptor.** Pass the contents of `scripts/inject-interceptor.js` as the function body to `browser_evaluate`. Re-inject after any cross-page navigation since `window.__networkLog` lives in page context.

3. **Trigger the user action.** Use `browser_snapshot()` to find element refs, then `browser_click({ target: "<ref>", element: "<description>" })`.

4. **Retrieve what fired:**
   - All network calls: `browser_evaluate({ function: "() => JSON.stringify(window.__networkLog, null, 2)" })`
   - PostHog only: `browser_evaluate({ function: "() => JSON.stringify(window.__networkLog.filter(r => r.url.includes('posthog')), null, 2)" })`
   - Segment only: `browser_evaluate({ function: "() => JSON.stringify(window.__networkLog.filter(r => r.url.includes('segment')), null, 2)" })`
   - Count by hostname: `browser_evaluate({ function: "() => JSON.stringify(window.__networkLog.reduce((acc, r) => { const k = new URL(r.url).hostname; acc[k] = (acc[k]||0)+1; return acc; }, {}))" })`
   - Clear log: `browser_evaluate({ function: "() => { window.__networkLog = [] }" })`
   - All cookies: `browser_evaluate({ function: "() => document.cookie" })`
   - All localStorage: `browser_evaluate({ function: "() => Object.fromEntries(Object.entries(localStorage))" })`
   - Specific localStorage key: `browser_evaluate({ function: "() => localStorage.getItem('posthog_session')" })`
   - Console output: `browser_console_messages({ level: "info" })` (or `"error"` for errors only)

5. **Verify** payload properties match expected values.

## Screenshots

```
browser_take_screenshot({ filename: "before.png", type: "png" })
```

## Gotchas

- The interceptor must be re-injected after any cross-page navigation. `window.__networkLog` is page-scoped.
- `browser_snapshot` refs reset on navigation. Re-snapshot after navigating before clicking refs.
- Clear `window.__networkLog` between tests to avoid stale entries from prior interactions.
