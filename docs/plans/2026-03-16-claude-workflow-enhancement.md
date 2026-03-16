# Claude Workflow Enhancement Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Build an eval harness for skill regression testing, a growth-browser skill for analytics QA, a diff-aware-qa skill for targeted browser testing, and a ship-pr skill for consistent pre-PR discipline.

**Architecture:** Five deliverables built in dependency order — eval harness first (enables TDD for all subsequent skills), then growth-browser, diff-aware-qa, and ship-pr. TODOS.md discipline is baked into ship-pr, not a separate build step.

**Tech Stack:** Python 3 + Anthropic SDK (eval harness), cmux browser CLI (growth-browser + diff-aware-qa), Markdown skills (all)

---

## Task 1: Eval Harness — Directory Structure + Dependencies

**Files:**
- Create: `ai/evals/run_evals.py`
- Create: `ai/evals/compare.py`
- Create: `ai/evals/requirements.txt`
- Create: `ai/evals/scenarios/.gitkeep`
- Create: `ai/evals/results/.gitkeep`
- Modify: `.gitignore`

**Step 1: Create the directory structure**

```bash
mkdir -p ~/dotfiles/ai/evals/scenarios
mkdir -p ~/dotfiles/ai/evals/results
```

**Step 2: Create requirements.txt**

```
anthropic>=0.40.0
pyyaml>=6.0
```

**Step 3: Verify Anthropic SDK is available**

```bash
python3 -c "import anthropic; print(anthropic.__version__)"
```

If missing: `pip install anthropic pyyaml`

**Step 4: Add results/ to .gitignore**

In `~/dotfiles/.gitignore`, add:
```
ai/evals/results/
```

**Step 5: Create placeholder files so directories are tracked**

```bash
touch ~/dotfiles/ai/evals/scenarios/.gitkeep
touch ~/dotfiles/ai/evals/results/.gitkeep
```

**Step 6: Commit**

```bash
git add ai/evals/ .gitignore
git commit -m "chore(evals): scaffold eval harness directory structure"
```

---

## Task 2: Eval Harness — Core Runner Script

**Files:**
- Create: `ai/evals/run_evals.py`

**Step 1: Write run_evals.py**

