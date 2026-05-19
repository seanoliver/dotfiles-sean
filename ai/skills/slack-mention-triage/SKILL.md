---
name: slack-mention-triage
description: Use when the user shares a Slack thread URL where they were @-mentioned and asks "what should I do with this?", "do I need to act on this?", "am I on the hook here?", "summarize this thread", or pastes a Slack URL with no other context. Also use when the user is overwhelmed by a long thread and wants ambient awareness before deciding whether to engage. Do NOT use for Gmail (use inbox-triage), multi-tool sweeps (use work-sweep), or drafting the actual reply (use message-crafter).
allowed-tools: mcp__claude_ai_Slack__slack_read_thread, mcp__claude_ai_Slack__slack_read_channel, mcp__claude_ai_Slack__slack_search_users
---

# Slack Mention Triage

The user has been @-mentioned in a Slack thread and wants to know what it's about and whether they need to act — without reading 15 replies themselves. Long threads have a real opportunity cost; the user shared the URL specifically because they don't want to pay it.

## The core insight

**A "not yours" or "FYI-only" verdict is not permission to skip the summary.** The user wants ambient awareness of what the thread is about even when no action is required. Summary always comes first, regardless of verdict.

## Phase 1: Read the thread

Parse the Slack URL. Format:
```
https://[workspace].slack.com/archives/[CHANNEL_ID]/p[TIMESTAMP]?thread_ts=[PARENT_TS]&cid=[CHANNEL_ID]
```

- `channel_id` is in the path after `/archives/`
- If a `thread_ts` query param exists, use it as `message_ts` (this is the parent of the thread the user is pointing to)
- If no `thread_ts`, convert the path timestamp: strip `p` prefix, insert `.` before last 6 digits (`p1779177748931669` → `1779177748.931669`)

Call `mcp__claude_ai_Slack__slack_read_thread` with the resolved channel_id and message_ts. **Read the full thread before producing any output.** If the thread links to other Slack threads with substantive content, follow them too.

## Phase 2: Analyze

Identify, in order:

1. **The user's @-mentions** — Where in the thread? In the parent or buried in a reply? Asked a direct question, assigned a task, or CC'd for visibility?
2. **Active in-thread work** — Who else is actively executing right now (e.g., teammate fixing the issue live, someone organizing a call)? That work is not in the user's lane.
3. **Assigned future work** — Did anyone say "we'll work with [user]" or assign a follow-up? Note the assignment but don't treat it as the immediate next action.
4. **The substantive question** — What's the actual thing being discussed, separate from operational chatter? The interesting question is often buried.

## Phase 3: Output (required format)

Use this exact structure, in this exact order:

```
**Summary:** [1–3 sentences. What the thread is about, who's driving, current state. ALWAYS include — never skip even when verdict is "not yours" or "FYI-only". Capture the arc, not just the parent message.]

**Verdict:** [yours | partial | FYI-only | not yours] — [1 line justification with the specific @-mention context]

**Next action:** [exactly one concrete thing, OR "none — file it" if FYI-only]
```

If a reply is needed, end with one line: `Want me to draft via message-crafter, or are you good?` Do not draft the reply yourself.

Length budget: ~10–15 lines total. Long threads still get short triage.

## Verdict definitions

| Verdict | Meaning |
|---------|---------|
| **Yours** | Direct ask requiring response or action from the user; no one else is on it |
| **Partial** | User is one of several owners; action exists but parallel work is happening |
| **FYI-only** | Tagged for visibility but not on the hook; informational |
| **Not yours** | Tag was incidental, in error, or the work has already moved on |

## Out of Scope

This skill does NOT:
- Draft the actual reply — hand off to `message-crafter` after triage
- Sweep multiple Slack threads or other tools — that's `work-sweep`
- Triage Gmail — that's `inbox-triage`
- Decide whether assigned future work is worth doing — surface the assignment, let the user judge
- Act on the thread (send a message, add reactions, mark unread)
- Summarize threads the user posted themselves and is monitoring (no @-mention triage needed)

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Skipping summary when verdict is "not yours" or "FYI-only" | Summary is ALWAYS first, regardless of verdict. The user wants ambient awareness. |
| Giving a menu of next actions | Exactly one. Park the rest in the summary if they matter. |
| Restating the parent message as the summary | Capture the arc — what's been resolved, what's open, where the energy is going |
| Outputting verdict before summary | Order is fixed: summary → verdict → action |
| Drafting the reply inline | Hand off to `message-crafter`. This skill stops at "want me to draft?" |
| Reading only the first few replies | Read the whole thread. Long threads often resolve at the end and change the triage. |
| Treating "we'll work with you on this" as the immediate next action | That's future-assigned work. Surface it in the summary, then identify the minimum reply (often "I'm in" or no reply at all). |

## Red flags — start over

- Output starts with verdict instead of summary
- Summary is a paraphrase of the @-mention message rather than the thread's arc
- Two or more "next actions"
- Drafted a reply inline instead of handing off
- Verdict given without naming where in the thread the user was @-mentioned

## Real-world failure that motivated this skill

2026-05-19, Scope/AEO thread. First-pass triage gave a correct verdict and one next action but skipped the summary entirely, on the implicit rationalization "Sean shared the URL so he must know what it's about." The user explicitly corrected: he shared it *because* he didn't want to read it. Summary-first is the fix.
