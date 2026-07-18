# Phase 1: propose, blind (decision 016, composition / integration)

You are proposing an approach to the assignment below. You are one of THREE
workers doing this independently, right now, in parallel (claude-worker,
codex-worker, agy-worker). You will not see the other proposals until phase 1
closes, and they will not see yours.

## Assignment (goal, verbatim from Scott via dalinar 2026-07-18T17:30Z)

> "This is an improvement, but a lot of work was put in without a ton of
> progress. Some of the buildings don't feel organic to the terrain, and the
> flora doesn't jive. The spike was really solid, how are our specs/prompts
> failing given the clear art target?"

Reframe (authoritative): the next round is composition/integration, NOT another
texture round. Ground/dirt texture is LOCKED and DONE (decisions 010-015). Do
not reopen it. Fix the SEAMS between separately-generated objects and the ground.

## The diagnosis you are solving

The spike (`docs/art/iso-five-asset-spike.png`) is a SINGLE composed image:
ground, buildings, flora, shadows generated together, so every object-to-ground
interaction (worn earth at thresholds, grass meeting foundations, grounding
shadows) is baked in. Our pipeline decomposes the spike into standalone sprites
and recomposes them in-engine (`src/render/town/village_render.gd`). Nothing has
ever graded the SEAMS. Scott's eye caught two instantly: contact shadows read
as pasted-on, and the flora shows literal cutout edges (the flower bush's
octagonal alpha-mask edge).

## Named failure surfaces (all RENDER-side)

1. **Object grounding.** `village_render.gd _build_shadows` draws one uniform
   soft-ellipse decal per object (`assets/village/shadow_decal.png`,
   `SHADOW_ALPHA 0.28`, `SHADOW_WIDTH_FRAC 0.62`). Buildings read pasted-on.
2. **Object-terrain interaction.** No worn/transition zone where a structure
   meets the ground. The spike has worn earth at thresholds and grass creeping
   to foundations; we have a razor sprite boundary.
3. **Flora integration.** `bush_a/b`, `flower_cluster_a/b`, `tree_large`,
   `crown_foliage` are grey-background cutouts with hard alpha edges, no
   palette/scale/edge grade against the actual ground.
4. **Scene-level lighting coherence.** One global `CanvasModulate`
   `Color(1.0,0.95,0.88)`. Separately-generated objects may not share a light
   direction or tonal key with the ground.

## Constraints

- Sim/render separation is HARD: work only in `src/render/town/`,
  `assets/village/`, `tools/art/`. `src/sim/` (placement/footprint) is PROTECTED
  and OUT of scope; if you think you need it, you have mis-scoped, re-scope.
- No em-dashes anywhere (code, comments, commits, docs). Hard repo rule.
- Isometric projection spine is frozen (decision 008). Art is ours (AI-gen /
  composited), no downloaded packs. Any offline bake in `tools/art/` stays a
  pure function of its inputs (no time/order-seeded RNG).
- Export-safe asset path only: ResourceLoader off `res://assets/village/`
  (proven by the export gate). No `Image.load` of a game texture at runtime.
- Ground/dirt TEXTURE is frozen. You may SAMPLE the ground for a seam treatment
  but must not retune the dirt plate/detail/lane bakes for their own sake.
- Full-village expansion is OUT (next round). Fix composition at the current
  four-building inn-green district.
- Meshy is AVAILABLE under deliberate-spend discipline IF in-context flora
  regeneration is your winning path and genuinely needs it (balance 2937, no
  pending). No mandate to spend. A paid path must justify why zero-cost
  compositing cannot achieve the same seam fix.

## Acceptance bar (what your approach will be graded against)

The COMPOSED SCENE at 1x, not crops, judged confusable with the spike across
four dimensions: (D1) object grounding / contact shadow, (D2) object-terrain
interaction / worn zones, (D3) flora integration / no cutout edge / in-context
palette+scale, (D4) scene-level lighting coherence. A single tell Scott's eye
would catch fails the pass. "No enumerable dirt defect" is NOT the bar anymore.

## Branch

Use the branch matching your role: claude-worker -> `claude/016-composition`,
codex-worker -> `codex/016-composition`, agy-worker -> `agy/016-composition`.
You are already IN a worktree branched off round head `3c4c905`. Confirm your
branch, do not create a new worktree, do not touch another resident's.

## Blind means blind

Do not read the other residents' proposals, branches, worktrees, or inboxes,
and do not accept a summary of one. Propose what you actually think is best, not
the safe middle. If you see another proposal by accident, say so.

## Required output format (four sections, all of them)

1. **Approach.** What you would build and why this way rather than the obvious
   alternative. Concrete: name the files, functions, shaders, bakes, assets, and
   data flow. Attackable, not "add contact shadows" but exactly how (per-object
   baked directional shadow? ground-shader interaction band sampling the
   footprint? alpha-feather shader on flora? in-context flora regen? per-object
   tonal match?). Say what you leave out.
2. **Risks.** Where it breaks, what you are unsure about, what you would find
   out first with one hour and one question. Include the risks that make your
   own approach look worse.
3. **Division-of-labor claim.** Which piece you specifically are best suited to
   own and why (your harness/strengths). Name pieces better suited to another
   resident if any.
4. **Rough estimate.** Order of magnitude, honest unit, what would blow it up.

## Ship it as a commit

Write the proposal as a real file on your branch (suggest
`docs/proposals/016-composition-<yourname>.md`) and COMMIT it with your
`Co-authored-by:` trailer. Not a scratch file, not dispatch output: a commit.
Then report the full 40-char SHA and the branch back. Your turn is over when the
proposal is committed and the SHA is reported, not before. Do NOT push to
origin (doers never push; the orchestrator integrates).
