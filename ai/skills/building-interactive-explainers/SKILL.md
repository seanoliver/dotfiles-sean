---
name: building-interactive-explainers
description: Use when Sean wants to learn how something works by seeing it rather than reading about it — "explain X with an animation", "build me an interactive guide to X", "make me a simulation of how X works", "teach me X visually", or he links a concept and asks for something he can play through. Also use when a prior explainer needs a new chapter or a correction.
---

# Building Interactive Explainers

## Overview

Sean learns a system by watching one concrete thing travel through it. The deliverable is a single self-contained HTML file: a low-poly 3D world that stays put, a traveler that moves through it, and chaptered narration with playback controls.

**Core principle: the world is the mental model.** Layout carries the architecture, motion carries the mechanism, prose carries only the why. If nothing on screen moves, you have written a document with a Next button — that is the failure this skill exists to prevent.

## Read First

1. `ls ~/supabase/docs/learning/` — read the most recent explainer there. Match its structure, palette, and control layout. Do not invent a new format.
2. Copy the playback engine from `engine.md` in this skill directory. It is load-bearing; do not reimplement it from scratch.

## Build Sequence

Follow in order. Do not start coding at step 4.

1. **Name the traveler and the world, in one sentence each.** "A deployment request travels from your terminal through the control plane onto three worker nodes." If you cannot name a thing that moves, the topic needs reframing — pick the object that flows (a request, a packet, a row, a byte, an electron) and build around it.
2. **Write the full chapter list as plain text first**, before any HTML. Each chapter: `title`, `body` (2–4 sentences, the why), `watch` (one sentence naming what moves on screen). 8–14 chapters. Show this list to Sean if the topic is large — cheaper to redirect now than after the geometry exists.
3. **Fact-check the script against primary sources** before building. Use context7 or official docs for anything version-specific. A beautiful animation of a wrong mental model is worse than no animation. Fix the text now.
4. **Build the static world.** Geometry, labels, lighting, ground. Every component that will ever appear exists from chapter 1 — empty, not absent. The learner must be able to orient once and stay oriented.
5. **Build the playback engine** from `engine.md`: chapter array, `seek()`, the `complete()` chain, generation-guarded timers, packet system, label cleanup.
6. **Animate each chapter** — `enter()` spawns the motion, `complete()` sets the resulting state.
7. **Verify in a real browser.** Mandatory. See below.
8. **Add the quiz** — 5 questions, each answerable only from something that was on screen, each with a one-sentence explanation of why the wrong answers are wrong.

## Non-Negotiables

| Rule | Why |
|---|---|
| Something moves in every chapter | A static diagram with a Next button is not an explainer |
| Layout never rearranges | Camera moves, world stays put — that is what makes it a place |
| Every chapter has a `watch` line | Otherwise the learner does not know where to look |
| Seek is deterministic | Jumping to chapter 9 must rebuild the exact same state as playing to it |
| Timers are generation-guarded | Stale callbacks from an abandoned chapter corrupt state |
| Verified in a real browser | See below — this is the most-skipped step |

## Verify In A Real Browser — Not Optional

`node --check` proves nothing. Neither does counting `<div>` tags.

**Browser tools are usually deferred, not absent.** Two baseline agents both concluded "no browser tool in this session" and shipped unverified. They were wrong. Before claiming you cannot verify:

```
ToolSearch: "select:mcp__plugin_playwright_playwright__browser_navigate,mcp__plugin_playwright_playwright__browser_take_screenshot,mcp__plugin_playwright_playwright__browser_console_messages,mcp__plugin_playwright_playwright__browser_evaluate,mcp__plugin_playwright_playwright__browser_resize"
```

Playwright blocks `file://`, so serve it: `cd <dir> && python3 -m http.server 8791 &` then navigate to `http://localhost:8791/<file>.html`.

