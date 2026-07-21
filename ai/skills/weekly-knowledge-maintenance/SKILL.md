---
name: weekly-knowledge-maintenance
description: Use when running the periodic maintenance pass on the Claude Code knowledge system in the ~/supabase hub — pruning memory files, verifying docs, trimming the sessions log, and checking context budget and hooks. Trigger on "weekly knowledge maintenance", "prune my memory", "audit the knowledge system", "kaizen week", "is my memory rotting", or a scheduled maintenance slot.
---

# Weekly Knowledge Maintenance

## Overview

Audit and prune the writable layers of the ~/supabase Claude Code knowledge system so they don't rot. The system map (layers, formats, gotchas) is documented at `~/cortex/wiki/side-projects/active/ai-tooling/claude-code-knowledge-management-system.md` — read it first if you're unfamiliar.

**Core principle:** verify, don't eyeball. Staleness is decided by evaluating each entry's `stale_when` **condition against reality**, and doc claims by **grepping the referenced repo** — never by file age alone. Age is a prompt to check, not a verdict.

**This pass PROPOSES; it does not delete.** Produce a report of proposed actions and get Sean's approval before deleting, migrating, or trimming anything. The only exception is fixing objectively-broken references (dangling links/pointers), which you may fix directly.

## When to use

- The weekly/periodic maintenance slot, or Sean asks to prune/audit the knowledge system.
- After a burst of project work that likely left stale project memories or shipped docs.

**When NOT to use:** mid-task (this is a dedicated pass, not a background chore); to reorganize folder structure or rewrite doc *content* (out of scope — see below).

## Before you start

1. **Read the map doc** (path above) so you know every layer and its caps.
2. **Concurrency lock.** Prevent two runs from double-writing the same week:
   ```bash
   WEEK=$(date +%G-W%V); LOCK="/tmp/km-maint-$WEEK.lock"
   [ -e "$LOCK" ] && echo "Already run this week ($WEEK) — stop unless Sean says re-run" || touch "$LOCK"
   ```

## The pass

Run all five phases. Each ends by adding entries to the report (format below). Use exact paths; `MEM=~/.claude/projects/-Users-seanoliver-supabase/memory`.

### Phase 1 — Memory hygiene

**a. Evaluate `stale_when`, not age.** For every project memory, read its `stale_when` condition and check whether it's now TRUE against real state (Linear, git, PRs, Slack) — verify, don't assume.
```bash
grep -rh 'stale_when' "$MEM"/*.md
```
Flag entries whose condition has fired as **PRUNE** (with the evidence). An old file whose condition is still false is KEEP — age alone is not staleness.

**b. Layering check.** Any `feedback_*` memory that is really a *standing rule true every time* is in the wrong layer — it belongs in `~/.claude/CLAUDE.md` (global) or `~/supabase/CLAUDE.md` (hub). Read each `feedback_*` file; flag misfiled ones as **MIGRATE** (name the target CLAUDE.md).
```bash
ls "$MEM"/feedback_*.md
```

**c. Dangling references.** A deleted memory must leave no pointer behind. Find `MEMORY.md` index lines and `[[wikilinks]]` that point at files which no longer exist:
```bash
# index lines whose target file is missing
grep -oE '\]\(([a-zA-Z0-9_./-]+\.md)\)' "$MEM/MEMORY.md" | sed -E 's/\]\(|\)//g' | while read f; do [ -e "$MEM/$f" ] || echo "DANGLING index -> $f"; done
# wikilinks whose target slug has no matching file
grep -rhoE '\[\[[a-z0-9_-]+' "$MEM"/*.md | sed 's/\[\[//' | sort -u | while read s; do ls "$MEM/$s".md >/dev/null 2>&1 || echo "check wikilink -> [[$s]]"; done
```
Broken references you may fix directly (remove or repoint). Note each fix in the report.

**d. Verify by parse, not bytes.** The auto-memory daemon rewrites files in `$MEM` in the background. After any memory edit, confirm the frontmatter still parses:
```bash
python3 -c "import glob,yaml; [yaml.safe_load(open(f).read().split('---',2)[1]) for f in glob.glob('$MEM/*.md')]" && echo "all frontmatter parses"
```

