---
name: message-crafter
description: Helps craft concise, natural-sounding async messages (Slack, email, etc.) through a structured distillation process. Use this skill whenever the user needs help writing a message, responding to someone, or figuring out what to say — especially when they have a lot of thoughts and need help filtering down to the essential point. Trigger on phrases like "help me write a message", "how should I reply", "what should I say", "I don't know how to word this", "draft a slack message", "help me respond", "craft a message", "I need to respond to", or when the user shares a Slack link and asks for help replying. Also trigger when the user brain-dumps a bunch of thoughts about a conversation and seems to be working toward composing a response, even if they don't explicitly ask for help writing it.
argument-hint: [slack thread URL or description of the situation]
allowed-tools: mcp__claude_ai_Slack__slack_read_thread, mcp__claude_ai_Slack__slack_read_channel, mcp__claude_ai_Slack__slack_search_public_and_private, mcp__claude_ai_Slack__slack_search_channels, AskUserQuestion
---

# Message Crafter

Helps distill a swirl of thoughts into a short, confident async message. The user often knows exactly what they want to communicate but struggles to filter it down — they overthink, over-explain, and end up sounding more eager than they intend. Your job is to be the editing layer between their thinking and their send button.

## The core insight

The user's casual explaining voice — how they'd describe the situation to a friend — is already the right voice. The gap isn't communication ability, it's trusting that brevity is enough. Every step of this process should reinforce that.

## Phase 1: Gather Context

If the user provides a Slack URL, parse the channel ID and message timestamp from it and read the thread using `mcp__claude_ai_Slack__slack_read_thread`. Slack URLs follow this pattern:
```
https://[workspace].slack.com/archives/[CHANNEL_ID]/p[TIMESTAMP_WITHOUT_DOT]
```
Convert the timestamp: remove the `p` prefix and insert a `.` before the last 6 digits (e.g., `p1773186977186989` → `1773186977.186989`).

If there are links to other Slack threads within the conversation, read those too — they're often critical context.

Read the full thread before asking the user anything. You want to understand:
- Who's in the conversation and what roles/teams they represent
- What's already been said (so you don't repeat it)
- What the other person is asking for or offering
- Where the conversation's energy is heading

## Phase 2: Listen to the Brain Dump

The user will often arrive with a stream of consciousness — everything they're thinking about the situation, what they want to say, what they're worried about, what impression they want to give. This is gold. Don't interrupt it.

If the user hasn't provided enough context, ask focused questions. But don't run through a formal checklist — pick the 1-2 questions that would actually unlock the draft:

- "What do you actually need from this person right now?"
- "What are you worried about sounding like?"
- "Is there something you've already said in the thread that covers part of this?"

Often the user will provide all of this unprompted. If they've given you a brain dump with clear intent, skip straight to Phase 3. The interview is a fallback, not a requirement.

## Phase 3: Identify the Core

This is the most important step. Reflect back to the user the ONE thing they're really trying to communicate or ask for. Say it in one sentence. Get confirmation before drafting.

Example: "So the core ask is: you want to see their planning docs so you can figure out together where PostHog fits in. That's it?"

Why this matters: when someone has 10 things they want to say, they often can't see which one is the load-bearing point. Naming it explicitly gives them permission to let the other 9 go (for now).

## Phase 4: Draft

Write a message that is **3-5 sentences max**. Apply these principles:

**One ask per message.** If you're asking for docs, don't also pitch an RFC, explain your team's value, and request a meeting. The rest comes naturally if they engage.

**Don't re-earn credibility.** If the user already made their case earlier in the thread, the reply doesn't need to re-sell anything. Trust that the previous messages did their work.

**Confidence through brevity.** Saying less signals "I'm not anxious about this." Long messages signal "I need you to understand how much I've thought about this." The former reads as senior; the latter reads as junior.

**Respect ownership.** If the other person owns the system/project/decision, the message should defer to their architecture and timeline. Use language like "figure out together" rather than "we'll implement X."

**Sound human.** No bullet points in the message body. No corporate transitions ("I'd like to align on..."). No emojis unless the user naturally uses them. Write like a thoughtful Slack message to a teammate, not a formal proposal.

**Flexible on format, not on substance.** "Happy to chat async or hop on a call, whatever works" is better than proposing three meeting times. It signals flexibility without neediness.

**Match tone to context.** Read the thread's existing tone. If it's casual, be casual. If it's more formal, match that. Don't be the person who shifts the register.

## Phase 5: Explain the Draft

After presenting the draft, briefly explain WHY it works — what's included, what's deliberately left out, and why. This serves two purposes:
1. It helps the user evaluate whether the draft is right
2. It builds their instinct for doing this themselves over time

Keep the explanation to 3-5 bullet points. Focus on the strategic choices, not mechanical ones.

## Phase 6: Refine

The user will often want adjustments. Common patterns:
- "This sounds too eager" → shorten it, remove qualifiers
- "This doesn't say enough" → ask which ONE additional point matters most, add only that
- "This sounds like AI wrote it" → make it more casual, add a minor imperfection, use contractions
- "I want to mention X too" → check if X serves the core ask or dilutes it. If it dilutes, suggest saving it for the follow-up conversation.

Always bias toward shorter. If in doubt, cut.

## Anti-patterns to avoid

- **Don't produce messages with bullet points or structured formatting.** Real Slack messages between colleagues are paragraphs, not presentations.
- **Don't use phrases like "I'd love to align on", "circle back", "loop in", "sync up on our respective".** These are corporate filler that makes messages sound generated.
- **Don't link-dump.** If referencing other conversations, mention them conversationally ("I saw the observability discussion") not as hyperlinks unless the user specifically wants links.
- **Don't front-load expertise.** The temptation is to show the user is smart by listing everything they know about the topic. That's what the meeting is for, not the Slack message.
- **Don't add emojis** unless the user explicitly uses them in their natural communication style.
- **Don't produce multiple options.** Draft one message. If it's wrong, iterate. Options create decision fatigue for someone who's already overthinking.
