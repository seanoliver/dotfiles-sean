---
name: inbox-triage
description: Use when the user wants to triage their Gmail inbox, clear out emails, do an inbox review, or get to inbox zero. Trigger on phrases like "check my email", "triage my inbox", "what's in my inbox", "help me get to inbox zero", "clean up my email", "go through my emails", or any request to review, categorize, or process Gmail messages.
---

# Inbox Triage

Daily inbox triage that fetches ALL messages in the inbox, categorizes them, flags items needing attention, and offers to bulk-archive the noise.

## Configuration

- **Email:** `helloseanoliver@gmail.com`
- **MCP tools:** `mcp__google_workspace__search_gmail_messages`, `mcp__google_workspace__get_gmail_messages_content_batch`, `mcp__google_workspace__batch_modify_gmail_message_labels`
- **User practice:** Inbox zero. Anything left in inbox is intentionally there because it needs follow-up.

## Phase 1: Fetch ALL Inbox Messages

**CRITICAL: Paginate until exhausted.** Do not stop at the first page. The user's oldest emails are often the most important (personal messages waiting for reply).

```
1. Search: in:inbox (page_size=25)
2. Collect all message IDs
3. If next_page_token exists, fetch next page
4. Repeat until no more pages
5. Report total count to user: "Found N messages in your inbox. Fetching details..."
```

**Fetch metadata in batches of 12** (not 25 — avoids Gmail's concurrent request rate limit which throttles at ~10-15 simultaneous requests per user). Use `format: "metadata"` to keep it fast.

If any messages hit rate limits (429 errors), collect the failed IDs and retry them in a separate smaller batch after the initial pass completes.

## Phase 2: Categorize

Read every subject line and sender. Categorize into these buckets, in this priority order:

### 1. Needs Attention (highest priority)
Personal emails from real people that may need a reply or action. Look for:
- Direct messages from individuals (not companies/services)
- Emails where someone is waiting on the user (follow-ups, "checking in", "tried to reach you")
- Financial/legal items (401k, insurance, tax documents)
- Calendar invitations requiring a response
- Threads with multiple replies (indicates active conversation)
- Emails older than 2 weeks from real people (likely forgotten)

**For each item, write 1-2 sentences about what it looks like and ask the user a specific question** (e.g., "Did you ever respond to this?" or "Is this still active?").

### 2. Receipts & Transactions
Purchase confirmations, payment receipts, subscription charges, shipping notifications. Keep for records but no action needed.

### 3. Newsletters Worth a Skim
Substantive content from newsletters the user subscribes to (Substack, tech newsletters, industry content). Not promotional — actual articles/essays.

### 4. Safe to Archive (lowest priority)
- Marketing/promotional emails from companies
- Automated alerts (crime radar, weather, daily digests)
- Job alert emails (LinkedIn, etc.)
- Product update emails from SaaS tools
- Expired offers or past-date event promotions
- Calendar notifications that are purely informational (updates, cancellations from Google Calendar)

## Phase 3: Present Results

Format as a structured report:

```markdown
### Needs Attention
[Numbered list with From, Subject, Date, and your specific question]

### Receipts & Transactions
[Table: From | Subject]

### Newsletters Worth a Skim
[Table: From | Subject]

### Safe to Archive (N emails)
[Table: From | Subject]

Would you like me to archive the N "Safe to Archive" emails?
```

**Key formatting rules:**
- Needs Attention items go FIRST and get the most detail
- Within Needs Attention, sort oldest-first (most likely to be forgotten)
- For Safe to Archive, just list them briefly — the user doesn't need to think about these
- Always end by offering to archive the safe-to-archive batch

## Phase 4: Act on User Decisions

After the user responds:

### Bulk archive
When user approves archiving, remove the `INBOX` label from all approved messages using `batch_modify_gmail_message_labels`. Batch in groups of 25.

### Follow-up actions
If the user wants to:
- **Reply to an email:** Fetch the full content and help draft a response
- **Archive specific categories:** Process the batch
- **Read a newsletter:** Fetch full content and summarize key points
- **Archive calendar invites from a specific sender:** Search broadly — people often send from multiple email addresses (e.g., personal Gmail AND work email). Search by name, not just email address.

## Known Gotchas

### Multiple email addresses per person
People send from different addresses (personal vs work). When archiving "all calendar updates from X", search by sender name across all known addresses, not just one. Example: Tina He sends from both `yingaling@gmail.com` and `the@meta.com`.

### Gmail rate limits
`get_gmail_messages_content_batch` with 25 messages can trigger "Too many concurrent requests for user" (HTTP 429). Use batches of 12 for metadata fetches. Retry failed messages in a separate smaller batch.

### Calendar invite emails vs calendar events
Archiving a calendar invite email does NOT accept, decline, or affect the calendar event in any way. It only removes the email from the inbox. Safe to archive without side effects.

### Read vs unread doesn't matter for inbox triage
The user's system is inbox-based, not unread-based. If it's in the inbox, it needs processing regardless of read status. Don't filter by `is:unread` — use `in:inbox`.