### Phase 2 — Durable-knowledge verification (docs/)

Actively verify, don't trust. For recent/likely-referenced files in `~/supabase/docs/bugs` and `docs/investigations`, when a doc names a specific file/function/path, grep the repo to confirm it still exists. Flag docs whose central claim references something now gone as **STALE** (needs update or archive note). Also flag exact duplicates (a memory summary + a full docs analysis is intentional, not a duplicate).

### Phase 3 — Context-budget report

Measure what loads every session; don't assert "it's lean" — count it.
```bash
wc -l ~/.claude/CLAUDE.md ~/supabase/CLAUDE.md "$MEM/MEMORY.md"
wc -c "$MEM/MEMORY.md"
```
Flag if `MEMORY.md` approaches its ~200-line / 25KB load cap, or if either CLAUDE.md has grown notably since last pass. Bloat here is silent — entries past the cap drop with no warning.

### Phase 4 — Sessions-log pruning

`$MEM/sessions.md` is the **one place** the log is trimmed. Keep roughly the trailing week of entries (below the `<!-- ENTRIES BELOW -->` marker); older entries whose Unfinished items are all closed can be dropped. Propose the cut in the report; trim only on approval.

### Phase 5 — Hook & skill health

```bash
for h in ~/supabase/.claude/hooks/*.sh; do bash -n "$h" && echo "ok: $h" || echo "SYNTAX: $h"; done
jq -e '.hooks' ~/supabase/.claude/settings.json >/dev/null && echo "settings.json valid" || echo "settings.json BROKEN"
```
Flag: hook scripts referenced in settings that don't exist (or vice-versa), dangling skill symlinks (run `~/dotfiles/scripts/link-ai-skills.sh` if any are broken — see the symlink gotcha memory), and any manual work done 2+ times this week that should become a skill (log to `~/dotfiles/ai/SKILL_BACKLOG.md`, don't build it now).

## Output format

Produce one report, exactly these sections. Every proposed action tagged and one line of rationale + evidence. Nothing gets acted on until Sean approves (except broken-reference fixes, which you list as already-done).

```
# Knowledge Maintenance — <YYYY-Www>

## Fixed directly (broken references only)
- <what> — <before → after>

## Proposed actions (await approval)
| Tag | Target | Rationale (evidence) |
|-----|--------|----------------------|
| PRUNE | project_x.md | stale_when fired: <condition> is now true (<evidence>) |
| MIGRATE | feedback_y.md → hub CLAUDE.md | standing rule, not an expiring fact |
| UPDATE | docs/....md | references deleted fn `foo()` (grep: 0 hits) |
| TRIM | sessions.md | 6 entries older than 1wk, all Unfinished closed |

## Context budget
- global CLAUDE.md: N lines · hub CLAUDE.md: N lines · MEMORY.md: N lines / N KB (cap ~200/25KB)

## Health
- hooks: ok/flags · settings.json: valid · symlinks: ok/repaired · skill-backlog additions: <list>

## Nothing-to-do
- <layers that were clean>
```

## Common mistakes

| Mistake | Correct |
|---------|---------|
| Flagging entries stale by age | Evaluate the `stale_when` condition against real state |
| "Memory looks lean" with no numbers | Run `wc`; report actual counts vs caps |
| Skipping the feedback→CLAUDE.md check | It's the highest-value hygiene step; do it every pass |
| Trusting a doc's named file still exists | Grep the repo to confirm before trusting the claim |
| Deleting/migrating without asking | Propose in the report; act only on approval |
| Auto-deleting a zero-usage entry | Rare-but-expensive entries should sleep; judge, don't auto-delete |

## Out of Scope

This skill audits and prunes the existing layers. It does NOT:
- Reorganize folder structure (subdividing `docs/`, adding `_archive/`) — propose separately if warranted, don't do it here.
- Rewrite the *content* of docs, memories, or CLAUDE.md — only flag for update.
- Promote investigations to Greenfield Playbooks — surface candidates, leave the call to Sean.
- Decide project status (shipped/dropped) on Sean's behalf — if a `stale_when` needs Sean's knowledge to evaluate, ask; don't guess.
- Build new skills — log candidates to the backlog per `~/.claude/CLAUDE.md`.
