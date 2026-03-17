# Godot Quality Gates

## 1. GDScript linting (if gdtoolkit is installed)

```bash
# Check if gdlint is available
command -v gdlint && gdlint --version || echo "gdlint not installed — skipping"

# If available:
gdlint **/*.gd
```

## 2. Scene validation

```bash
# Check for broken node references (Godot 4)
grep -r "NodePath" . --include="*.tscn" | head -20
```

Review manually — Godot scene files are binary-ish, automated validation is limited.

## 3. Debug artifact check

```bash
# print() statements added in this branch
git diff main...HEAD | grep "^+" | grep -E "^\+\s*print\("

# breakpoint() calls
git diff main...HEAD | grep "^+" | grep "breakpoint()"
```

## 4. No browser testing

Godot projects don't have web routes. Skip diff-aware-qa entirely.
Report: "Godot project — browser QA not applicable."
