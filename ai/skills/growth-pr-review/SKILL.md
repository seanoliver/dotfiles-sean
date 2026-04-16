---
name: growth-pr-review
description: Use when reviewing PRs that touch experiments, A/B tests, feature flags,
  analytics events, or growth engineering code in Supabase Studio. Covers exposure/conversion
  event pairs, flag gating correctness, naming conventions, and PostHog integration.
---

# Growth Engineering PR Review

Specialized review checklist for PRs touching experiments, feature flags, analytics,
and growth instrumentation in Supabase Studio. Use alongside the general `pr-review`
skill — this adds growth-specific criteria.

**REQUIRED BACKGROUND:** Read `telemetry-standards` for event naming and property conventions.

## Experiment Lifecycle Checklist

Every experiment PR must have **both** an exposure event and a conversion event. Missing either
makes the experiment unanalyzable.

### 1. Exposure Event

Fires when a user **in the experiment** sees the experiment surface. Must include:

- `experiment_id` — string identifier matching the PostHog experiment
- `variant` — the variant the user is in (`'control'` | `'variation'` | custom variant names)
- Event name: `{object}_{experiment_name}_experiment_exposed`

**Critical: Only fire for users IN the experiment.**

| Flag type | In experiment | Not in experiment |
|-----------|--------------|-------------------|
| Boolean feature flag | `true` or `false` | `false` = control, so only `undefined` means not in experiment |
| Multivariate experiment | `'control'`, `'variation'`, etc. | `undefined` or `false` |

```typescript
// CORRECT — guards against undefined (not in experiment)
const variant = usePHFlag<'control' | 'variation'>('myExperiment')

// Don't fire exposure if user isn't in the experiment
if (variant === undefined) return null

// Both control AND variation users get exposure events
track('feature_my_experiment_exposed', {
  experiment_id: 'myExperiment',
  variant,
})
```

```typescript
// WRONG — fires exposure for users not in the experiment
const variant = usePHFlag('myExperiment')
track('feature_my_experiment_exposed', { variant }) // variant could be undefined!
```

**Deduplication:** Use a `useRef` guard or `useTrackExperimentExposure` hook to fire once per mount:

```typescript
const hasTrackedExposure = useRef(false)
useEffect(() => {
  if (hasTrackedExposure.current) return
  if (variant === undefined) return
  hasTrackedExposure.current = true
  track('feature_my_experiment_exposed', {
    experiment_id: 'myExperiment',
    variant,
  })
}, [variant, track])
```

Or use the dedicated hook (PostHog-native session dedup via `sessionStorage`):

```typescript
import { useTrackExperimentExposure } from 'hooks/misc/useTrackExperimentExposure'

useTrackExperimentExposure('myExperiment', variant, { extraProp: 'value' })
```

### 2. Conversion Event

Fires when a user completes the target action the experiment is measuring.

- Event name: `{object}_{experiment_name}_experiment_converted`
- Must include `experiment_id` and `variant` (same values as exposure)
- Keep conversion events **separate** from existing product events (e.g., don't overload
  `table_created` — create `table_create_experiment_converted` instead)
- Include outcome properties relevant to the hypothesis (e.g., `has_rls_enabled`, `has_generated_policies`)

```typescript
export interface MyExperimentConvertedEvent {
  action: 'feature_my_experiment_converted'
  properties: {
    experiment_id: 'myExperiment'
    variant: 'control' | 'variation'
    // outcome-specific properties
    completedAction: boolean
  }
  groups: TelemetryGroups
}
```

### 3. Event Definitions in telemetry-constants.ts

Both exposure and conversion events must be defined as TypeScript interfaces in
`packages/common/telemetry-constants.ts` and added to the `TelemetryEvent` union type.

Required JSDoc tags: `@group Events`, `@source studio`, `@page` (route where event fires).

## Feature Flag Gating

### PostHog flags (experiments/growth): `usePHFlag`

```typescript
import { usePHFlag } from 'hooks/ui/useFlag'

const variant = usePHFlag<'control' | 'variation'>('experimentName')

// Handle all three states explicitly
if (variant === undefined) return null        // loading or not in experiment
if (variant === false) return <Control />     // explicitly disabled (boolean flags)
// For multivariate: variant === 'control' → show control UI
// For multivariate: variant === 'variation' → show treatment UI
```

**Return values:**
- `undefined` — flag store loading OR flag doesn't exist → don't render, don't track
- `false` — flag explicitly false → for boolean flags this is control; for multivariate this means not enrolled
- `string` value — the variant name (`'control'`, `'variation'`, etc.)