```python
#!/usr/bin/env python3
"""
Skill eval runner — tests whether Claude skills trigger and are followed correctly.
Usage: python run_evals.py [--skill brainstorming] [--verbose]
"""

import anthropic
import yaml
import json
import argparse
from datetime import datetime
from pathlib import Path

MODEL = "claude-sonnet-4-6"
PASS_THRESHOLD = 7  # score >= 7 is a pass

client = anthropic.Anthropic()


def load_scenarios(scenarios_dir: Path, skill_filter: str | None = None) -> list[dict]:
    """Load all scenario YAML files, optionally filtered by skill name."""
    scenarios = []
    for yaml_file in sorted(scenarios_dir.glob("*.yaml")):
        with open(yaml_file) as f:
            data = yaml.safe_load(f)
        skill_name = data.get("skill", yaml_file.stem)
        if skill_filter and skill_name != skill_filter:
            continue
        for scenario in data.get("scenarios", []):
            scenario["skill"] = skill_name
            scenarios.append(scenario)
    return scenarios


def build_system_prompt(skill_names: list[str]) -> str:
    """Build a system prompt that tells Claude which skills are available."""
    skills_list = "\n".join(f"- {name}" for name in skill_names)
    return f"""You are Claude Code, an AI coding assistant. You have the following skills available:

{skills_list}

When a skill applies to the user's request, you MUST invoke it before responding.
Skills are invoked by calling the Skill tool with the skill name."""


def run_scenario(scenario: dict, skill_names: list[str]) -> str:
    """Run a single scenario and return the agent's response transcript."""
    response = client.messages.create(
        model=MODEL,
        max_tokens=1500,
        system=build_system_prompt(skill_names),
        messages=[{"role": "user", "content": scenario["prompt"]}],
    )
    return response.content[0].text


def judge_response(scenario: dict, agent_response: str) -> dict:
    """Use an LLM judge to score whether the agent met the scenario criteria."""
    criteria_str = "\n".join(f"- {c}" for c in scenario["judge_criteria"])

    judge_prompt = f"""You are evaluating whether an AI agent correctly followed a skill workflow.

Scenario ID: {scenario["id"]}
Skill being tested: {scenario["skill"]}
Pressure level: {scenario.get("pressure", "medium")}

User prompt given to agent:
{scenario["prompt"]}

Agent's response:
{agent_response}

Criteria to evaluate (did the agent meet each one?):
{criteria_str}

Score the agent 0-10:
- 10: Met all criteria fully
- 7-9: Met most criteria with minor gaps
- 4-6: Partially met criteria
- 1-3: Mostly failed criteria
- 0: Completely ignored the skill

Respond ONLY with valid JSON, no other text:
{{"score": <0-10>, "passed": <true if score >= {PASS_THRESHOLD}>, "reasoning": "<one sentence>", "criteria_met": [<list of met criteria>], "criteria_missed": [<list of missed criteria>]}}"""

    judge_response = client.messages.create(
        model=MODEL,
        max_tokens=600,
        messages=[{"role": "user", "content": judge_prompt}],
    )

    raw = judge_response.content[0].text.strip()
    return json.loads(raw)


def run_evals(
    scenarios_dir: Path,
    results_dir: Path,
    skill_filter: str | None = None,
    verbose: bool = False,
) -> dict:
    scenarios = load_scenarios(scenarios_dir, skill_filter)
    if not scenarios:
        print("No scenarios found.")
        return {}

    # Collect all skill names for system prompt
    all_skill_names = list({s["skill"] for s in scenarios})

    results = []
    for scenario in scenarios:
        label = f"{scenario['skill']} / {scenario['id']}"
        print(f"  Running: {label}...", end=" ", flush=True)

        try:
            response = run_scenario(scenario, all_skill_names)
            judgment = judge_response(scenario, response)

            result = {
                "skill": scenario["skill"],
                "scenario": scenario["id"],
                "pressure": scenario.get("pressure", "medium"),
                "score": judgment["score"],
                "passed": judgment["passed"],
                "reasoning": judgment["reasoning"],
                "criteria_met": judgment.get("criteria_met", []),
                "criteria_missed": judgment.get("criteria_missed", []),
            }
            results.append(result)

            status = "✓" if result["passed"] else "✗"
            print(f"{status} {result['score']}/10 — {result['reasoning']}")

            if verbose and result["criteria_missed"]:
                for c in result["criteria_missed"]:
                    print(f"    ✗ {c}")

        except Exception as e:
            print(f"ERROR: {e}")
            results.append({
                "skill": scenario["skill"],
                "scenario": scenario["id"],
                "score": 0,
                "passed": False,
                "reasoning": f"Error: {e}",
                "criteria_met": [],
                "criteria_missed": scenario.get("judge_criteria", []),
            })

    total = len(results)
    passed = sum(1 for r in results if r["passed"])

    output = {
        "run_id": datetime.now().strftime("%Y-%m-%d-%H%M"),
        "model": MODEL,
        "total": total,
        "passed": passed,
        "pass_rate": round(passed / total, 2) if total > 0 else 0,
        "results": results,
    }

    results_dir.mkdir(parents=True, exist_ok=True)
    output_file = results_dir / f"{output['run_id']}.json"
    with open(output_file, "w") as f:
        json.dump(output, f, indent=2)

    print(f"\nResults: {passed}/{total} passed ({output['pass_rate']:.0%})")
    print(f"Saved to: {output_file}")

    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run skill evals")
    parser.add_argument("--skill", help="Run only scenarios for this skill name")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show missed criteria")
    parser.add_argument("--scenarios", default="scenarios", help="Scenarios dir (default: scenarios/)")
    parser.add_argument("--results", default="results", help="Results dir (default: results/)")
    args = parser.parse_args()

    base_dir = Path(__file__).parent
    run_evals(
        scenarios_dir=base_dir / args.scenarios,
        results_dir=base_dir / args.results,
        skill_filter=args.skill,
        verbose=args.verbose,
    )
```

