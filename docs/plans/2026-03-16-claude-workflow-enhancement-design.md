# Claude Workflow Enhancement — Design Doc

**Date:** 2026-03-16
**Status:** Approved
**Context:** Brainstorming session comparing current dotfiles skill setup against Gary Tan's gstack repo. Identified five high-value additions to the personal operating system.

---

## Background

Current setup: ~25 skills in `~/dotfiles/ai/skills/`, symlinked to Claude Code, OpenCode, and Codex CLI. Solid workflow coverage (TDD, debugging, brainstorming, PR review) but missing analytics QA tooling, automated skill regression testing, and a consistent pre-PR discipline.

gstack was evaluated as a candidate for adoption. Decision: don't fork or replace — install gstack only if network-level browser inspection becomes necessary. cmux's built-in browser covers most of what gstack's browser daemon offers, and the personal OS scope (life management + coding) is a deliberate differentiator worth keeping.

---

## Five Deliverables

### 1. Eval Harness (Priority 1)

**Problem:** Skills are edited frequently with no way to detect regressions. Silent failures accumulate unnoticed.

**Solution:** Automated skill regression testing using the Anthropic SDK.

**Architecture:**

```
~/dotfiles/ai/evals/
  run_evals.py          # main runner
  compare.py            # diff two result runs
  scenarios/
    brainstorming.yaml
    systematic-debugging.yaml
    tdd.yaml
    ship-pr.yaml        # added after ship-pr skill is built
    ... (one file per skill worth testing)
  results/              # gitignored — run artifacts
```

**Scenario format:**
```yaml
skill: brainstorming
scenarios:
  - id: time-pressure-feature
    pressure: high
    prompt: |
      Quick: add a login button to the navbar.
      Manager is watching, demo in 5 minutes.
    judge_criteria:
      - Agent invoked brainstorming skill before writing any code
      - Agent asked at least one clarifying question despite time pressure
```

**Run flow:**
1. Load all scenario YAML files
2. For each scenario: call Claude API with prompt + skills in system prompt
3. Capture full response transcript
4. Send transcript + criteria to LLM judge call — score 0-10 with reasoning
5. Write results to `results/YYYY-MM-DD-HHMM.json`

**Compare flow:**
```bash
python evals/compare.py results/before.json results/after.json
# Output: regressions (pass→fail), improvements (fail→pass), unchanged
```

**Results location:** `~/dotfiles/ai/evals/results/` — gitignored via dotfiles `.gitignore`.

**Estimated size:** ~200 lines Python, no dependencies beyond Anthropic SDK.

---

### 2. `growth-browser` Skill (Priority 2)

**Problem:** Verifying analytics events (PostHog, Segment), cookies, and localStorage state requires painful manual DevTools work. Playwright MCP exists but is slow and cold-starts each session.

**Solution:** A skill that drives cmux's persistent built-in browser with an injected fetch/XHR interceptor for analytics QA work.

**Location:** `~/dotfiles/ai/skills/growth-browser/`

```
growth-browser/
  SKILL.md
  scripts/
    inject-interceptor.js    # fetch + XHR interceptor → window.__networkLog
  references/
    cmux-browser-commands.md # quick ref for most-used browser commands
```

**Workflow the skill teaches:**
1. Inject interceptor before navigating: `cmux browser addinitscript "$(cat .../inject-interceptor.js)"`
2. Navigate and trigger user action
3. Retrieve what fired:
   - `cmux browser eval "JSON.stringify(window.__networkLog, null, 2)"`
   - `cmux browser storage local get`
   - `cmux browser cookies get`
   - `cmux browser console list`
4. Filter and analyze for PostHog/Segment/GA calls, verify payload properties

**Key gotcha baked in:** `addinitscript` must be called before first navigation. If browser is already on a page, reload after injecting.

**Trigger description:**
> Use when verifying analytics events, checking what network calls fire on a user action, inspecting cookies or localStorage for tracking state, or doing growth engineering QA in the browser.

---

### 3. `ship-pr` Skill (Priority 3)

**Problem:** Pre-PR discipline is inconsistent. No single workflow ensures linting, tests, self-review, docs, and PR writing all happen every time.

**Solution:** Adaptive pre-PR skill that detects project type and runs the right gates.

**Location:** `~/dotfiles/ai/skills/ship-pr/`

