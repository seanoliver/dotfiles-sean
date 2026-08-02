#!/usr/bin/env python3
"""MCP + account health check for Sean's two-account Claude Code setup.

Authoritative source of truth is `claude mcp list` (it holds OAuth tokens);
raw HTTP probes of MCP URLs give false "needs auth" results and are never used.

Usage:
  ./check.py                 # active account: identity, billing, live server health, config drift
  ./check.py --both          # additionally run live health for the OTHER account (slow, ~2min)
  ./check.py --expect personal|work
  ./check.py --sync-plan     # print the exact commands to close MCP registration drift
"""
import argparse
import json
import os
import re
import subprocess
import sys

HOME = os.path.expanduser("~")
ACCOUNTS = {"work": os.path.join(HOME, ".claude"),
            "personal": os.path.join(HOME, ".claude-personal")}

GREEN, YELLOW, RED, DIM, BOLD, OFF = (
    "\033[32m", "\033[33m", "\033[31m", "\033[2m", "\033[1m", "\033[0m")

problems: list[str] = []


def hdr(text):
    print(f"\n{BOLD}{text}{OFF}")


def flag(msg):
    problems.append(msg)
    return f"{RED}{msg}{OFF}"


def config_path(config_dir):
    """The default (work) account keeps its config at ~/.claude.json, NOT inside
    ~/.claude/. Only an explicit CLAUDE_CONFIG_DIR nests it as <dir>/.claude.json."""
    if os.path.realpath(config_dir) == os.path.realpath(os.path.join(HOME, ".claude")):
        return os.path.join(HOME, ".claude.json")
    return os.path.join(config_dir, ".claude.json")


def load(config_dir):
    try:
        with open(config_path(config_dir)) as f:
            return json.load(f)
    except Exception as e:
        print(f"  {RED}cannot read {config_path(config_dir)}: {e}{OFF}")
        return None


def active_config_dir():
    """The dir Claude Code is actually using right now."""
    return os.environ.get("CLAUDE_CONFIG_DIR") or os.path.join(HOME, ".claude")


def account_name_for(config_dir):
    real = os.path.realpath(config_dir)
    for name, path in ACCOUNTS.items():
        if os.path.realpath(path) == real:
            return name
    return None


# ---------------------------------------------------------------- identity

def report_identity(expect):
    hdr("1. Account and billing")
    cfg_dir = active_config_dir()
    name = account_name_for(cfg_dir)
    d = load(cfg_dir)
    if d is None:
        return name

    acct = d.get("oauthAccount") or {}
    email = acct.get("emailAddress", "<none>")
    print(f"  config dir        {cfg_dir}"
          + ("" if os.environ.get("CLAUDE_CONFIG_DIR") else f"  {DIM}(default, CLAUDE_CONFIG_DIR unset){OFF}"))
    print(f"  resolves to       {name or flag('UNKNOWN account dir')}")
    print(f"  logged in as      {email}")
    print(f"  organization      {acct.get('organizationName')} ({acct.get('organizationType')})")
    print(f"  billing type      {acct.get('billingType')}")
    print(f"  seat / rate tier  {acct.get('seatTier')} / "
          f"{acct.get('organizationRateLimitTier') or acct.get('userRateLimitTier')}")

    if not acct.get("oauthAccount") and not email:
        print("  " + flag("no oauthAccount in config - session is not logged in"))

    env_acct = os.environ.get("CLAUDE_ACCOUNT")
    if env_acct and name and env_acct != name:
        print("  " + flag(
            f"CLAUDE_ACCOUNT={env_acct} but config dir is the {name} account. "
            "The env var is cosmetic; CLAUDE_CONFIG_DIR decides billing. Billing follows "
            f"{name}."))
    elif env_acct:
        print(f"  CLAUDE_ACCOUNT    {env_acct} {GREEN}(agrees with config dir){OFF}")

    if expect and name != expect:
        print("  " + flag(f"expected the {expect} account, but this session bills to {name}"))
    elif expect:
        print(f"  {GREEN}billing confirmed: {expect}{OFF}")

    return name


# ------------------------------------------------------------ registration

def globals_of(config_dir):
    d = load(config_dir)
    return set((d or {}).get("mcpServers", {}).keys())


def report_drift(sync_plan):
    hdr("2. MCP registration drift between accounts")
    work, personal = globals_of(ACCOUNTS["work"]), globals_of(ACCOUNTS["personal"])
    both = work & personal
    only_work = sorted(work - personal)
    only_personal = sorted(personal - work)

    print(f"  work global servers      {len(work)}")
    print(f"  personal global servers  {len(personal)}")
    print(f"  present in both          {len(both)}")

    if not only_work and not only_personal:
        print(f"  {GREEN}no drift - both accounts register the same servers{OFF}")
        return
    if only_work:
        print("  " + flag(f"missing from personal ({len(only_work)}): {', '.join(only_work)}"))
    if only_personal:
        print("  " + flag(f"missing from work ({len(only_personal)}): {', '.join(only_personal)}"))
    print(f"\n  {DIM}Cause: MCP servers are registered in <config-dir>/.claude.json, which is the one"
          f"\n  file NOT shared between accounts. `claude mcp add` only writes to the account that"
          f"\n  was active at the time.{OFF}")
    if sync_plan:
        emit_sync_plan(only_work, only_personal)
    else:
        print(f"  {DIM}Re-run with --sync-plan to get the commands that close this gap.{OFF}")


