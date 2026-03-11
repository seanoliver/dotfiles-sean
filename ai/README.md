# AI Skills Setup

This repository uses one shared skills directory for Claude Code, OpenCode, and Codex CLI.

## Canonical skills path

- `~/dotfiles/ai/skills`

All three client-specific skill directories should be symlinks to this path:

- `~/.claude/skills`
- `~/.config/opencode/skills`
- `~/.codex/skills`

## Refresh symlinks

Run:

```bash
~/dotfiles/scripts/link-ai-skills.sh
```

The script creates timestamped backups before replacing non-symlink directories.

You only need to run this script when:

- setting up a new machine,
- repairing broken/missing symlinks,
- or changing the canonical skills directory path.

If the symlinks already exist and you `git pull` new skill changes into `~/dotfiles`, you do not need to run the script again. The CLIs will see the updated skill files through the existing symlinks.

## Daily workflow

1. Add or edit skills in `~/dotfiles/ai/skills`.
2. Commit and push changes in the `~/dotfiles` repo.
3. Pull on other machines.
4. Run `~/dotfiles/scripts/link-ai-skills.sh` only if this is the first setup on that machine or the symlinks are missing.

## Backups created during migration

Initial migration backups were created with timestamp `20260311-090111`:

- `~/.claude/skills.backup-20260311-090111`
- `~/.config/opencode/skills.backup-20260311-090111`
- `~/.codex/skills.backup-20260311-090111`

These can be used for rollback if needed.
