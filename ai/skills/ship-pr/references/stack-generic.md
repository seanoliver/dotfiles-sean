# Generic Project Quality Gates

For projects that don't match TypeScript/Next.js or Godot patterns.

## 1. Check for a test command

```bash
# Look for test scripts
cat package.json | grep -A5 '"scripts"' 2>/dev/null
cat Makefile 2>/dev/null | grep -E "^test"
ls *_test.go 2>/dev/null && echo "Go tests found"
```

Run whatever test command exists.

## 2. Debug artifact check

```bash
git diff main...HEAD | grep "^+" | grep -iE "console\.log|print\(|debugger|breakpoint"
```

## 3. Browser testing

Only if the project has a web UI and a local dev server.
Check `package.json` for a `dev` or `start` script.
If no web UI: skip diff-aware-qa, note "no web interface detected."
