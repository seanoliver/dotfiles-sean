# The Playback Engine

Copy these patterns. Every one exists because its absence produced a real bug in a shipped explainer.

Reference implementation: `~/supabase/docs/learning/kubernetes-lowpoly.html`.

## Imports

Three.js from unpkg via an import map — works from `file://` because unpkg sends `Access-Control-Allow-Origin: *`.

```html
<script type="importmap">
{ "imports": {
  "three": "https://unpkg.com/three@0.160.0/build/three.module.js",
  "three/addons/": "https://unpkg.com/three@0.160.0/examples/jsm/"
} }
</script>
```

```js
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { CSS2DRenderer, CSS2DObject } from 'three/addons/renderers/CSS2DRenderer.js';
```

## Low-poly look

Flat shading + Lambert + a warm key light and a cool hemisphere. No fog — a dollied-back portrait camera pushes past fog-far and the scene goes black.

```js
const mat = (color, opts = {}) => new THREE.MeshLambertMaterial({ color, flatShading: true, ...opts });

scene.add(new THREE.HemisphereLight(0xcfe4ff, 0x46644f, 1.0));
const sun = new THREE.DirectionalLight(0xfff3d6, 1.55);
sun.position.set(-34, 56, 32);
sun.castShadow = true;
sun.shadow.mapSize.set(2048, 2048);
```

Cones and dodecahedrons scattered on the ground read as trees and rocks and make the scene feel like a place rather than a diagram. Cheap, worth it.

## Labels — and cleaning them up

`CSS2DRenderer` leaves the `<div>` in the DOM when its 3D object is removed. Ghost labels float over an empty scene and look like objects that still exist.

```js
function label(parent, text, y, cls = '') {
  const el = document.createElement('div');
  el.className = 'lbl ' + cls;
  el.textContent = text;
  const o = new CSS2DObject(el);
  o.position.set(0, y, 0);
  parent.add(o);
  o.userData.el = el;
  return o;
}

function killLabels(root) {
  root.traverse(o => {
    if (o.isCSS2DObject && o.element?.parentNode) o.element.parentNode.removeChild(o.element);
  });
}
```

Call `killLabels(obj)` before every `parent.remove(obj)`. Test it: count `.lbl` at chapter 1, jump around, come back, count again.

Two labels on one object need ~1.6 world units of vertical gap or they collide on screen. Mark secondary labels `class="secondary"` and hide them under 820px.

## Chapters

```js
const CH = [
  {
    t: 'Title',
    b: 'Body with <b>emphasis</b> and <code>literals</code>.',
    w: 'What to watch on screen.',
    dur: 8,                                   // seconds
    cam: { pos: [0, 46, 76], tgt: [0, 6, 14] },
    enter() { /* spawn packets, kick off motion — cosmetic only */ },
    complete() { CH[n - 1].complete(); /* then set THIS chapter's end state */ },
  },
];
```

**The `complete()` chain is the whole trick.** `enter()` animates; `complete()` sets state. Each `complete()` calls its predecessor first, so any chapter can be entered cold and rebuild the exact state that playing through would produce. Chapter 0's `complete()` calls `resetWorld()` and terminates the chain.

Keep `complete()` idempotent — it will be called repeatedly.

## Seek

```js
let gen = 0;                    // bumped on every seek; orphans abandoned timers
function later(fn, ms) { const g = gen; window.setTimeout(() => { if (g === gen) fn(); }, ms); }

function seek(n, { autoplay = null } = {}) {
  n = Math.max(0, Math.min(CH.length - 1, n));
  gen++;
  clearPackets(); clearPings();
  scene.updateMatrixWorld(true);      // world positions must be fresh before enter() samples them
  if (n === 0) resetWorld(); else CH[n - 1].complete();
  cur = n; u = 0;
  userDriving = false;
  applyCam(CH[n]);
  CH[n].enter();
  if (autoplay !== null) playing = autoplay;
  renderUI();
}
```

