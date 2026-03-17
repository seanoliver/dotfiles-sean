# cmux Browser Commands — Growth/Analytics Quick Reference

## Setup (do this first, before any navigation)

```bash
# Inject network interceptor — MUST be before first navigation
cmux browser addinitscript "$(cat ~/.claude/skills/growth-browser/scripts/inject-interceptor.js)"

# Open browser split in current workspace (if not already open)
cmux browser open
```

## Navigation

```bash
cmux browser goto https://localhost:3000/your-page
cmux browser reload          # reload current page
cmux browser get url         # get current URL
```

## Retrieve network log (after triggering an action)

```bash
# All captured requests
cmux browser eval "JSON.stringify(window.__networkLog, null, 2)"

# Filter to PostHog only
cmux browser eval "JSON.stringify(window.__networkLog.filter(r => r.url.includes('posthog')), null, 2)"

# Filter to Segment only
cmux browser eval "JSON.stringify(window.__networkLog.filter(r => r.url.includes('segment') || r.url.includes('cdn.segment')), null, 2)"

# Count by URL pattern
cmux browser eval "JSON.stringify(window.__networkLog.reduce((acc, r) => { const key = new URL(r.url).hostname; acc[key] = (acc[key]||0)+1; return acc; }, {}))"

# Clear log and start fresh
cmux browser eval "window.__networkLog = []"
```

## Cookies and Storage

```bash
# Get all cookies
cmux browser cookies get

# Get specific cookie
cmux browser cookies get --name ph_distinct_id

# Get localStorage
cmux browser storage local get

# Get specific localStorage key
cmux browser storage local get --key posthog_session
```

## Console and Errors

```bash
cmux browser console list    # all console output
cmux browser errors list     # JS errors only
```

## Interaction (trigger user actions)

```bash
cmux browser snapshot -i                    # get interactive elements
cmux browser click @e1                      # click element by ref
cmux browser fill @e2 "test@example.com"    # fill input
cmux browser press Enter                    # keyboard
cmux browser wait --url-contains /dashboard # wait for navigation
```

## Screenshots

```bash
cmux browser screenshot --out /tmp/before.png
cmux browser screenshot --out /tmp/after.png
```

## Important Gotchas

- **addinitscript must run before navigation.** If the browser is already on a page, reload after injecting.
- **Refs (@e1, @e2) reset on navigation.** Always re-snapshot after navigating.
- **window.__networkLog persists across navigations** within the same session — clear it between tests with `cmux browser eval "window.__networkLog = []"`.