**Step 2: Make it executable**

```bash
chmod +x ~/dotfiles/ai/evals/run_evals.py
```

**Step 3: Verify the script parses without errors**

```bash
cd ~/dotfiles/ai/evals && python3 -c "import run_evals; print('OK')"
```

Expected: `OK`

**Step 4: Commit**

```bash
git add ai/evals/run_evals.py
git commit -m "feat(evals): add eval runner script with LLM judge"
```

---

## Task 3: Eval Harness — Compare Script

**Files:**
- Create: `ai/evals/compare.py`

**Step 1: Write compare.py**

```python
#!/usr/bin/env python3
"""
Compare two eval result runs to detect regressions and improvements.
Usage: python compare.py results/before.json results/after.json
"""

import json
import sys
from pathlib import Path


def compare(before_path: str, after_path: str) -> None:
    with open(before_path) as f:
        before = json.load(f)
    with open(after_path) as f:
        after = json.load(f)

    before_lookup = {(r["skill"], r["scenario"]): r for r in before["results"]}
    after_lookup = {(r["skill"], r["scenario"]): r for r in after["results"]}

    regressions = []
    improvements = []
    unchanged = []
    new_scenarios = []

    for key, after_result in after_lookup.items():
        if key not in before_lookup:
            new_scenarios.append(after_result)
            continue
        before_result = before_lookup[key]
        if before_result["passed"] and not after_result["passed"]:
            regressions.append((before_result, after_result))
        elif not before_result["passed"] and after_result["passed"]:
            improvements.append((before_result, after_result))
        else:
            unchanged.append(after_result)

    print(f"\n{'='*60}")
    print("EVAL COMPARISON")
    print(f"Before: {before['run_id']}  ({before['passed']}/{before['total']} passed)")
    print(f"After:  {after['run_id']}  ({after['passed']}/{after['total']} passed)")
    print(f"{'='*60}")

    if regressions:
        print(f"\n🔴 REGRESSIONS ({len(regressions)}) — these need fixing:")
        for b, a in regressions:
            print(f"  {a['skill']} / {a['scenario']}")
            print(f"    Before: {b['score']}/10 — {b['reasoning']}")
            print(f"    After:  {a['score']}/10 — {a['reasoning']}")
            if a.get("criteria_missed"):
                for c in a["criteria_missed"]:
                    print(f"      ✗ {c}")

    if improvements:
        print(f"\n🟢 IMPROVEMENTS ({len(improvements)}):")
        for b, a in improvements:
            print(f"  {a['skill']} / {a['scenario']}")
            print(f"    Before: {b['score']}/10 → After: {a['score']}/10")

    if new_scenarios:
        print(f"\n🆕 NEW SCENARIOS ({len(new_scenarios)}):")
        for r in new_scenarios:
            status = "✓" if r["passed"] else "✗"
            print(f"  {status} {r['skill']} / {r['scenario']} ({r['score']}/10)")

    print(f"\nUnchanged: {len(unchanged)} scenarios")

    if regressions:
        print("\n⚠️  REGRESSIONS DETECTED — do not merge skill changes until fixed.")
        sys.exit(1)
    else:
        print("\n✅ No regressions detected.")


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python compare.py <before.json> <after.json>")
        sys.exit(1)
    compare(sys.argv[1], sys.argv[2])
```

**Step 2: Make executable and verify**

```bash
chmod +x ~/dotfiles/ai/evals/compare.py
python3 -c "import compare; print('OK')"
```

Expected: `OK`

**Step 3: Commit**

```bash
git add ai/evals/compare.py
git commit -m "feat(evals): add eval comparison script"
```

---

## Task 4: Eval Harness — Initial Scenario Files

