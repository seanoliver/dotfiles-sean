---
name: growth-browser
description: Use when verifying analytics events fired correctly, checking what network calls trigger on a user action, inspecting cookies or localStorage for tracking state, debugging PostHog or Segment event payloads, or doing growth engineering browser QA. Trigger on phrases like "did that event fire", "check what PostHog is sending", "verify the tracking", "inspect cookies", "what's in localStorage".
---

# Growth Browser

Drive cmux's persistent browser to verify analytics events, network calls, cookies, and localStorage — without touching Chrome DevTools manually.

## Setup (once per session)

Inject the network interceptor BEFORE navigating anywhere:

```bash
cmux browser addinitscript "$(cat ~/.claude/skills/growth-browser/scripts/inject-interceptor.js)"
```

If the browser is already on a page, reload after injecting:
```bash
cmux browser reload
```

## Standard Workflow

1. **Inject interceptor** (above)
2. **Navigate** to the page under test: `cmux browser goto <url>`
3. **Trigger the user action** (click, fill form, etc.) using snapshot refs
4. **Retrieve what fired:**

```bash
# All network calls
cmux browser eval "JSON.stringify(window.__networkLog, null, 2)"

# PostHog only
cmux browser eval "JSON.stringify(window.__networkLog.filter(r => r.url.includes('posthog')), null, 2)"

# Cookies + storage
cmux browser cookies get
cmux browser storage local get
cmux browser console list
```

5. **Verify** payload properties match expected values

## Reference

See `references/cmux-browser-commands.md` for full command reference, filtering patterns, and gotchas.