Check all five, and report what you observed:
1. **Console is clean** (a favicon 404 is fine, nothing else is).
2. **Screenshot every chapter** — not a sample. Jump to each one, screenshot, and judge it against the framing rules below. Bad framing is the most common defect that survives to delivery, and it is invisible unless you look at every shot.
3. **Seek integrity** — jump to a late chapter cold, then to an early one, then back. State must match what playing through produces.
4. **No leaked DOM** — count `.lbl` elements at chapter 1, jump around, return to chapter 1, count again. Same number.
5. **Mobile** — resize to 390×844 and screenshot.

If a check fails, fix it and re-run. Report honestly which checks you ran.

### Framing rules (apply to every chapter screenshot)

The narration panel covers the lower-left corner, roughly 420×300px. The legend covers the upper right.

- **The chapter's subject sits in the right two-thirds of the frame, vertically centered.** If the thing the `watch` line names is behind the panel, the camera is wrong.
- **No more than about a third of the frame is empty sky or bare ground.** Large void = camera aimed above the action; lower `cam.pos.y` or raise `cam.tgt.y`.
- **Nothing important is cropped by an edge.** Cropped is worse than small — when in doubt, dolly out.
- **Labels do not overlap each other.** Two colliding labels mean the components are too close in screen space: spread the geometry, don't shrink the text.
- **Both endpoints of a chapter's motion are visible.** If a packet flies from A to B, both A and B must be in frame, or the journey reads as a thing vanishing off-screen.

A quick sanity check on any `cam` entry: the subject should span roughly half the frame width. Chapter cameras copied from an earlier build usually need re-tuning after the world's layout changes.

## Output Format

Single file: `~/supabase/docs/learning/<topic>-lowpoly.html`. No build step, no local server needed to open it — Three.js loads from the unpkg CDN via an import map, which works from `file://` because unpkg sends `Access-Control-Allow-Origin: *`.

Required UI, in this order:
- Top bar: title + one-line subtitle, "Reset view" and "Chapters" buttons
- Legend (desktop only) mapping colors to states
- Narration panel: `CHAPTER n OF m`, title, body, and the `watch` line under a divider, with a collapse toggle
- Transport: clickable chapter scrubber, prev / play-pause / next, speed toggle (0.5×/1×/2×), step counter, "Quiz me"
- Keyboard: space = play/pause, ← → = step
- Chapter drawer, quiz overlay

Chapter object shape:

```js
{
  t: 'A pod dies. Nobody panics.',
  b: 'Kill a pod and the controller sees 2 where it wants 3. <b>Same loop, same answer.</b>',
  w: 'node-3’s pod goes red and vanishes; a replacement appears with a new name.',
  dur: 12,
  cam: { pos: [32, 42, 58], tgt: [16, 4, 6] },
  enter() { /* spawn packets, start motion */ },
  complete() { CH[n-1].complete(); /* set resulting state */ },
}
```

Finish by reporting: the file path, the chapter list, and which verification checks passed.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Stacked prose boxes with a Next button | Build a world with a traveler. Motion is the explanation. |
| Rearranging layout per chapter | Move the camera instead |
| Narration restates the chapter title | The `watch` line names an on-screen object and what it does |
| Incremental state mutation only | `complete()` chain so any chapter can be entered cold |
| `setTimeout` straight to state | Generation-guarded `later()` — see engine.md |
| Removing a 3D object with a label | `killLabels()` first; CSS2DRenderer orphans the `<div>` |
| Camera framing tuned on one aspect ratio | Dolly out by aspect; re-frame on resize |
| Fog + a dollied-back camera | Portrait pushes past fog-far and the scene goes black. Skip fog. |
| "Recommend Sean opens it to confirm" | Open it yourself |

## Out of Scope

This skill does **not**:
- Publish or deploy anything. Sean opens the file locally. Only set up GitHub Pages if he asks.
- Write bug-journal or investigation entries. These are learning artifacts, not project docs.
- Teach the underlying topic in chat. The file is the explanation; keep the chat summary to a few lines.
- Build production data-viz or dashboards — use `dataviz` for charts and real datasets.
- Cover 2D-only diagrams by default. Drop to 2D only when the concept has no spatial topology at all (e.g. a pure state machine), and even then keep the traveler, the fixed layout, and the `watch` line.
