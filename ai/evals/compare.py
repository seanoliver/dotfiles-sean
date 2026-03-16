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
