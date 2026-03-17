# TypeScript/Next.js Quality Gates

Run these in order. Stop and fix before proceeding if any fail.

## 1. Prettier

```bash
# Check only (don't auto-fix without asking)
npx prettier --check "**/*.{ts,tsx,js,jsx,json,css,md}"
```

If it fails: `npx prettier --write "**/*.{ts,tsx,js,jsx,json,css,md}"` then re-check.

## 2. ESLint

```bash
npx eslint . --ext .ts,.tsx --max-warnings 0
```

Zero warnings policy — all warnings must be resolved or explicitly suppressed with a comment.

## 3. TypeScript type check

```bash
npx tsc --noEmit
```

## 4. Tests

```bash
# Run test suite — use whichever is configured
npm test
# or
npx vitest run
# or
npx jest --ci
```

Check `package.json` scripts for the right command.

## 5. Debug artifact check

```bash
# Uncommitted console.logs in changed files
git diff main...HEAD | grep "^+" | grep -E "console\.(log|warn|error|debug)" | grep -v "//.*console"

# TODO comments added in this branch (not pre-existing)
git diff main...HEAD | grep "^+" | grep -E "TODO|FIXME|HACK|XXX"
```

Flag these to the user — they may be intentional but should be acknowledged.
