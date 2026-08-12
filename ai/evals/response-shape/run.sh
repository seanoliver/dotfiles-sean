#!/usr/bin/env bash
# Measure whether Cortex's replies obey the countable rules in SOUL.md.
#
#   ./run.sh                 # tag "run", 3 reps per case
#   REPS=5 ./run.sh nightly  # more reps = tighter rate
#   MODEL=opus ./run.sh o    # different model
#
# Each rep is a fresh headless session, so SOUL.md loads through the normal
# SessionStart hook. Reps run in parallel; a rule that fires intermittently shows
# up as 2/3 instead of hiding behind a single PASS.
#
# `claude` is an interactive shell alias on this machine, so the binary is
# addressed by path. Override with CLAUDE_BIN if it moves.
set -eu
cd "$(dirname "$0")"
TAG="${1:-run}"; MODEL="${MODEL:-sonnet}"; REPS="${REPS:-3}"; PAR="${PAR:-6}"
CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
[ -x "$CLAUDE_BIN" ] || { echo "no claude binary at $CLAUDE_BIN" >&2; exit 1; }
OUT="out/$TAG"; rm -rf "$OUT"; mkdir -p "$OUT"

running=0
scored="$OUT/.scored"; : > "$scored"

while IFS=$'\t' read -r name tag prompt; do
  [ -z "${name:-}" ] && continue
  case "$prompt" in @*) prompt="$(cat "${prompt#@}")" ;; esac
  for i in $(seq 1 "$REPS"); do
    dest="$OUT/$i-$name.txt"
    "$CLAUDE_BIN" -p "$prompt" --model "$MODEL" < /dev/null > "$dest" 2>&1 &
    printf '%s::%s\n' "$dest" "$tag" >> "$scored"
    running=$((running + 1))
    if [ "$running" -ge "$PAR" ]; then wait; running=0; fi
  done
done < cases.tsv
wait

# shellcheck disable=SC2046
python3 score.py $(sort "$scored")
