---
name: work-sweep-to-bear
description: Use when the user asks to export, save, or send a Work Sweep report to Bear Notes. Do NOT invoke automatically after a sweep — only when explicitly requested.
---

# Work Sweep → Bear Notes Export

Exports the current Work Sweep report to Bear Notes with the correct format, checkboxes, and hashtag handling.

## Steps

1. **Search for an existing note today** using `bear-search-notes` with `term: "Work Sweep"` and `createdAfter: today`. If found, archive it with `bear-archive-note` before creating the new one.

2. **Create the new note** using `bear-create-note` with:
   - `title`: `YYYY-MM-DD Work Sweep` (e.g. `2026-03-10 Work Sweep`)
   - `tags`: `work-sweep`
   - `text`: formatted content (see below)

## Note Format

### Checkboxes everywhere

**Every item in every section gets a Bear checkbox (`- [ ]`).** No exceptions:
- Active Projects → each project is a checkbox
- PRs Awaiting Review → each PR is a checkbox (no table — one checkbox per PR)
- Miscellaneous Follow-Ups → each item is a checkbox
- Priority Order → each entry is a checkbox

Keep the item index numbers alongside the checkboxes:
```
- [ ] **[1] Cross-App Attribution Fix** — description here. **Next:** action. Links: ...
- [ ] **[6] PR `#43564`** — debug code must be removed before merge. [Link](url)
```

### Hashtag handling — critical

Bear interprets `#word` as a tag. Wrap ALL `#` references in backticks to prevent this:
- Channel names: `#team-growth-eng` → `` `#team-growth-eng` ``
- PR numbers: `#43564` → `` `#43564` ``
- Issue numbers: `#GROWTH-646` → leave as-is (contains hyphen, not parsed as tag)

**Exception:** The `#work-sweep` tag at the very end of the note is intentional — do NOT wrap it. This makes Bear tag the note inline.

### Note structure

```
## Active Projects

- [ ] **[1] Project Name** — one-sentence description. Status.
  **Next:** specific action.
  Links: [GROWTH-XXX](url) · [PR `#NNNNN`](url)

- [ ] **[2] Next Project** — ...

---

## PRs Awaiting Your Review

- [ ] **[3]** [`#NNNNN` PR title](url) — Repo · notes on what's needed

---

## Miscellaneous Follow-Ups

- [ ] **[4] Short label** — context. [Slack thread](url)

---

## Priority Order

- [ ] **[1] Merge PR `#NNNNN`** — reason this is top priority.
- [ ] **[6] Review PR `#NNNNN`** — what needs to happen.
...

#work-sweep
```

The `#work-sweep` at the very bottom of the note body is an intentional inline Bear tag — do not backtick it.

## What NOT to do

- Do not use table format for PRs — every item must be a checkbox
- Do not add a `#work-sweep` Bear tag via text AND also skip the `tags` param — use both
- Do not wrap `#work-sweep` at the bottom in backticks
- Do not run this automatically after a sweep — only when the user asks