def emit_sync_plan(only_work, only_personal):
    print(f"\n{BOLD}  Sync plan{OFF}  {DIM}(review, then paste; add -s user to scope globally){OFF}")
    for missing, src, dst_dir in ((only_work, "work", ACCOUNTS["personal"]),
                                  (only_personal, "personal", ACCOUNTS["work"])):
        if not missing:
            continue
        src_dir = ACCOUNTS[src]
        d = load(src_dir) or {}
        dst = "personal" if src == "work" else "work"
        print(f"\n  {DIM}# copy {src} -> {dst}{OFF}")
        for n in missing:
            cfg = d["mcpServers"][n]
            env_prefix = (f'CLAUDE_CONFIG_DIR={dst_dir} ' if dst == "personal" else '')
            if cfg.get("type") == "http":
                hdrs = " ".join(f'--header "{k}: {v}"' for k, v in (cfg.get("headers") or {}).items())
                print(f'  {env_prefix}claude mcp add --scope user --transport http {n} "{cfg["url"]}" {hdrs}'.rstrip())
            else:
                envs = " ".join(f'--env {k}="{v}"' for k, v in (cfg.get("env") or {}).items())
                args = " ".join(f'"{a}"' for a in cfg.get("args", []))
                print(f'  {env_prefix}claude mcp add --scope user {envs} {n} -- "{cfg["command"]}" {args}'.strip())
    print(f"\n  {DIM}HTTP servers needing OAuth must be authorized once per account via /mcp.{OFF}")


# ------------------------------------------------------------ live health

def parse_status_line(line):
    """`claude mcp list` emits `<name>: <target> - <status>`. Names may themselves
    contain colons (plugin:github:github), so split on the first ': ' (colon+space)
    and take the status after the LAST ' - '."""
    if ": " not in line or " - " not in line:
        return None
    name, rest = line.split(": ", 1)
    _, status = rest.rsplit(" - ", 1)
    if not status[:1] in "✔✗!":
        return None
    return name, status


def live_health(config_dir, label):
    env = {k: v for k, v in os.environ.items()
           if k not in ("CLAUDECODE", "CLAUDE_CODE_SESSION_ID", "CLAUDE_CODE_CHILD_SESSION",
                        "CLAUDE_CODE_ENTRYPOINT", "CLAUDE_CODE_OAUTH_TOKEN")}
    if config_dir == os.path.join(HOME, ".claude"):
        env.pop("CLAUDE_CONFIG_DIR", None)
    else:
        env["CLAUDE_CONFIG_DIR"] = config_dir

    try:
        p = subprocess.run(["claude", "mcp", "list"], capture_output=True, text=True,
                           timeout=300, env=env, cwd=HOME)
    except subprocess.TimeoutExpired:
        print(f"  {flag(f'{label}: `claude mcp list` timed out after 5min')}")
        return
    except FileNotFoundError:
        print(f"  {flag('`claude` not on PATH')}")
        return

    ok, auth, fail = [], [], []
    for line in p.stdout.splitlines():
        m = STATUS_RE.match(line.strip())
        if not m:
            continue
        n, s = m["name"], m["status"]
        (ok if "✔" in s else auth if "!" in s else fail).append(n)

    print(f"  {label}: {GREEN}{len(ok)} connected{OFF}, "
          f"{YELLOW}{len(auth)} need auth{OFF}, {RED}{len(fail)} failed{OFF}")
    if auth:
        print(f"    {YELLOW}needs /mcp login:{OFF} {', '.join(sorted(auth))}")
    if fail:
        print("    " + flag(f"{label} failed to connect: {', '.join(sorted(fail))}"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--both", action="store_true", help="also health-check the other account (slow)")
    ap.add_argument("--expect", choices=["personal", "work"], help="assert which account should be billing")
    ap.add_argument("--sync-plan", action="store_true", help="print commands to close registration drift")
    a = ap.parse_args()

    print(f"{BOLD}MCP + account health{OFF}  {DIM}cwd={os.getcwd()}{OFF}")
    active = report_identity(a.expect)
    report_drift(a.sync_plan)

    hdr("3. Live server health  (authoritative: `claude mcp list`)")
    targets = [(active, active_config_dir())] if active else []
    if a.both:
        other = "personal" if active == "work" else "work"
        targets.append((other, ACCOUNTS[other]))
    if not targets:
        print("  " + flag("could not identify the active account; skipping"))
    for label, cfg_dir in targets:
        live_health(cfg_dir, label)
    if not a.both:
        print(f"  {DIM}Only the active account was probed. Use --both to check the other.{OFF}")

    hdr("Summary")
    if problems:
        for p in problems:
            print(f"  {RED}x{OFF} {p}")
        sys.exit(1)
    print(f"  {GREEN}All checks passed.{OFF}")


if __name__ == "__main__":
    main()
