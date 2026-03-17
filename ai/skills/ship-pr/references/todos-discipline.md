# TODOS.md Discipline

## File location

| Project type | Where | Visibility |
|---|---|---|
| Personal project | `TODOS.md` in repo root | Committed normally |
| Supabase / work repo | `TODOS.md` in repo root | Added to `.git/info/exclude` — local only |

## Setting up .git/info/exclude (work repos, one-time setup)

```bash
echo "TODOS.md" >> .git/info/exclude
```

This file is inside `.git/` — it never appears in `git status`, never gets committed, never touches `.gitignore`.

## TODOS.md format

```markdown
# TODOS

## Deferred Bugs
- [ ] Description — discovered YYYY-MM-DD, context

## Future Work
- [ ] Description — why deferred

## Decisions Pending
- [ ] Description — what's blocking it
```

## When to update

**During ship-pr:** Mark completed items `[x]`, add newly deferred items from the self-review.

**During diff-aware-qa:** Add any bugs found that you're not fixing in this PR.

## Check during ship-pr

```bash
# See if TODOS.md exists and has open items
cat TODOS.md 2>/dev/null | grep -c "^- \[ \]" || echo "0 open items"
```
