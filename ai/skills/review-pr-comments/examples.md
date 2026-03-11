# Examples

## Review by PR URL
```
/review-pr-comments https://github.com/org/repo/pull/123
```

## Review by PR number with explicit repo
```
/review-pr-comments 123 --repo org/repo
```

## Typical output snippet
```
PR Summary
- Title: Add billing webhook retries
- Author: octo-dev
- Base -> Head: main -> billing/retries
- URL: https://github.com/org/repo/pull/123

Comment Analysis
1) 987654321 [review] by @coderabbitai
   - Context: apps/api/src/billing.ts:142
   - Decision: Accept
   - Reasoning: This avoids retry storms in transient failures and aligns with our backoff policy.
   - Implementation options:
     - Option A: Gate retries behind a max attempt counter and exponential backoff.
   - Draft replies:
     - Reply A: Good catch, added a max-attempt guard with exponential backoff. Thanks!

Reply Comments (copy/paste)
1) Comment 987654321 Reply A: Good catch, added a max-attempt guard with exponential backoff. Thanks!
```
