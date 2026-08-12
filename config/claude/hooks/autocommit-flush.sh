#!/usr/bin/env bash
# Stop hook: commit everything this session touched under ~/dotfiles as ONE
# commit, then push. Paths come from the ledger that autocommit-record.sh
# appends to on each Write/Edit.
#
# Ordering is the point. This runs after the turn ends, so a deliberate
# `git commit` written during the turn wins — its paths have nothing left to
# commit and are skipped silently, instead of the hook racing ahead and
# leaving the real commit holding scraps.
#
# Commits use explicit pathspecs, so anything else staged in the working tree
# (unrelated work-in-progress) is never swept in.
set -u

LOG="$HOME/.claude/dotfiles-autocommit.log"
stamp() { date -u +%FT%TZ; }

payload=$(cat 2>/dev/null) || payload='{}'
[ -n "$payload" ] || payload='{}'

sid=$(printf '%s' "$payload" | jq -r '.session_id // "nosession"' 2>/dev/null)
[ -n "$sid" ] || sid=nosession

ledger="$HOME/.claude/autocommit-ledger/$sid.paths"
[ -f "$ledger" ] || exit 0

cd "$HOME/dotfiles" 2>/dev/null || exit 0

# Dedupe, keep first-seen order, drop paths that are no longer known to git
# and no longer exist (edited then deleted within the same turn).
paths=()
while IFS= read -r p; do
  [ -n "$p" ] || continue
  for seen in "${paths[@]+"${paths[@]}"}"; do
    [ "$seen" = "$p" ] && continue 2
  done
  if [ -e "$p" ] || git ls-files --error-unmatch -- "$p" >/dev/null 2>&1; then
    paths+=("$p")
  fi
done < "$ledger"

if [ "${#paths[@]}" -eq 0 ]; then
  rm -f "$ledger"
  exit 0
fi

# Stage the recorded paths so new files are known to git before we commit.
for p in "${paths[@]}"; do
  git add -- "$p" 2>/dev/null
done

if git diff --cached --quiet -- "${paths[@]}" 2>/dev/null; then
  echo "[$(stamp)] flush: nothing to commit, ${#paths[@]} path(s) already handled ($sid)" >> "$LOG"
  rm -f "$ledger"
  exit 0
fi

n=${#paths[@]}
if [ "$n" -le 3 ]; then
  subject="dotfiles: update $(IFS=', '; echo "${paths[*]}")"
else
  subject="dotfiles: update $n files (${paths[0]}, ${paths[1]}, +$((n - 2)) more)"
fi

if git commit -q -m "$subject" \
  -m "Automated flush of this session's dotfiles edits. Files were recorded by the PostToolUse hook and committed together when the turn ended." \
  -- "${paths[@]}" 2>>"$LOG"; then
  echo "[$(stamp)] flush: committed $n path(s) ($sid)" >> "$LOG"
  git push origin main 2>>"$LOG" \
    && echo "[$(stamp)] flush: pushed ($sid)" >> "$LOG" \
    || echo "[$(stamp)] flush: push FAILED ($sid)" >> "$LOG"
else
  echo "[$(stamp)] flush: commit FAILED ($sid)" >> "$LOG"
fi

rm -f "$ledger"
exit 0
