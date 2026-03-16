#!/usr/bin/env python3
"""
Skill eval runner — tests whether Claude skills trigger and are followed correctly.
Uses the `claude` CLI (Claude Code) for all API calls — no ANTHROPIC_API_KEY needed.
Usage: python run_evals.py [--skill brainstorming] [--verbose]
"""

import subprocess
import yaml
import json
import argparse
from datetime import datetime
from pathlib import Path

PASS_THRESHOLD = 7  # score >= 7 is a pass
EVAL_MODEL = "haiku"  # fast + cheap for eval runs; override with --model flag


def call_claude(prompt: str, system_prompt: str | None = None, model: str | None = None) -> str:
    """Call claude -p and return the text response. Uses Claude Code auth — no API key needed."""
    cmd = [
        "claude", "-p",
        "--output-format", "json",
        "--allowed-tools", "Skill",  # allow skill invocation only; no Bash/Edit/Write side effects
        "--model", model or EVAL_MODEL,
        "--strict-mcp-config",       # no --mcp-config means zero MCP servers loaded (fast startup)
    ]
    if system_prompt:
        cmd += ["--system-prompt", system_prompt]
    cmd += ["--", prompt]  # -- terminates option parsing so prompt isn't consumed by --allowed-tools

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if result.returncode != 0:
        raise RuntimeError(f"claude CLI error: {result.stderr.strip()}")

    # JSON output is an array of events; find the last result event
    events = json.loads(result.stdout)
    for event in reversed(events):
        if event.get("type") == "result":
            return event["result"]

    raise RuntimeError("No result event in claude CLI output")


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
    """Run a single scenario and return the agent's response."""
    return call_claude(
        prompt=scenario["prompt"],
        system_prompt=build_system_prompt(skill_names),
    )


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

    raw = call_claude(judge_prompt)
    # Strip markdown code fences if present
    raw = raw.strip()
    if raw.startswith("```"):
        raw = "\n".join(raw.split("\n")[1:])
        raw = raw.rstrip("`").strip()
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
