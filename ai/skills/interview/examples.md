# Interview Skill Examples

## Example Usage

### Basic Invocation
```
/interview Add a dark mode toggle to the settings page
```

### More Detailed Starting Point
```
/interview Build a real-time collaborative document editor with conflict resolution
```

### API Feature
```
/interview Add webhook support for our notification system
```

## Example Interview Flow

### Round 1: Big Picture
```
Q: What's the primary problem this solves? Who is experiencing this pain today?
Q: What does a successful outcome look like for the user?
Q: What's driving the timeline for this feature?
```

### Round 2: User Context
```
Q: Walk me through a typical user's journey - what are they doing before, during, and after using this feature?
Q: Are there different user types with different needs?
Q: How technically sophisticated are your users?
```

### Round 3: Functional Deep-Dive
```
Q: What are all the inputs the user provides?
Q: What validation happens on those inputs?
Q: What exactly do they see when it's working vs when it fails?
```

### Round 4: Technical Probing
```
Q: What data needs to be persisted? What's the lifecycle?
Q: Are there race conditions or concurrent access concerns?
Q: What's the expected scale? 10 users? 10,000? 10M?
```

### Round 5: Edge Cases
```
Q: What happens if the user loses network mid-operation?
Q: What if they have no data yet (empty state)?
Q: What if they hit a quota or rate limit?
```

### Round 6: Tradeoffs
```
Q: If you had to cut one thing from v1, what would it be?
Q: What technical debt are you knowingly accepting?
Q: What's the simplest version that would still be valuable?
```

## Sample Output Spec (Abbreviated)

```markdown
# Dark Mode Toggle Specification

## Overview
- **Problem Statement**: Users working in low-light environments experience eye strain with the current light-only UI
- **Target Users**: All authenticated users, particularly those working evening hours
- **Success Metrics**: 30% adoption within 60 days, reduction in "eye strain" support tickets

## Requirements

### Functional Requirements
1. User can toggle between light, dark, and system-default modes
2. Preference persists across sessions and devices
3. Toggle is accessible from settings and via keyboard shortcut (Cmd/Ctrl+Shift+D)
4. Transition between modes is animated (200ms fade)

### Non-Functional Requirements
- Toggle must complete within 50ms (no flash of wrong theme)
- Must work with all existing components
- Must meet WCAG 2.1 AA contrast requirements in both modes

## User Experience

### User Flows
1. **First-time setup**: System defaults to OS preference, banner offers customization
2. **Manual toggle**: Settings > Appearance > Theme selector
3. **Quick toggle**: Keyboard shortcut or header icon

### Edge Cases
- System preference changes while app is open -> update immediately
- User on old browser without prefers-color-scheme -> default to light

## Technical Design

### Data Model
```typescript
interface UserPreferences {
  theme: 'light' | 'dark' | 'system';
  updatedAt: timestamp;
}
```

### Implementation Approach
- CSS custom properties for all colors
- Theme class on document root
- LocalStorage for immediate load, API sync for persistence

...
```

## Tips for Good Interviews

1. **Don't accept vague answers** - "It should be fast" -> "What response time is acceptable? 100ms? 1s? 5s?"

2. **Explore the "why"** - Understanding motivation reveals hidden requirements

3. **Think about failure** - Happy path is easy; error handling reveals complexity

4. **Challenge scope** - "Do you really need X for v1, or is that a nice-to-have?"

5. **Validate with examples** - "Give me a specific example of when a user would..."
