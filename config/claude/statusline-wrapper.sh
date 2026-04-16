#!/bin/bash
# Custom Claude Code statusline.
# Line 1: [account] [repo/subpath@branch*] [↑ahead↓behind] [≡stash] [⎇worktree]
# Line 2: Model · <bar> <pct>% · <tokens> · ⏱ <duration> [· 5h:X% · 7d:Y%]
ACCOUNT="${CLAUDE_ACCOUNT:-work}"
INPUT=$(cat)

export CLAUDE_ACCOUNT="$ACCOUNT"
export CLAUDE_STATUSLINE_INPUT="$INPUT"
# Uncomment to debug: dump raw input + env on each refresh
# echo "$INPUT" > /tmp/claude-statusline-last.json 2>/dev/null
# env | sort > /tmp/claude-statusline-env.txt 2>/dev/null

python3 - <<'PY'
import json, os, subprocess, datetime

# --- ANSI helpers -----------------------------------------------------------
RESET   = "\033[0m"
DIM     = "\033[2m"
BOLD    = "\033[1m"
CYAN    = "\033[36m"
YELLOW  = "\033[33m"
GREEN   = "\033[32m"
RED     = "\033[31m"
MAGENTA = "\033[35m"
BLUE    = "\033[34m"

def c(code, s): return f"{code}{s}{RESET}"

# --- Inputs -----------------------------------------------------------------
account = os.environ.get("CLAUDE_ACCOUNT", "work")
raw     = os.environ.get("CLAUDE_STATUSLINE_INPUT", "")
try:
    data = json.loads(raw) if raw.strip() else {}
except Exception:
    data = {}

ws              = data.get("workspace", {}) or {}
cwd             = ws.get("current_dir") or data.get("cwd") or os.getcwd()
model           = (data.get("model", {}) or {}).get("display_name") \
                    or (data.get("model", {}) or {}).get("id") or "Claude"
ctx             = data.get("context_window", {}) or {}
usage           = ctx.get("current_usage", {}) or {}
ctx_size        = ctx.get("context_window_size") or 0
used_pct        = ctx.get("used_percentage")  # authoritative, matches /context
transcript_path = data.get("transcript_path") or ""
rate_limits     = data.get("rate_limits", {}) or {}
cost            = data.get("cost", {}) or {}

# --- Git helpers ------------------------------------------------------------
def git(*args):
    try:
        return subprocess.check_output(("git", "-C", cwd) + args,
                                       stderr=subprocess.DEVNULL, text=True).strip()
    except Exception:
        return ""

repo_root = git("rev-parse", "--show-toplevel")
location_segments = []

if repo_root:
    repo_name = os.path.basename(repo_root)
    branch    = git("symbolic-ref", "--short", "HEAD") or git("rev-parse", "--short", "HEAD") or "?"
    subpath   = "/" + os.path.relpath(cwd, repo_root) if cwd != repo_root else ""
    dirty     = "*" if git("status", "--porcelain") else ""
    location_segments.append(c(YELLOW, f"[{repo_name}{subpath}@{branch}{dirty}]"))

    # ahead / behind upstream
    ab = git("rev-list", "--left-right", "--count", "@{upstream}...HEAD")
    if ab:
        try:
            behind, ahead = (int(x) for x in ab.split())
            if ahead or behind:
                parts = []
                if ahead:  parts.append(c(GREEN, f"↑{ahead}"))
                if behind: parts.append(c(RED,   f"↓{behind}"))
                location_segments.append("".join(parts))
        except Exception:
            pass

    # stash count
    stash = git("stash", "list")
    stash_count = len([l for l in stash.splitlines() if l.strip()])
    if stash_count:
        location_segments.append(c(MAGENTA, f"≡{stash_count}"))

    # worktree indicator (only when in a linked worktree, not main checkout)
    git_dir = git("rev-parse", "--git-dir")
    if git_dir and "/worktrees/" in git_dir:
        worktree_name = os.path.basename(git_dir.rstrip("/"))
        location_segments.append(c(BLUE, f"⎇{worktree_name}"))