Use `later()` for every delay inside a chapter. A raw `setTimeout` from a chapter the user has left will fire into the new state and corrupt it.

`scene.updateMatrixWorld(true)` matters because `enter()` typically calls `localToWorld()` to find packet endpoints, and matrices are otherwise only refreshed at render time.

## Packets

The traveler. A small emissive octahedron on a quadratic bezier, with an expanding ring on arrival.

```js
function packet({ from, to, color, arc = 10, dur = 1.1, delay = 0, text = '', onArrive }) {
  const m = new THREE.Mesh(packetGeo, new THREE.MeshLambertMaterial({
    color, flatShading: true, emissive: color, emissiveIntensity: 0.5 }));
  m.visible = false;
  scene.add(m);
  if (text) label(m, text, 1.5, 'sm dark');
  const mid = from.clone().lerp(to, 0.5); mid.y += arc;
  packets.push({ m, curve: new THREE.QuadraticBezierCurve3(from.clone(), mid, to.clone()),
                 dur, delay, t: -delay, onArrive });
}
```

Chain `onArrive` to spawn the next hop — that is how you show "A → B → C" as one continuous journey. Stagger parallel packets with `delay: i * 0.3` so three things happening at once stay legible.

Hold component positions as functions, not values, so they survive layout changes:

```js
const P = {
  api: () => apiServer.localToWorld(new THREE.Vector3(0, 8, 0)),
  pod: (p) => p.group.position.clone().add(new THREE.Vector3(0, 1.5, 0)),
};
```

## Actors with state

Give each state a distinct color *and* a distinct motion. Color alone is not enough — motion is what the eye catches.

```js
tick(dt) {
  this.group.position.lerp(this.target, 1 - Math.pow(0.0015, dt));   // frame-rate independent
  this.mesh.material.color.lerp(new THREE.Color(WANTED[this.state]), 0.12);
  if (this.state === 'pending')     { this.group.position.y += Math.sin(this.t * 2) * 0.02; }
  if (this.state === 'creating')    { s = 1 + Math.sin(this.t * 9) * 0.07; }   // urgent pulse
  if (this.state === 'running')     { s = 1 + Math.sin(this.t * 2.2) * 0.02; } // calm breath
  if (this.state === 'terminating') { op = 0.4; s = 0.85; }
}
```

Because targets are lerped every frame, reassigning an actor to a new home animates the move for free — that alone sells "the scheduler placed this pod."

## Camera

Per-chapter framing, eased, and it yields the instant the user drags.

```js
function dollyFactor() {                     // narrow viewports see less; back off
  const a = stage.clientWidth / stage.clientHeight;
  return a < 0.8 ? 1.85 : a < 1.1 ? 1.5 : a < 1.5 ? 1.18 : 1;
}
function applyCam(ch, instant = false) {
  const tgt = new THREE.Vector3(...ch.cam.tgt);
  const pos = new THREE.Vector3(...ch.cam.pos).sub(tgt).multiplyScalar(dollyFactor()).add(tgt);
  // lerp pos/tgt over ~1.3s with an ease-in-out, skip while userDriving
}
controls.addEventListener('start', () => { userDriving = true; });
```

Also widen the lens on narrow viewports and re-frame on resize:

```js
camera.fov = w / h < 1.1 ? 48 : (w / h < 1.5 ? 40 : 34);
if (!userDriving) applyCam(CH[cur], true);
```

Set `controls.maxDistance` generously (~320) or the dolly gets clamped and portrait framing silently fails.

## Frame loop

```js
const dtRaw = Math.min(clock.getDelta(), 0.05);   // clamp so tab-switching doesn't teleport everything
const dt = dtRaw * speed;                          // speed scales content, not camera easing
if (playing) { u += dt / CH[cur].dur; if (u >= 1) nextCh(); }
```

Ambient motion between chapters — a slowly rotating service disc, a bobbing float — keeps the scene alive while the learner reads.
