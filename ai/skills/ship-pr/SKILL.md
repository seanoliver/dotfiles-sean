---
name: ship-pr
description: Use when code is done and ready to ship — before pushing or opening a PR. Runs quality gates (linting, tests, type checking), does a deep self-review of the diff, runs browser QA on affected pages, updates documentation, handles TODOS.md, and writes the PR. Trigger on phrases like "ready to ship", "create a PR", "push this", "open a pull request", "I'm done with this feature".
---

# Ship PR

Consistent pre-PR discipline — detect the stack, run the right gates, review, document, and write the PR.

**Announce at start:** "I'm using the ship-pr skill."

## Step 1: Detect stack

```bash
ls package.json 2>/dev/null && echo "typescript"
ls project.godot 2>/dev/null && echo "godot"
ls go.mod 2>/dev/null && echo "go"
```

Load the matching reference file:
- TypeScript/Next.js → `references/stack-typescript.md`
- Godot → `references/stack-godot.md`
- Anything else → `references/stack-generic.md`

## Step 2: Run quality gates

Follow the loaded stack reference exactly. Stop and fix before proceeding if any gate fails.

## Step 3: Browser QA (web projects only)

Invoke the `diff-aware-qa` skill. If it reports "no browser testing needed" (non-web project), continue.

## Step 4: Deep self-review

Read the full diff with fresh eyes:

```bash
git diff main...HEAD
```

Check for:
- Logic errors or missing edge cases
- Security issues (unvalidated input, exposed secrets, missing auth checks)
- Performance problems (N+1 queries, unnecessary re-renders, large payloads)
- Anything you'd be embarrassed for a senior engineer to find

**Block on any critical finding.** Fix it before continuing. Log non-critical issues to TODOS.md.

## Step 5: Update documentation

Check if any bug journal or investigation entries were opened during this work:

```bash
ls docs/bugs/*.md docs/investigations/*.md 2>/dev/null | xargs grep -l "Status: Open" 2>/dev/null
```

If open entries exist, verify they're complete before shipping.

## Step 6: Handle TODOS.md

Read `references/todos-discipline.md` for setup and format.

```bash
# Check for open items
cat TODOS.md 2>/dev/null | grep "^- \[ \]"
```

- Mark completed items `[x]`
- Add newly deferred bugs or decisions from the self-review

## Step 7: Write the PR

**Title:** `<type>(<scope>): <short description>` (conventional commits style).

**Body:** Invoke the `writing-pr-descriptions` skill. It enforces the concise, skimmable format and respects any project PR template at `.github/PULL_REQUEST_TEMPLATE.md`.

For UI changes, attach screenshots (from Playwright MCP's `browser_take_screenshot`) under the relevant section of whatever structure that skill produces.

## Step 8: Confirm before pushing

Show a summary:
```
Stack: TypeScript/Next.js
Gates passed: Prettier ✓, ESLint ✓, TypeScript ✓, Tests ✓
Browser QA: 2 pages tested, 0 issues
Self-review: 1 item deferred to TODOS.md
Docs: all entries complete
PR: ready to create
```

Ask: "Ready to push and open PR?"
