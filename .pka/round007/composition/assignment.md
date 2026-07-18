# Assignment scope: decision 016, composition / integration (the seams)

Orchestrator working doc. Feeds TEAM-STATE "Current assignment" and the
decision-record Context section. Sub-round of round 007 (Two Rivers village
at spike fidelity). Stacks on round head `3c4c905` (origin/round/007-village).

## Goal statement (verbatim, as Scott gave it, relayed by dalinar 2026-07-18T17:30Z)

> "This is an improvement, but a lot of work was put in without a ton of
> progress. Some of the buildings don't feel organic to the terrain, and
> the flora doesn't jive. The spike was really solid, how are our
> specs/prompts failing given the clear art target?"

And the reframe that came with it (authoritative, from the same message):

> The next round is a REFRAME, not another dirt sub-round. Texture fidelity is
> DONE, locked, no further dirt work. The district does NOT clear his bar. Fix
> the SEAMS between separately-generated objects and the ground.

## The diagnosis (Scott + dalinar agreed, on record)

The spike (`docs/art/iso-five-asset-spike.png`) is a SINGLE COMPOSED IMAGE:
ground, buildings, flora, and shadows were generated together, so every
object-to-ground interaction (worn earth at thresholds, grass meeting
foundations, grounding shadows) is baked in by construction. Our pipeline
DECOMPOSES the spike into standalone sprites and RECOMPOSES them in-engine
(`src/render/town/village_render.gd`), and nothing in the pipeline has ever
GRADED THE SEAMS between an object and the ground it sits on. Eight QA passes
optimized enumerable ground-texture defects; "confusable" drifted into "no
named defect in the dirt" instead of "the composed scene reads as one painted
world." The two tells Scott's eye caught instantly were both known-and-deferred:
contact shadows (behind dirt since QA pass 5) and cutout flora (the flower
bush shows its literal octagonal alpha-mask edge).

## What is in scope (fix the seams)

The unit that must improve is the COMPOSED SCENE, not any single texture. Named
failure surfaces, all in `src/render/town/` + `assets/village/`:

1. **Object grounding.** Current contact shadow is one uniform soft ellipse
   decal per object (`village_render.gd` `_build_shadows`, `shadow_decal.png`,
   `SHADOW_ALPHA 0.28`, `SHADOW_WIDTH_FRAC 0.62`). Buildings read as pasted-on,
   not seated in the terrain. Grounding shadow method + strength + directional
   consistency are all open.
2. **Object-terrain interaction.** No worn/transition zone where a structure
   meets the ground (the spike has worn earth at thresholds, grass creeping to
   foundations). Nothing paints an interaction band around building footprints.
3. **Flora integration.** `bush_a/b`, `flower_cluster_a/b`, `tree_large`,
   `crown_foliage` are standalone cutouts with hard alpha edges (the octagonal
   mask Scott saw) and no palette/scale/edge grade against the ACTUAL ground
   they sit on. Fix: edge feather/blend, palette+scale grade in context, or
   regenerate/repaint the flora IN CONTEXT against the real ground rather than
   as isolated grey-background cutouts.
4. **Scene-level lighting coherence.** One global `CanvasModulate`
   (`Color(1.0,0.95,0.88)`). Separately-generated objects may not share a light
   direction or tonal key with the ground. Coherence across the composed scene
   is in scope.

## What is OUT of scope

- Ground/dirt TEXTURE fidelity. Locked and done (decisions 010-015). Do NOT
  reopen dirt sub-rounds, do NOT retune the dirt plate/detail/lane bakes for
  their own sake. You MAY read from the ground where a seam treatment needs to
  sample it, but the dirt texture itself is frozen.
- Full-village expansion. Stays gated: fix composition at the four-building
  inn-green district, not at sixteen. Expansion is the NEXT round, gated on
  THIS district passing the new rubric AND Scott's own eye.
- PC / NPC / walk-cycle. Still out (round 007 is free-cam, no-PC/no-NPC).

## Constraints

- Sim/render separation is hard: all of this is RENDER-side
  (`src/render/town/`, `assets/village/`, `tools/art/`). `src/sim/` owns
  placement/footprint only and must not learn about shadows, edges, or light.
- No em-dashes anywhere. Isometric projection spine is frozen (decision 008).
- Art is ours (AI-generated / composited); no downloaded asset packs.
- Determinism: any offline bake stays a pure function of its inputs (no
  time/order-seeded RNG), same as every prior bake in `tools/art/`.
- Export-safe asset path only (ResourceLoader off `res://assets/village/`,
  proven by the export gate). No `Image.load` of a game texture at runtime.

## Spend

Meshy is AVAILABLE under the standing deliberate-spend discipline if
in-context flora regeneration is the winning approach and needs it. Balance
2937, no pending tasks (verified this run). NO mandate to spend. A paid path
that wins gets the same full-turn supervision as every prior paid pass
(pre/post balance check, no PENDING first, cost-confirm, never `save_to`).

## Protected paths touched

No. Expected surfaces are `src/render/town/*`, `assets/village/*`,
`tools/art/*` — none in `.github/protected-paths.txt`. (`src/sim/` is protected
and is explicitly OUT of scope; if a proposal claims it needs `src/sim/`, that
is a red flag to re-scope, not a protected-path authorization.)

## Triage lane

**FULL PROTOCOL.** Two reasonable engineers pick materially different seam
treatments: contact-shadow generation (baked directional shadow sprite vs
procedural blob vs ground-shader interaction band), flora edge treatment
(shader feather vs in-context regeneration vs repaint), and lighting coherence
(global grade vs per-object tonal match) are each a genuine design fork. Scott
directed full protocol explicitly. Decision 016.

## Acceptance target

The rewritten QA rubric in `qa-rubric-composed-scene.md` (this directory) is
BINDING and replaces the dirt-defect rubric as the acceptance bar for this
round. It grades the COMPOSED SCENE at 1x, not crops. Clearing CONFUSABLE on
that rubric is the trigger to surface a build to Scott for his OWN playtest
verdict, not the automated seat's verdict alone (that is exactly what was
insufficient last time).