**Files:**
- Create: `ai/evals/scenarios/brainstorming.yaml`
- Create: `ai/evals/scenarios/systematic-debugging.yaml`
- Create: `ai/evals/scenarios/tdd.yaml`
- Create: `ai/evals/scenarios/verification-before-completion.yaml`

**Step 1: Write brainstorming.yaml**

```yaml
skill: brainstorming
scenarios:
  - id: simple-feature-request
    pressure: low
    prompt: |
      Add a login button to the navbar of our React app.
    judge_criteria:
      - Agent invoked the brainstorming skill before writing any code or implementation
      - Agent asked at least one clarifying question about the feature

  - id: time-pressure-feature
    pressure: high
    prompt: |
      Quick: add a login button to the navbar. Manager is watching,
      demo in 5 minutes. Just write the code.
    judge_criteria:
      - Agent still invoked brainstorming despite the time pressure framing
      - Agent did not immediately write implementation code

  - id: refactor-request
    pressure: medium
    prompt: |
      Refactor the UserProfile component — it's getting too complex.
    judge_criteria:
      - Agent invoked brainstorming to understand the goal before touching code
      - Agent did not immediately start editing files
```

**Step 2: Write systematic-debugging.yaml**

```yaml
skill: systematic-debugging
scenarios:
  - id: obvious-bug
    pressure: low
    prompt: |
      My button click handler isn't firing. The onClick prop is set
      but nothing happens when I click the button.
    judge_criteria:
      - Agent invoked systematic-debugging skill before proposing a fix
      - Agent did not immediately suggest a code change without diagnosing first

  - id: production-pressure-bug
    pressure: high
    prompt: |
      URGENT: production is broken, users can't log in. Error: "Cannot read
      properties of undefined (reading 'userId')". Fix it now.
    judge_criteria:
      - Agent invoked systematic-debugging despite urgency framing
      - Agent asked for more diagnostic information or proposed investigation steps
```

**Step 3: Write tdd.yaml**

```yaml
skill: test-driven-development
scenarios:
  - id: new-function
    pressure: low
    prompt: |
      Implement a function that validates email addresses.
    judge_criteria:
      - Agent invoked test-driven-development skill before writing implementation
      - Agent wrote or proposed a failing test before any implementation code

  - id: sunk-cost-pressure
    pressure: high
    prompt: |
      I've spent 3 hours writing a 200-line payment processing function.
      It works perfectly — I manually tested every case. It's 6pm, I have
      dinner plans. I just realized I never wrote tests. Should I commit
      and write tests tomorrow?
    judge_criteria:
      - Agent invoked TDD skill or referenced it
      - Agent did not recommend committing untested code
      - Agent recommended writing tests before committing (even if that means delay)
```

**Step 4: Write verification-before-completion.yaml**

```yaml
skill: verification-before-completion
scenarios:
  - id: claim-fix-complete
    pressure: low
    prompt: |
      I think I've fixed the bug where the user's avatar wasn't loading.
      I changed the image URL construction logic. Can we say it's done?
    judge_criteria:
      - Agent invoked verification-before-completion skill
      - Agent required running actual verification commands before claiming done
      - Agent did not just say "looks good, it's done"

  - id: about-to-commit
    pressure: medium
    prompt: |
      I'm about to create a PR for the new onboarding flow. The code
      looks right to me. Let's write the PR description and push.
    judge_criteria:
      - Agent invoked verification-before-completion before agreeing to push
      - Agent required evidence (test output, browser check) before proceeding
```

**Step 5: Run the evals for the first time to establish a baseline**

```bash
cd ~/dotfiles/ai/evals
python3 run_evals.py --verbose
```

Expected: some passes, some failures. This is your baseline. Note the run ID from the output (format: `YYYY-MM-DD-HHMM`).

**Step 6: Commit scenarios**

```bash
git add ai/evals/scenarios/
git commit -m "feat(evals): add initial scenarios for brainstorming, debugging, TDD, verification"
```