else:
    location_segments.append(c(DIM, f"[{os.path.basename(cwd) or cwd}]"))

# --- Account ----------------------------------------------------------------
acct_color = MAGENTA if account == "personal" else CYAN
account_str = c(acct_color, f"[{account}]")

# --- Context usage ----------------------------------------------------------
total_tokens = (
    (usage.get("input_tokens") or 0)
    + (usage.get("output_tokens") or 0)
    + (usage.get("cache_creation_input_tokens") or 0)
    + (usage.get("cache_read_input_tokens") or 0)
)

def fmt_tokens(n):
    if n >= 1_000_000: return f"{n/1_000_000:.1f}M".replace(".0M", "M")
    if n >= 1_000:     return f"{n/1000:.0f}k"
    return str(n)

pct = int(used_pct) if used_pct is not None else 0

bar_len = 10
filled  = round(bar_len * pct / 100)
bar     = "█" * filled + "░" * (bar_len - filled)
if pct >= 90:   bar_col = RED
elif pct >= 70: bar_col = YELLOW
else:           bar_col = GREEN

pct_col  = bar_col
tokens_str = c(DIM, f"{fmt_tokens(total_tokens)}/{fmt_tokens(ctx_size) if ctx_size else '?'}")

# --- Session duration -------------------------------------------------------
duration_str = ""
if transcript_path and os.path.exists(transcript_path):
    try:
        with open(transcript_path, "r") as f:
            first_line = f.readline()
        if first_line:
            first = json.loads(first_line)
            ts = first.get("timestamp")
            if ts:
                start = datetime.datetime.fromisoformat(ts.replace("Z", "+00:00"))
                delta = datetime.datetime.now(datetime.timezone.utc) - start
                mins = int(delta.total_seconds() // 60)
                if mins < 1:    dur = "<1m"
                elif mins < 60: dur = f"{mins}m"
                else:           dur = f"{mins//60}h {mins%60}m"
                duration_str = c(DIM, f"⏱ {dur}")
    except Exception:
        pass

# --- Rate limits (shown when notable) --------------------------------------
def fmt_pct(p):
    """Round to 1 decimal, strip trailing .0 (7.03 -> '7', 7.25 -> '7.3')."""
    r = round(float(p), 1)
    s = f"{r:.1f}"
    return s[:-2] if s.endswith(".0") else s

def rate_segment(label, block):
    p = (block or {}).get("used_percentage")
    if p is None:
        return None
    p_f = float(p)
    if   p_f >= 80: color = RED
    elif p_f >= 50: color = YELLOW
    else:           color = GREEN
    seg_bar_len = 5
    filled = round(seg_bar_len * p_f / 100)
    seg_bar = "█" * filled + "░" * (seg_bar_len - filled)
    return c(color, f"{label} {seg_bar} {fmt_pct(p)}%")

rate_parts = [s for s in (
    rate_segment("5h", rate_limits.get("five_hour")),
    rate_segment("7d", rate_limits.get("seven_day")),
) if s]

# --- Cost (work account only — enterprise API billing) ---------------------
cost_part = None
if account == "work":
    usd = cost.get("total_cost_usd")
    if usd is not None:
        if   usd >= 10: cost_col = RED
        elif usd >= 1:  cost_col = YELLOW
        else:           cost_col = GREEN
        cost_part = c(cost_col, f"${usd:.2f}")

# --- Compose ----------------------------------------------------------------
sep = c(DIM, "·")
line1 = " ".join([account_str] + location_segments)
line2_parts = [c(CYAN, model), c(bar_col, bar), c(pct_col, f"{pct}%"), tokens_str]
if duration_str: line2_parts.append(duration_str)
line2_parts.extend(rate_parts)
if cost_part: line2_parts.append(cost_part)
line2 = f" {sep} ".join(line2_parts)

print(line1)
print(line2)
PY
