---
name: posthog-architecture
description: Use when adding, debugging, or reviewing feature flags, A/B experiments, exposure events, conversion events, or any PostHog-related code in the Supabase dashboard or platform repo. Also use when bucketing rates don't match the configured rollout percentage, when an audience filter seems to silently exclude users, or when something looks like a race between identify and flag evaluation.
---

# PostHog Architecture in Supabase

Supabase's PostHog integration is **mostly server-side**. Default posthog-js mental models — `identify()` triggers a `/flags/` reload, `onFeatureFlags` re-evaluates, `getFeatureFlag` returns the live SDK value — do not apply. Code written against those assumptions appears to work but is operating on a separate store the rest of the stack ignores.

This skill is a reference for how the integration actually works, what the common failure modes look like, and how to add flags/events correctly.

## Read First

When debugging or extending PostHog behavior in this codebase, ALWAYS read these files before recommending changes:

| Concern | File |
|---|---|
| Flag evaluation handler | `~/supabase/platform/api/apps/mgmt-api/src/routes/platform/telemetry/feature-flags.controller.ts` |
| Frontend flag context | `~/supabase/supabase/packages/common/feature-flags.tsx` |
| Frontend flag hook | `~/supabase/supabase/apps/studio/hooks/ui/useFlag.ts` |
| Frontend identify (pageviews only) | `~/supabase/supabase/apps/studio/lib/telemetry.tsx` |
| posthog-js wrapper (pageviews only) | `~/supabase/supabase/packages/common/posthog-client.ts` |

Do not infer behavior from posthog-js documentation alone. The wrapper at `posthog-client.ts` is used for pageviews; flags and custom events bypass it.

## Architecture in One Diagram

```
┌─ Frontend (apps/studio) ───────────────────────────────────────────┐
│                                                                    │
│  FeatureFlagProvider  ──HTTP──>  GET /telemetry/feature-flags      │
│      │                                                             │
│      ▼                                                             │
│  React context                                                     │
│      │                                                             │
│      ▼                                                             │
│  usePHFlag('foo')                                                  │
│                                                                    │
│  posthog-js (client)  ──HTTP──>  POST /pageview                    │
│                                  (PAGEVIEWS ONLY)                  │
└────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─ Backend (platform/api/mgmt-api) ──────────────────────────────────┐
│                                                                    │
│  TelemetryFeatureFlagsController.callFeatureFlag                   │
│      │                                                             │
│      │  build personProperties + groups                            │
│      ▼                                                             │
│  ctx.posthog.getAllFlagsAndPayloads({                              │
│    distinctId: gotrue_id,                                          │
│    options: { personProperties, groups, groupProperties }          │
│  })                                                                │
│      │                                                             │
│      ▼                                                             │
│  PostHog server SDK  ──>  PostHog cloud (eu.posthog.com)           │
└────────────────────────────────────────────────────────────────────┘
```

Custom events follow the same shape via sibling routes (e.g. `POST /telemetry/feature-flags/track`, other `/telemetry/*` handlers). The frontend never calls `posthog.capture` for product events directly.

## Hard Rules