---

## Task 5: `growth-browser` Skill — Interceptor Script

**Files:**
- Create: `ai/skills/growth-browser/scripts/inject-interceptor.js`

**Step 1: Create directory**

```bash
mkdir -p ~/dotfiles/ai/skills/growth-browser/scripts
mkdir -p ~/dotfiles/ai/skills/growth-browser/references
```

**Step 2: Write inject-interceptor.js**

```javascript
/**
 * growth-browser network interceptor
 * Injected via: cmux browser addinitscript "$(cat path/to/inject-interceptor.js)"
 * Captures all fetch and XHR calls into window.__networkLog
 *
 * IMPORTANT: Must be injected BEFORE navigating to the target page.
 * If already on a page, reload after injecting.
 */
(function () {
  if (window.__interceptorInstalled) return;
  window.__interceptorInstalled = true;
  window.__networkLog = [];

  // --- Intercept fetch ---
  const originalFetch = window.fetch;
  window.fetch = function (...args) {
    const url =
      typeof args[0] === "string"
        ? args[0]
        : args[0]?.url || String(args[0]);
    const options = args[1] || {};
    const entry = {
      type: "fetch",
      url,
      method: (options.method || "GET").toUpperCase(),
      body: options.body ? String(options.body).substring(0, 1000) : null,
      timestamp: Date.now(),
      ts: new Date().toISOString(),
    };
    window.__networkLog.push(entry);
    return originalFetch.apply(this, args);
  };

  // --- Intercept XHR ---
  const originalOpen = XMLHttpRequest.prototype.open;
  const originalSend = XMLHttpRequest.prototype.send;

  XMLHttpRequest.prototype.open = function (method, url) {
    this._logEntry = { type: "xhr", method: method.toUpperCase(), url };
    return originalOpen.apply(this, arguments);
  };

  XMLHttpRequest.prototype.send = function (body) {
    if (this._logEntry) {
      this._logEntry.body = body ? String(body).substring(0, 1000) : null;
      this._logEntry.timestamp = Date.now();
      this._logEntry.ts = new Date().toISOString();
      window.__networkLog.push(this._logEntry);
    }
    return originalSend.apply(this, arguments);
  };

  console.log("[growth-browser] Network interceptor installed ✓");
})();
```

**Step 3: Verify the script is valid JavaScript**

```bash
node --check ~/dotfiles/ai/skills/growth-browser/scripts/inject-interceptor.js
```

Expected: no output (no errors)

**Step 4: Commit**

```bash
git add ai/skills/growth-browser/
git commit -m "feat(skills): add growth-browser fetch/XHR interceptor script"
```

---

## Task 6: `growth-browser` Skill — Reference File + SKILL.md

**Files:**
- Create: `ai/skills/growth-browser/references/cmux-browser-commands.md`
- Create: `ai/skills/growth-browser/SKILL.md`

**Step 1: Write cmux-browser-commands.md**

```markdown
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
```

**Step 2: Write SKILL.md**

```markdown
---
name: growth-browser
description: Use when verifying analytics events fired correctly, checking what network calls trigger on a user action, inspecting cookies or localStorage for tracking state, debugging PostHog or Segment event payloads, or doing growth engineering browser QA. Trigger on phrases like "did that event fire", "check what PostHog is sending", "verify the tracking", "inspect cookies", "what's in localStorage".
---

# Growth Browser

Drive cmux's persistent browser to verify analytics events, network calls, cookies, and localStorage — without touching Chrome DevTools manually.

## Setup (once per session)

Inject the network interceptor BEFORE navigating anywhere:

```bash
cmux browser addinitscript "$(cat ~/.claude/skills/growth-browser/scripts/inject-interceptor.js)"
```

If the browser is already on a page, reload after injecting:
```bash
cmux browser reload
```

## Standard Workflow

1. **Inject interceptor** (above)
2. **Navigate** to the page under test: `cmux browser goto <url>`
3. **Trigger the user action** (click, fill form, etc.) using snapshot refs
4. **Retrieve what fired:**

```bash
# All network calls
cmux browser eval "JSON.stringify(window.__networkLog, null, 2)"

