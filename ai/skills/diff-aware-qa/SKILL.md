---
name: diff-aware-qa
description: Use after making code changes to test only the affected pages in a web project. Automatically reads the git diff, maps changed files to routes, and runs targeted browser testing on those pages. Use before shipping, after a feature is implemented, or when asked to "test what changed" or "verify my changes in the browser". Skips automatically for non-web projects (Go, Godot, API-only).
---

# Diff-Aware QA

Test only what changed — read the git diff, identify affected pages, test those with cmux browser.

## Workflow

### Step 1: Read the diff

```bash
git diff main...HEAD --name-only
```

### Step 2: Map to affected pages

Use `references/page-detection.md` to map each changed file to a route.

- Next.js `app/`: changed `page.tsx` files map directly; changed components trace upward via grep
- Non-web projects (Go, Godot, API-only): **stop here**, report "no browser testing needed"

### Step 3: Test each affected page

For each route identified:

```bash
# Navigate
cmux browser goto http://localhost:3000<route>

# Check for errors
cmux browser errors list
cmux browser console list

# Take snapshot to verify render
cmux browser snapshot -i
```

If the diff includes analytics/tracking changes, also run the `growth-browser` workflow:
- Inject interceptor, trigger the relevant user action, verify events still fire correctly

### Step 4: Report

Output a structured summary:
```
Pages tested: /dashboard, /dashboard/settings
Issues found: 1
  - /dashboard: JS error "Cannot read properties of undefined" (line 45)
Pages skipped: /api/events (API route, no browser test)
```

## Reference

See `references/page-detection.md` for file-to-route mapping patterns and dev server URLs.
