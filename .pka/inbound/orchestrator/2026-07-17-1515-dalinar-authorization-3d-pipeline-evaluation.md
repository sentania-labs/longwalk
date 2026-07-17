---
from: dalinar (relaying Scott's authorization — production-approach fork)
date: 2026-07-17T15:15Z
type: authorization + design-fork (evaluate, pilot authorized if team chooses)
re: non-sprite / 3D art production as a path to spike fidelity
---

Scott has opened the art PRODUCTION approach as a fork. He is NOT mandating
a change; he is authorizing the team to evaluate non-sprite paths and,
if the team judges it worthwhile, to run a PILOT. His words: "if there's a
way to do it that's not sprite based, I'm open to it... if they think access
to something like Meshy will do it, I'm prepared to let them have a pilot."
He also noted codex is doing strong sprite work — a pivot should build on
that, not casually discard it.

## The three paths to evaluate

Treat this as a contested phase-1 question. Evaluate all three; propose with
evidence (sample outputs where feasible, honest fidelity/effort/risk):

1. **Stay pure-sprite** (current path). Codex's pipeline continues; close the
   fidelity gap directly in 2D generation. Lowest disruption; the animation,
   scale, and shadow defects stay hard 2D problems.

2. **Real-time 3D** (Meshy-generated meshes rendered live through an
   iso-locked camera in Godot 3D). Solves animation (skeletal rigging),
   scale (shared 3D space), and shadows/grounding (real geometry) largely by
   construction. RISK: real-time 3D through an iso camera tends to read as
   "generic indie 3D," which may miss the spike's PAINTERLY 2D vibe; also
   discards the 2D iso render spine just built, and AI-generated meshes need
   real cleanup + rigging effort.

3. **3D pre-rendered to 2D sprites** (Dalinar's recommended bias — evaluate
   it seriously). Generate/build models in 3D (Meshy), rig + animate + pose,
   then RENDER from the fixed iso angle down to 2D sprite sheets with
   painterly post-processing. This is how Diablo, StarCraft, Age of Empires 2,
   Donkey Kong Country were made. Gets consistent lighting, correct scale,
   8 facings, and rigged animation from the 3D side, while the in-game asset
   stays a painterly 2D sprite — PRESERVING the iso render spine and most of
   codex's existing pipeline. Attacks the exact named defects (animation,
   scale, shadows) without gambling the vibe.

## Constraints on the evaluation

- The GOAL is unchanged: spike fidelity, Two Rivers vibe, in the running
  game. The production method is what's on the table, not the target.
- "Art is ours" still holds: Meshy (if used) is a generation TOOL producing
  OUR assets, same category as the sprite-forge image gen — reference art
  stays reference only. Meshy is a NEW DEPENDENCY (external service, likely
  API key / account) — treat adoption as the escalation-class decision it is,
  record it in a decision record, and note license/ToS + cost for Scott.
- Isometric is settled (decision 007). Any 3D path renders to / composes for
  the isometric view; it does not reopen projection.
- If the team pilots path 2 or 3, scope the pilot SMALL first: one building +
  the player character through the full chosen pipeline, rendered in-engine,
  compared side-by-side against the spike and the current 2D build. Prove the
  vibe before committing the whole town to a new pipeline.

## Decision authority

The team CHOOSES the path (this is a capability/production-method call within
its autonomy), records the decision with the four-ballot vote, and reports
the chosen direction + any pilot result to Scott via TEAM-STATE / a milestone
build. Adopting Meshy specifically (new paid/external dependency) should be
called out explicitly to Scott in the decision record even though the pilot
itself is pre-authorized. If the team stays pure-sprite, that's a legitimate
outcome — Scott opened the door, he didn't push anyone through it.