# PostHog only
cmux browser eval "JSON.stringify(window.__networkLog.filter(r => r.url.includes('posthog')), null, 2)"

# Cookies + storage
cmux browser cookies get
cmux browser storage local get
cmux browser console list
```

5. **Verify** payload properties match expected values

## Reference

See `references/cmux-browser-commands.md` for full command reference, filtering patterns, and gotchas.
```

**Step 3: Validate skill frontmatter**

```bash
python3 ~/dotfiles/ai/skills/.system/skill-creator/scripts/quick_validate.py \
  ~/dotfiles/ai/skills/growth-browser
```

Expected: `Skill is valid!`

**Step 4: Commit**

```bash
git add ai/skills/growth-browser/
git commit -m "feat(skills): add growth-browser skill for analytics QA"
```

---

## Task 7: `diff-aware-qa` Skill

**Files:**
- Create: `ai/skills/diff-aware-qa/references/page-detection.md`
- Create: `ai/skills/diff-aware-qa/SKILL.md`

**Step 1: Create directory**

```bash
mkdir -p ~/dotfiles/ai/skills/diff-aware-qa/references
```

**Step 2: Write page-detection.md**

```markdown
# Mapping Changed Files to Affected Pages

## Next.js App Router (`app/` directory)

| Changed file pattern | Affected route |
|---|---|
| `app/page.tsx` | `/` |
| `app/dashboard/page.tsx` | `/dashboard` |
| `app/[slug]/page.tsx` | All dynamic routes under `/` |
| `app/layout.tsx` | All routes (global layout change) |
| `app/dashboard/layout.tsx` | All routes under `/dashboard` |

**Components:** trace upward — find all `import` references to the changed component, then map those files to their routes using the table above.

```bash
# Find all files importing a changed component
grep -r "from.*ComponentName" app/ --include="*.tsx" -l
```

## Next.js Pages Router (`pages/` directory)

File path maps directly to route:
- `pages/index.tsx` → `/`
- `pages/dashboard.tsx` → `/dashboard`
- `pages/api/events.ts` → API route, no browser test needed

## Non-web projects (skip browser testing)

- Go files, `.go` extension → skip, note "CLI project — no browser testing"
- Godot files, `.gd` or `.tscn` extension → skip, note "Godot project — no browser testing"
- API-only changes (files only in `api/` or `server/`) → skip browser, note "API-only change"

## Dev server URLs

Always test against the local dev server. Common ports:
- Next.js: `http://localhost:3000`
- Vite: `http://localhost:5173`
- Custom: check `package.json` scripts for `--port` flag
```

**Step 3: Write SKILL.md**

```markdown
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
```

**Step 4: Validate and commit**

```bash
python3 ~/dotfiles/ai/skills/.system/skill-creator/scripts/quick_validate.py \
  ~/dotfiles/ai/skills/diff-aware-qa

git add ai/skills/diff-aware-qa/
git commit -m "feat(skills): add diff-aware-qa skill for targeted browser regression testing"
```

---

## Task 8: `ship-pr` Skill — Reference Files

**Files:**
- Create: `ai/skills/ship-pr/references/stack-typescript.md`
- Create: `ai/skills/ship-pr/references/stack-godot.md`
- Create: `ai/skills/ship-pr/references/stack-generic.md`
- Create: `ai/skills/ship-pr/references/todos-discipline.md`

**Step 1: Create directory**

```bash
mkdir -p ~/dotfiles/ai/skills/ship-pr/references
```

**Step 2: Write stack-typescript.md**

```markdown
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
```

**Step 3: Write stack-godot.md**

```markdown
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
```

**Step 4: Write stack-generic.md**

```markdown
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
```

**Step 5: Write todos-discipline.md**

```markdown
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
```

**Step 6: Commit**

```bash
git add ai/skills/ship-pr/references/
git commit -m "feat(skills): add ship-pr reference files for stack detection and TODOS discipline"
```

---

## Task 9: `ship-pr` Skill — SKILL.md

**Files:**
- Create: `ai/skills/ship-pr/SKILL.md`

**Step 1: Write SKILL.md**

```markdown
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

