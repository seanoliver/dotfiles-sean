---
name: mcp-health
description: Use when an MCP server is missing, disconnected, or "not detected" in /mcp; when tools that worked in one Claude Code session are absent in another; when a server appears in one account but not the other; or when confirming which account (work vs personal) is billing the current session.
---

# MCP + Account Health

## Overview

Sean runs two Claude Code accounts selected by `CLAUDE_CONFIG_DIR`:

| Account | Config dir | Config file | Billing |
|---|---|---|---|
| work (default) | `~/.claude` | **`~/.claude.json`** | sean.oliver@supabase.io, Supabase enterprise |
| personal | `~/.claude-personal` | `~/.claude-personal/.claude.json` | helloseanoliver@gmail.com, Max 20x |

`~/dotfiles/config/claude/settings.json` and `~/dotfiles/ai/skills` are symlinked into
both, so settings/skills/hooks/agents/commands are shared. **`.claude.json` is not
shared** — and that file holds MCP server registrations. `claude mcp add` writes only
to whichever account was active, so registrations silently diverge. That divergence is
the cause of nearly every "my MCP server disappeared" report.

## Run the check

**Step 1 — run this immediately. Do not investigate by hand first; the script already
does every check, and hand-investigation reproduces the traps listed below.**

```bash
~/.claude/skills/mcp-health/check.py
```

**Step 2 — if Step 1 reported drift, close it immediately. Do not ask first:**

```bash
~/.claude/skills/mcp-health/check.py --sync
```

Sean has standing approval to sync drift automatically — parity between the two accounts
is always the desired state. `--sync` copies each missing server into the account that
lacks it, then re-checks. It is additive and reversible (`claude mcp remove <name>`); it
never deletes or overwrites an existing registration.

Two things `--sync` deliberately does not do, so say them when reporting:
- Newly added servers do not load until Claude Code restarts.
- HTTP servers still need a one-time `/mcp` OAuth login in the receiving account.

**Step 3 — add flags only when the situation calls for it:**

| Flag | Use when |
|---|---|
| `--sync-plan` | Preview the sync without running it (secrets are redacted) |
| `--expect personal` / `--expect work` | Sean is asking which account is billing |
| `--both` | A server is reportedly missing from *both* accounts (~2 min) |

**Step 4 — report using the Output format section below.**

Exits non-zero if anything is wrong. It covers account/billing identity, registration
drift between accounts, and live per-server status. If the script itself errors, fix the
script — do not fall back to manual probing.

## Interpreting results

| Symptom | Meaning | Fix |
|---|---|---|
| Server missing from one account only | Registration drift | Run `--sync` right away; report what was added |
| `! Needs authentication` | Registered, OAuth not granted **for that account** | `/mcp` in a session on that account; OAuth is per-account and never carries over |
| `✗ Failed to connect` | Server actually broken | Check the command/URL; for local HTTP servers confirm the host is reachable |
| `CLAUDE_ACCOUNT` disagrees with config dir | Cosmetic env var drifted | Ignore the var — `CLAUDE_CONFIG_DIR` alone determines billing |
| Everything missing, unexpected account | Wrong account for this repo | Exit; relaunch with `claude-personal` or `claude` (work) |

## Rules

1. **Read the active config first.** `CLAUDE_CONFIG_DIR` decides everything. Never
   report on `~/.claude.json` without checking whether the session actually uses it.
2. **The work config file is `~/.claude.json`, not `~/.claude/.claude.json`.** The
   default account stores config beside the directory, not inside it.
3. **`claude mcp list` is the only authority on connection status.** Do not curl or
   probe MCP URLs directly to judge health.
4. **Never diagnose from the tool list alone.** A server absent from the session's tools
   means it is not registered *for this account* — not that it is broken or unreachable.
5. **Diff both accounts before concluding anything is broken.** Most reports are drift.
6. **Fix drift with `--sync`, never by hand.** Do not hand-edit `.claude.json` — Claude
   Code rewrites it and edits are lost. Do not hand-write `claude mcp add` commands
   either: `-e/--env` and `-H/--header` are *variadic* and swallow every following
   token, so options placed before the server name silently consume it. The script
   already orders the argv correctly.
7. **Never paste a sync command containing credentials into chat.** Use `--sync` (which
   executes directly) or `--sync-plan` (which redacts). Several servers carry live API
   keys and bearer tokens in `env`/`headers`.

## Why not curl the MCP URL

Claude Code stores OAuth tokens per account and attaches them to MCP requests. A raw
`curl` has no token, so authenticated servers return 401/403 and look broken when they
are fine. During the investigation that produced this skill, raw probes reported
readwise, customerio, and posthog as failing; `claude mcp list` showed all three
Connected. Trust the CLI.

## Output format

Report to Sean in this order, and no more than a few lines each:

1. **Billing** — one line: account, email, and whether it matches expectation.
2. **Drift** — the server names missing from each side, or "none".
3. **Broken** — only servers that genuinely failed to connect, separated from those
   merely needing `/mcp` login.
4. **One next action.** Exactly one, even when several things are wrong.

Do not paste the raw script output. Do not paste sync-plan commands containing secrets
into chat unless Sean asks for them — point at `--sync-plan` instead.

## Out of Scope

- Does not run `claude mcp add`, edit any config, or grant OAuth. It reports and emits
  a plan; Sean executes.
- Does not diagnose bugs *inside* a working MCP server (wrong tool results, bad data).
  That is a normal debugging task.
- Does not manage project-scoped `.mcp.json` files or plugin marketplaces.
- Does not change which account a session uses — that requires relaunching the CLI.
