#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
CANONICAL_SKILLS_DIR="$DOTFILES_DIR/ai/skills"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.config/opencode/skills"
  "$HOME/.codex/skills"
)

if [[ ! -d "$CANONICAL_SKILLS_DIR" ]]; then
  echo "[ERROR] Canonical skills directory not found: $CANONICAL_SKILLS_DIR"
  exit 1
fi

for target in "${TARGETS[@]}"; do
  parent_dir="$(dirname "$target")"
  backup_path="$parent_dir/skills.backup-$TIMESTAMP"

  mkdir -p "$parent_dir"

  if [[ -L "$target" ]]; then
    rm -f "$target"
  elif [[ -e "$target" ]]; then
    mv "$target" "$backup_path"
    echo "[INFO] Backed up $target -> $backup_path"
  fi

  ln -s "$CANONICAL_SKILLS_DIR" "$target"
  echo "[OK] $target -> $CANONICAL_SKILLS_DIR"
done

# `npx skills add` writes RELATIVE symlinks (../../.agents/skills/<name>). They
# resolve against $CANONICAL_SKILLS_DIR, i.e. $DOTFILES_DIR/.agents/..., which
# does not exist. Every externally-installed skill silently dangles. Rewrite any
# link pointing into .agents as an absolute path so it resolves from anywhere.
relinked=0
dangling=0
for skill in "$CANONICAL_SKILLS_DIR"/*; do
  [[ -L "$skill" ]] || continue
  link_target="$(readlink "$skill")"

  if [[ "$link_target" == *"/.agents/skills/"* && "$link_target" != /* ]]; then
    ln -sfn "$HOME/.agents/skills/$(basename "$link_target")" "$skill"
    relinked=$((relinked + 1))
  fi

  if [[ ! -e "$skill" ]]; then
    echo "[WARN] dangling: $(basename "$skill") -> $(readlink "$skill")"
    dangling=$((dangling + 1))
  fi
done

if (( relinked > 0 )); then
  echo "[OK] Re-linked $relinked relative .agents symlink(s) to absolute paths."
fi
if (( dangling > 0 )); then
  echo "[WARN] $dangling skill symlink(s) still dangle. Re-run the skills CLI install."
fi

echo "[DONE] AI skills symlinks refreshed."