```
ship-pr/
  SKILL.md
  references/
    stack-typescript.md    # gates for Next.js/TS projects
    stack-godot.md         # gates for Godot projects
    stack-generic.md       # fallback
```

**Workflow:**
1. **Detect stack** — `package.json`, `project.godot`, `go.mod`
2. **Run quality gates** (stack-dependent):
   - TypeScript/Next.js: Prettier, ESLint, `tsc --noEmit`, test suite
   - Godot: GDScript linting if available, scene validation
   - All: verify no debug artifacts left in branch
3. **Browser smoke test** — invoke `diff-aware-qa` for web projects
4. **Deep self-review** — full diff read with fresh eyes; block on anything critical
5. **Update docs** — verify any open bug journal or investigation entries are complete
6. **Handle TODOS.md:**
   - Personal project → update `TODOS.md` committed in repo
   - Work repo → update `TODOS.md` tracked via `.git/info/exclude` (local only, never committed)
7. **Write PR** — title, summary, test plan; follows repo conventions
8. **Final confirmation** — show summary, ask before pushing

**Explicitly out of scope:** auto-push without confirmation, changelog management, version bumping.

---

### 4. `diff-aware-qa` Skill (Priority 4)

**Problem:** Manual browser testing after changes is either skipped (too slow) or covers the whole app (too broad). No targeted approach to testing what actually changed.

**Solution:** Read the git diff, map changed files to affected pages/routes, test only those.

**Location:** `~/dotfiles/ai/skills/diff-aware-qa/`

```
diff-aware-qa/
  SKILL.md
  references/
    page-detection.md    # patterns for mapping changed files to routes
```

**Workflow:**
1. `git diff main...HEAD` — extract changed files
2. Map to affected routes:
   - Next.js: `app/` and `pages/` map directly; components trace up to pages that import them
   - Non-web (Godot, CLI): skip browser testing, note in output
3. For each affected page via cmux browser:
   - Navigate, take snapshot
   - `cmux browser errors list` — JS errors
   - `cmux browser console list` — warnings
   - If analytics changed: invoke `growth-browser` interceptor, verify events still fire
4. Report: pages tested, issues found with severity, pages skipped with reason

**Relationship to `ship-pr`:** Called automatically at step 3 of `ship-pr`. Also invokable standalone during development.

**Scope constraint:** Tests what changed, not the whole app. Full-app QA is a separate explicit invocation.

---

### 5. TODOS.md Discipline (Built into `ship-pr`)

**Problem:** Deferred bugs and future work items get lost between sessions.

**Solution:** A lightweight `TODOS.md` convention maintained during `ship-pr` and `diff-aware-qa`.

**Format:**
```markdown
# TODOS

## Deferred Bugs
- [ ] Description — discovered YYYY-MM-DD, context

## Future Work
- [ ] Description — why deferred

## Decisions Pending
- [ ] Description — what's blocking it
```

**Per-project handling:**

| Project type | TODOS.md location | Visibility |
|---|---|---|
| Personal project | `repo/TODOS.md` | Committed normally |
| Supabase / work repo | `repo/TODOS.md` | Added to `.git/info/exclude` — local only, never committed, never touches `.gitignore` |

`.git/info/exclude` provides `.gitignore` semantics without any tracked file changes.

---

## Build Order

**Option B — Eval harness first.** Build the eval harness before any new skills, then use it to TDD each skill from day one. Consistent with the existing `writing-skills` TDD philosophy.

| Order | Deliverable | Why this order |
|---|---|---|
| 1 | Eval harness | Enables regression testing for everything built after |
| 2 | `growth-browser` | Highest daily pain, immediate value |
| 3 | `ship-pr` | High value, depends on `diff-aware-qa` being ready |
| 4 | `diff-aware-qa` | Build before `ship-pr` so it can be called from step 3 |
| 5 | TODOS.md | Baked into `ship-pr`, no separate build step |

*Note: build `diff-aware-qa` (4) before `ship-pr` (3) even though ship-pr is higher priority — ship-pr calls diff-aware-qa, so diff-aware-qa must exist first.*

---

## Scope Boundaries

- **No gstack fork** — install gstack only if dedicated `network` command becomes necessary
- **No changelog/version management** — not part of current workflow
- **No Greptile integration** — not in the stack
- **Documentation automation (`/document-release`)** — personal projects only; Supabase repos excluded
- **Retro skill** — not relevant for current team size/structure