1. **Do not call posthog-js for flags or custom events.** No `posthog.getFeatureFlag`, `posthog.onFeatureFlags`, `posthog.identify`-driven flag re-evaluation, `posthog.capture` for product events. These compile and look correct but operate on a store the rest of the app ignores.
2. **Feature flag values come from `usePHFlag`** (`apps/studio/hooks/ui/useFlag.ts`). It reads from a React context populated once per dep-change by `FeatureFlagProvider`. There is no live subscription to posthog-js.
3. **Custom events go through the backend.** Add a new telemetry endpoint when adding a new event type — do not bypass it.
4. **Audience filters need explicit `personProperties`.** PostHog evaluates audience filters against the `personProperties` payload the backend sends. If the property isn't in that payload, PostHog falls back to whatever's stored on the person profile from prior events — usually empty/stale for new signups. Audience filter then silently fails and the user gets `false` (control).
5. **Bucketing identifier is `distinctId: gotrue_id`** (the user's gotrue UUID). Stable per user. Do not bucket on anonymous distinct_ids.

## Adding a New Feature Flag

1. Create the flag in PostHog UI with bucketing on `distinct_id`. Audience filters use person properties (e.g. `org_count`, `signup_timestamp`, `plan`).
2. **Confirm the backend already sends every property your audience filter references.** Read `feature-flags.controller.ts:getFeatureFlags`. If your filter mentions `org_count` and the controller doesn't pass it in `personProperties`, your flag will not work — see "Audience Filter Silently Fails" below.
3. Read the flag in React with `usePHFlag<T>('flagKey')`. Handle the three return states: `undefined` (loading or missing), `false` (explicitly disabled / not in audience), `T` (a real value).
4. For experiments: fire an exposure event via the existing telemetry track endpoint. Include `experiment_id` and `variant`. See the `growth-pr-review` skill for full exposure/conversion event conventions.

## Adding a Property to the Audience-Filter Vocabulary

When an audience filter needs a property the backend doesn't currently send (the bug that produced this skill):

1. Find the source of truth for the property. Prefer our own database — we control it and there is no propagation delay. Avoid relying on PostHog's person profile for new-signup properties (it's populated async by posthog-js events and is often empty for the user's first few minutes).
2. In `feature-flags.controller.ts:getFeatureFlags`, look up the value and include it in `personProperties`:
   ```ts
   const payload = {
     distinctId: gotrue_id,
     options: {
       personProperties: { gotrue_id, org_count, signup_timestamp },
       // ...
     },
   }
   ```
3. **Update the cache key** in `feature-flags.controller.ts` if the new property can change during a user's session and that change should affect flag evaluation (look at `getPosthogUserFeaturesCacheKey`). Otherwise the cached value (default TTL: 10 minutes) will be served past the change.
4. Add a unit/e2e test covering the audience filter path — see `feature-flags.e2e-spec.ts`.

## Common Failure Modes

### Audience Filter Silently Fails

**Symptoms:** Configured rollout is `N%`, actual bucketing rate is much lower (sometimes by 5x). Day-over-day rate is *stable but wrong* — not the bursty pattern a real deploy bug produces.

**Cause:** The audience filter references a person property that the backend doesn't pass in `personProperties`. PostHog falls back to the stored person profile, finds nothing/stale data, the filter fails, the user gets `false`.

**Fix:** Add the property to `personProperties` in `getFeatureFlags`. Source it from our DB, not from PostHog person properties.

### Stale Flag Value Pinned for 10 Minutes

**Symptoms:** A user whose properties just changed (created their first org, upgraded plan, etc.) keeps seeing the old flag value for ~10 minutes.

**Cause:** `feature-flags.controller.ts` caches the eval result keyed by `(gotrue_id, project_ref, organization_slug)` with a 10-minute TTL. If the property that should change the eval isn't in the cache key, the stale answer is served.

**Fix:** Add the relevant property to the cache key, or drop the TTL for flags where freshness matters.

### "It Works in Posthog But Not In Our App"

**Symptoms:** Engineer checks the PostHog UI's "Match users" preview, sees the user is correctly bucketed, but the app behaves as if they're in control.

**Cause:** The PostHog UI evaluates against the person profile in PostHog cloud. Our backend evaluates against the `personProperties` we send. These are different.

**Fix:** Test by hitting `/telemetry/feature-flags` directly with the user's auth and reading the response. That's what the app sees.

### Frontend "Race Fix" That Isn't Fixing Anything

**Symptoms:** A hook subscribes to `posthog.onFeatureFlags` or waits on `posthog.getPersonProperty` before reading a flag.

**Cause:** Misapplied posthog-js mental model. The flag value `usePHFlag` returns comes from the React context, not from posthog-js. The hook's subscription doesn't refresh the value it reads.

**Fix:** Delete the subscription. Read `usePHFlag` directly. If you need to wait for the flag to be `!== undefined`, just check that — it'll be defined once `FeatureFlagProvider`'s fetch resolves.

## Red Flags — Stop and Reconsider

Any of these in a PR means you're working against the architecture:

- Importing `posthog-js` outside `packages/common/posthog-client.ts`
- Calling `posthog.getFeatureFlag`, `posthog.onFeatureFlags`, `posthog.reloadFeatureFlags`
- Calling `posthog.capture` for a product event (not a pageview)
- A frontend hook that "waits for identify to complete" before reading a flag
- An audience filter that references a property without a corresponding update to `feature-flags.controller.ts`
- A new telemetry event added without a backend endpoint

## Out of Scope

This skill does NOT cover:

- **Event naming conventions** — see `telemetry-standards`.
- **Experiment exposure/conversion event design** — see `growth-pr-review`.
- **Analytics query patterns in Hex or PostHog UI** — out of scope; this is about the integration, not the analysis.
- **PostHog server SDK configuration** — outside our control plane; refer to PostHog docs.
- **Pageview tracking** — works via standard posthog-js and is the one place the default mental model applies. Don't touch unless you're explicitly changing pageview behavior.
- **Group analytics / group properties** — touched on briefly (the controller does pass `groups` and `groupProperties`), but full group analytics patterns are out of scope here.

## References

- Investigation log: `~/supabase/docs/investigations/2026-05-18-posthog-architecture.md` (when written)
- Bug journal: `~/supabase/docs/bugs/2026-05-18-default-grants-bucketing-1pct.md` (when written)
- Related skills: `telemetry-standards` (event vocabulary), `growth-pr-review` (experiment review), `explain-race-condition` (when the symptom looks like a race but isn't)
