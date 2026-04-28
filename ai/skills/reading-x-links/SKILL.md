---
name: reading-x-links
description: Use when the user shares any URL on x.com, twitter.com, fxtwitter.com, vxtwitter.com, or t.co (the Twitter/X URL shortener). Direct WebFetch on x.com returns 402 / login wall, and most named workarounds (fxtwitter HTML, vxtwitter HTML, public Nitter mirrors) UA-sniff WebFetch and either redirect or serve JS shells with no tweet text.
---

# Reading X / Twitter links

## Why this exists

Plain WebFetch on `x.com` / `twitter.com` returns **402 Payment Required** (verified 2026-04-27). The popular HTML workarounds people post about online — `fxtwitter.com`, `vxtwitter.com`, `nitter.*` — UA-sniff and fail too: fxtwitter 302-redirects WebFetch back to x.com, vxtwitter serves a JS-redirect shell, and most Nitter instances are dead post-2023.

The only reliable fallbacks are the JSON API endpoints fxtwitter and vxtwitter publish for bots. Those return clean structured data regardless of user-agent.

## Verified fallback chain

For status URLs (`{host}/{user}/status/{id}` — strip query params first):

1. `https://api.fxtwitter.com/{user}/status/{id}` — preferred. Returns `{ tweet: { text, author: { name, screen_name }, created_at, replies, retweets, likes, views, replying_to, media, ... } }`. Includes `replying_to` for thread walking.
2. `https://api.vxtwitter.com/{user}/status/{id}` — fallback. Top-level fields: `text`, `user_name`, `user_screen_name`, `date`, `mediaURLs`, `likes`, `retweets`, etc.
3. `https://xcancel.com/{user}/status/{id}` — Nitter fork, intermittently 503. Parse the rendered HTML.
4. `https://archive.ph/newest/https://x.com/{user}/status/{id}` — only works if archived.
5. **Playwright MCP** (`mcp__plugin_playwright_playwright__browser_navigate`) — heavy fallback. Use for threads, quote-tweets, replies, profile pages, search results, or anything richer than a single tweet.
6. Ask Sean to paste the text or screenshot it.

For non-status URLs (profile `x.com/user`, search, hashtag, `/i/lists/...`): skip 1–2, jump to xcancel → archive → Playwright.

## URL parsing

Before fetching, normalize:

- Strip tracking params (`?s=20`, `?t=...`, `?ref_src=...`).
- Extract `{user}` and `{id}` from the path.
- Handle path suffixes: `/photo/N`, `/video/N`, `/analytics`. Drop them — the base status URL is what the API wants.
- `t.co/...` short links: `WebFetch` the t.co URL first to follow the redirect, then re-enter this skill with the resolved URL.
- `mobile.twitter.com` / `m.twitter.com`: treat as `twitter.com`.

## Reporting back

Don't dump JSON. Give Sean:

- **Author**: `@handle` (display name)
- **Posted**: human date (e.g. "2024-03-15")
- **Text**: verbatim, in a `>` quote block
- **Media**: list URLs if present
- **Engagement**: only if relevant to his question

If `replying_to` is non-null and Sean's question implies he wants the thread context, recursively fetch the parent tweet(s) before responding. Don't fetch the whole reply tree unless asked.

## Common mistakes

| Mistake | Reality |
|---|---|
| Using `fxtwitter.com` (no `api.`) | UA-sniffs WebFetch and 302-redirects to x.com → 402 |
| Using `vxtwitter.com` (no `api.`) | Returns JS-redirect HTML; no tweet text in the response |
| Trying `nitter.net` | Shut down. Most public Nitter instances are dead. |
| Forgetting to strip `/photo/1` from URL | api.fxtwitter still works but returns slightly different shape; cleaner to strip |
| Not following `t.co` redirect first | The shortened URL needs to resolve to know which method to use |
| Confidently asserting "fxtwitter.com works" | Test before claiming. The JSON API works; the HTML version does not (in this tool). |

## When all else fails

State what you tried (which fallbacks, which errors) and ask Sean to paste the tweet text or screenshot. Don't pretend you can't read X links when you have untried fallbacks left.
