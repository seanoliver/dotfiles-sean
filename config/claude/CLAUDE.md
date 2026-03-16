- Object Parameters vs. Boolean Flags: When a function has multiple optional parameters or boolean
  flags, using an object parameter significantly improves code readability at call sites. Compare
  handleGenerateTables('prompt', false) (unclear what false means) with handleGenerateTables({
  promptOverride: 'prompt', wasQuickIdea: false }) (self-documenting). The default parameter = {}
  allows calling with no arguments while maintaining TypeScript type safety.

- Nullish Coalescing (??) vs. Logical OR (||): The ?? operator only falls back to the right-hand
  value when the left is null or undefined, while || treats falsy values like 0, '', and false as
  triggers. For string fallbacks where an empty string should be preserved, ?? is the safer choice.
- Always RTFM and double/triple check the type definitions to make sure you're using a custom hook or
function from a third party API library to make sure you are passing the correct params and reading the crorrect response values. do not guess!
- when adding debugging comments, group them for easy searching by prepending them with a custom 1-2 character id (e.g. "[a] [NewTab] Data recieved" where "a" might be shared by other related logs in other files and you simply want to review them together -- always use unique ids for different "groups" of related debugging logs, and review wich "groups" you've already created in context to determine if you need to pick an existing one or create a new one for the given log it pertains to.
- After any non-trivial bug fix, create/update a bug journal entry in `docs/bugs/` (use `docs/bugs/TEMPLATE.md`) capturing symptom, root cause, repro steps, fix, verification, and a recurrence guardrail. Bug journal entries are part of done criteria — a fix is not complete without one.
- After any non-trivial investigation or exploration into how something works, create an investigation entry in `docs/investigations/` (use `docs/investigations/TEMPLATE.md`) capturing context, key findings, how it works, gotchas, and references. This applies whether the investigation was prompted by a bug fix, feature build, or curiosity.

## PR Pre-Push Checklist (MANDATORY — no exceptions)

Before every `git push` + `gh pr create`, run these three commands and confirm the output matches your expectations. If anything looks wrong, STOP and fix the branch before pushing.

```bash
# 1. What commits will this PR include?
git log --oneline origin/<base-branch>..HEAD
# Expected: exactly the commits you intentionally added. If you see 10+ and expected 1-3, STOP.

# 2. What is the diff size?
git diff origin/<base-branch>...HEAD --stat
# Expected: matches the scope of your change. A cleanup PR should be small.

# 3. After creating the PR, verify GitHub agrees:
gh pr view <number> --json commits,additions,deletions \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'Commits: {len(d[\"commits\"])}, +{d[\"additions\"]}/-{d[\"deletions\"]}')"
# Expected: matches what you saw locally. If the numbers are larger, close immediately.
```

**Stacked PRs are especially dangerous.** If the local base branch has commits that were never force-pushed to origin (e.g. after a rebase or code-review fixups), `origin/<base>` will be behind the local version, and GitHub will include all those extra commits in your PR. Always use `origin/<base>` (not the local branch name) as the reference in step 1.