Title format: `<type>(<scope>): <short description>` (conventional commits style)

Body sections:
- **Summary** — what changed and why (2-4 bullets)
- **Test plan** — what was tested and how
- **Screenshots** — for UI changes (attach from `cmux browser screenshot`)
- **Notes** — anything reviewers should know

For Supabase repos: follow the existing PR template if one exists (check `.github/PULL_REQUEST_TEMPLATE.md`).

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
```

**Step 2: Validate and commit**

```bash
python3 ~/dotfiles/ai/skills/.system/skill-creator/scripts/quick_validate.py \
  ~/dotfiles/ai/skills/ship-pr

git add ai/skills/ship-pr/
git commit -m "feat(skills): add ship-pr skill for consistent pre-PR discipline"
```

---

## Task 10: Add Eval Scenarios for New Skills + Final Baseline

**Files:**
- Create: `ai/evals/scenarios/growth-browser.yaml`
- Create: `ai/evals/scenarios/ship-pr.yaml`

**Step 1: Write growth-browser.yaml**

```yaml
skill: growth-browser
scenarios:
  - id: posthog-event-verification
    pressure: low
    prompt: |
      I just added a new PostHog event for when users click the upgrade button.
      Can you verify the event is firing correctly with the right properties?
    judge_criteria:
      - Agent invoked growth-browser skill
      - Agent described injecting the network interceptor before navigating
      - Agent described checking window.__networkLog for PostHog calls

  - id: cookie-inspection
    pressure: low
    prompt: |
      I need to check what cookies are set after a user logs in on localhost:3000.
    judge_criteria:
      - Agent invoked growth-browser or described using cmux browser cookies get
      - Agent did not suggest opening Chrome manually
```

**Step 2: Write ship-pr.yaml**

```yaml
skill: ship-pr
scenarios:
  - id: feature-complete-typescript
    pressure: low
    prompt: |
      I've finished implementing the new onboarding flow in our Next.js app.
      Time to ship — can you help me get this into a PR?
    judge_criteria:
      - Agent invoked ship-pr skill before doing anything else
      - Agent described running quality gates (lint, tests, type check)
      - Agent described doing a self-review before pushing

  - id: skip-gates-pressure
    pressure: high
    prompt: |
      The feature is done and working. Skip the linting and tests — they always
      pass anyway and the deadline is in 10 minutes. Just write the PR and push.
    judge_criteria:
      - Agent still invoked ship-pr skill
      - Agent did not skip quality gates despite deadline pressure
      - Agent ran or described running the gates before writing the PR
```

**Step 3: Run the full eval suite to establish final baseline**

```bash
cd ~/dotfiles/ai/evals
python3 run_evals.py --verbose
```

Note the run ID. This is your production baseline. Any future skill edit should be compared against this run.

**Step 4: Commit and push**

```bash
git add ai/evals/scenarios/
git commit -m "feat(evals): add scenarios for growth-browser and ship-pr skills"
git push
```

---

## How to Use the Eval Harness Going Forward

**Before editing a skill:**
```bash
cd ~/dotfiles/ai/evals
python3 run_evals.py --skill brainstorming    # run just one skill's scenarios
# note the result file path from output
```

**After editing the skill:**
```bash
python3 run_evals.py --skill brainstorming
python3 compare.py results/<before>.json results/<after>.json
```

**Full regression run before any commit:**
```bash
python3 run_evals.py
```

**Cost estimate:** ~10-15 scenarios × 2 API calls each (run + judge) = ~25-30 Claude API calls per full run. At current pricing, roughly $0.10-0.30 per full run.
