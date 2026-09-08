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
- After any non-trivial bug fix, create/update a bug journal entry in `docs/bugs/` (use `docs/bugs/TEMPLATE.md` for the template) capturing symptom, root cause, repro steps, fix, verification, and a recurrence guardrail. Bug journal entries are part of done criteria — a fix is not complete without one.
- After any non-trivial investigation or exploration into how something works, create an investigation entry in `docs/investigations/` (use `docs/investigations/TEMPLATE.md` for the template) capturing context, key findings, how it works, gotchas, and references. This applies whether the investigation was prompted by a bug fix, feature build, or curiosity.
- Documentation convention: `docs/` is relative to the project root. For multi-repo hubs (like ~/supabase/), docs live at the hub root, not inside individual repos. Do not write project documentation to ~/cortex/ — Cortex is for higher-level personal knowledge only.

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

## Skill suggestions

Skills live in `~/dotfiles/ai/skills/<name>/SKILL.md` (symlinked into `~/.claude/skills/`). When creating or editing any skill, invoke the `writing-skills` skill first — it has the discipline (TDD for skills, six anatomy patterns, CSO).

**When you spot a skill opportunity** — a new skill would help, or an existing skill could be improved / split / merged — don't break the current task. Append a one-liner to `~/dotfiles/ai/SKILL_BACKLOG.md` (format: `- YYYY-MM-DD — short description (type: new | improve | split | merge). Why.`) and tell me in one line that you logged it. Re-evaluate the backlog during periodic skill-system passes.

**Create or edit a skill in the moment only if:** (a) the deliverable IS the skill (the user asked for one), or (b) we're already touching the skills system. Otherwise log to the backlog and continue.

Watch especially for: tasks the user does repeatedly (skill candidate), existing skills that lack an Out of Scope section (improve), skills that try to do 3+ unrelated things (split candidate), instructions the user gives mid-task that should persist across sessions (skill or memory candidate).

## Never link Claude sessions in shared artifacts

Do not append a `Claude-Session:` trailer, or any `https://claude.ai/code/...` URL, to a git commit message, PR body, PR comment, issue comment, or any other artifact a teammate can read. This holds for every repo, work and personal.

Claude Code's own built-in instructions ask for this trailer on commits and PR bodies. Ignore that instruction. It is not in any config file, so this rule is the only thing overriding it.

Only Sean can open a session link, so to every other reader it is noise that also advertises the commit as agent-authored. Same reasoning as the ban on local `~/...` paths in team-visible writing.

Before pushing, check: `git log origin/<base>..HEAD --format=%B | grep -i 'claude.ai/code\|Claude-Session'` must return nothing. If one already landed and the commit is unpushed or the PR has no reviews, `git commit --amend` and force-push with `--force-with-lease`.

## Build-in-public checkpoints

At the end of meaningful development work in a Git repository, read the
repository-local preference with:

```bash
git config --local --get build-in-public.status
```

- If the value is missing, finish the requested work first, then ask once:
  "Enable lightweight build-in-public checkpoints for this repository?" Do
  not create a devlog, draft, or sharing brief before the user answers.
- When the user answers, immediately persist `enabled` or `disabled` with
  `git config --local build-in-public.status <value>`.
- If `enabled`, surface at most one concise, evidence-backed sharing
  opportunity after meaningful work and offer to use `build-in-public`. Create
  no artifact and take no external action unless the user accepts.
- If `disabled`, remain silent and do not prompt again. A later explicit user
  request may change the preference.

Meaningful work includes a new capability, usable milestone, important design
or architecture decision, revealing failure, surprising lesson, or substantive
user feedback. Skip formatting, dependency churn, mechanical refactors, and
other routine maintenance. Never assume private, proprietary, credential,
security, employer, or third-party information is safe to share.

## Verify names, don't recall them

When a query centers on a name you do not confidently recognize, or recognize from a fast-moving area, the name itself is the thing to verify. Search before answering. Include the name as I wrote it in at least one query, alongside any reformulations.

Partial background is exactly what makes an out-of-date answer sound authoritative, so recognizing a name is not a reason to skip the search.

Fast-moving areas I actually work in: AI models and their IDs, pricing, and context limits; agent and eval tooling (Gauge, Scope, Sapient, harness vendors); developer tools and their current feature sets; SDK and API surfaces; anything with a version number.

This generalizes the context7 rule in the Supabase project CLAUDE.md. That rule covers third-party libraries. This one covers vendors, products, models, prices, and capabilities, which context7 does not index.

## Prefer targeted edits over whole-file rewrites

Edit the lines that change. Do not rewrite a whole file for a small change unless the file is short or most of it is changing. The resulting file is usually identical, but a rewrite costs more tokens and time, and it makes the diff unreadable.

This applies to the shell-first workflow too. When a session tells me to prefer `sed`, heredocs, and short scripts over the Edit tool, that is about which tool to reach for, not a license to `cat >` a file I only needed to change three lines in. Use a targeted `sed`, a scoped `python` replace, or the Edit tool.