### ConfigCat flags (infra/ops): `useFlag`

```typescript
import { useFlag } from 'common'

const enabled = useFlag('disableProjectCreationAndUpdate')
```

**Flag these in review:**
- Using `useFlag` (ConfigCat) for experiments — should be `usePHFlag` (PostHog)
- Using `usePHFlag` for infrastructure gates — should be `useFlag` (ConfigCat)
- Not handling `undefined` state from `usePHFlag` (causes exposure events for non-enrolled users)
- Treating `false` the same as `undefined` in multivariate experiments

## Event Naming Conventions

Follows `telemetry-standards` with these experiment-specific additions:

| Pattern | Format | Example |
|---------|--------|---------|
| Exposure | `{object}_{experiment}_experiment_exposed` | `table_create_generate_policies_experiment_exposed` |
| Conversion | `{object}_{experiment}_experiment_converted` | `table_create_generate_policies_experiment_converted` |
| Product event | `{object}_{verb}` (standard) | `product_card_clicked` |

**Experiment ID** property should be `camelCase`: `experiment_id: 'tableCreateGeneratePolicies'`

**Variant values** should be lowercase strings: `'control'`, `'variation'`, `'test'`

## useTrack Requirements

All events in Studio must use the `useTrack` hook from `lib/telemetry/track`:

```typescript
import { useTrack } from 'lib/telemetry/track'
```

**Why:** `useTrack` auto-injects `project` and `organization` group properties. These are
essential for filtering experiments by org/project in PostHog.

**Flag these:**
- Direct `posthog.capture()` calls (bypasses group enrichment)
- `useSendEventMutation` (deprecated)
- Missing `useTrack` import when component has tracking

**Exception:** `useTrackExperimentExposure` calls `posthogClient.captureExperimentExposure()`
directly — this is acceptable because it uses PostHog-native session deduplication.

## Review Checklist

When reviewing a growth engineering PR, verify each applicable item:

### Experiment PRs
- [ ] Exposure event fires for **both** control and variant users
- [ ] Exposure event does **not** fire when variant is `undefined` (user not in experiment)
- [ ] Exposure event fires only once per session (ref guard or `useTrackExperimentExposure`)
- [ ] Conversion event exists and fires on the target action
- [ ] Both events include `experiment_id` and `variant` properties
- [ ] Conversion event is separate from existing product events
- [ ] Both events defined in `telemetry-constants.ts` with JSDoc
- [ ] Both events added to `TelemetryEvent` union type
- [ ] Variant type is properly typed (not `string`, use union of actual variants)

### Feature Flag PRs
- [ ] Using correct provider (`usePHFlag` for growth, `useFlag` for infra)
- [ ] All three states handled: `undefined`, `false`, variant value
- [ ] No UI flash — `undefined` returns null/skeleton, not default content
- [ ] Flag cleanup plan documented (comment or PR description noting when flag can be removed)

### Analytics PRs
- [ ] Event names follow `[object]_[verb]` snake_case with approved verbs
- [ ] Properties are camelCase and self-explanatory
- [ ] Using `useTrack` hook (not direct `posthog.capture()` or deprecated hooks)
- [ ] No PII in event properties
- [ ] No passive render tracking (except `_exposed` events)
- [ ] Event interface added to `telemetry-constants.ts`
- [ ] `groups: TelemetryGroups` included (or `Omit<TelemetryGroups, 'project'>` where project doesn't exist yet)

### General Growth
- [ ] New user interactions have tracking (buttons, forms, toggles, modals)
- [ ] Error/failure states are tracked where they affect growth metrics
- [ ] Existing funnel events not broken by the change
- [ ] Dev toolbar works for testing the new tracking (flags override correctly)

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Exposure fires when `variant === undefined` | Guard: `if (variant === undefined) return` before tracking |
| Exposure fires on every render | Use `useRef` guard or `useTrackExperimentExposure` for dedup |
| No conversion event defined | Every experiment needs a measurable conversion action |
| Conversion reuses existing product event | Create a separate `_experiment_converted` event |
| Using `posthog.capture()` directly | Use `useTrack` to get group enrichment |
| Boolean flag: treating `false` as "not in experiment" | For boolean flags, `false` IS the control group — only `undefined` means not enrolled |
| Multivariate flag: not handling `false` | For multivariate, `false` or `undefined` means not enrolled |
| Variant typed as `string` | Use union type: `'control' \| 'variation'` |
| Missing TelemetryEvent union entry | Event won't be type-checked by `useTrack` |
| Mixing experiment tracking with product tracking | Keep experiment events isolated for clean analysis |
