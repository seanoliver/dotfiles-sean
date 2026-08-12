#!/usr/bin/env bash
# PostToolUse(Write|Edit): record an edited ~/dotfiles path in this session's
# autocommit ledger. Deliberately does NO git work — the Stop hook
# (autocommit-flush.sh) turns the ledger into one commit per turn.
#
# Why the split: the previous version of this hook ran `git commit && git push`
# inline on every single edit. Two consequences, both bad. A three-edit change
# became three commits titled "dotfiles: auto-commit <path>", so 58 of 60
# commits in one week carried no information. And because PostToolUse fires
# mid-turn, it raced any deliberate commit the agent was about to write — the
# agent's commit ended up holding only the leftovers.
#
# Guards preserved from the original: dotfiles-only, and a secret-pattern
# skip list that logs and bails.
set -u

LOG="$HOME/.claude/dotfiles-autocommit.log"
LEDGER_DIR="$HOME/.claude/autocommit-ledger"

payload=$(cat)
[ -n "$payload" ] || exit 0

f=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$f" ] || exit 0

sid=$(printf '%s' "$payload" | jq -r '.session_id // "nosession"' 2>/dev/null)
[ -n "$sid" ] || sid=nosession

real=$(readlink -f "$f" 2>/dev/null)
[ -n "$real" ] || exit 0

case "$real" in
  "$HOME/dotfiles/"*) ;;
  *) exit 0 ;;
esac
rel="${real#$HOME/dotfiles/}"

case "$rel" in
  *.env|*.env.*|.env|.env.*|*secret*|*Secret*|*SECRET*|*token*|*Token*|*TOKEN*|\
*credentials*|*Credentials*|*CREDENTIALS*|*password*|*Password*|*PASSWORD*|\
*.pem|*.PEM|*.key|*.KEY|*.p12|*.pfx|\
private/*|*/private/*|.private/*|*/.private/*|.aws/*|*/.aws/*|.ssh/*|*/.ssh/*)
    echo "[$(date -u +%FT%TZ)] skip-secret-pattern: $rel" >> "$LOG"
    exit 0 ;;
esac

mkdir -p "$LEDGER_DIR" 2>/dev/null || exit 0
printf '%s\n' "$rel" >> "$LEDGER_DIR/$sid.paths"
echo "[$(date -u +%FT%TZ)] record: $rel ($sid)" >> "$LOG"
exit 0
