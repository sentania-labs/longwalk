# 016: composition and integration (grade the seams, not the textures)

- **Status:** accepted
- **Date:** 2026-07-18
- **Assignment:** Round 007 / decision 016. Scott playtested the WIP village
  build and the inn-green district did NOT pass: "Some of the buildings don't
  feel organic to the terrain, and the flora doesn't jive. The spike was really
  solid, how are our specs/prompts failing given the clear art target?" Texture
  fidelity is now LOCKED and DONE (decisions 010-015); the next round fixes the
  SEAMS between separately-generated objects and the ground.
- **Orchestrator run:** composition round, run stamp `20260718-171534` (phase 1)
  / `20260718-172217` (phase 2). See TEAM-STATE.md.
- **Lane:** full protocol (Scott directed it; two reasonable engineers pick
  materially different seam treatments).
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

The spike (`docs/art/iso-five-asset-spike.png`) is a single composed image:
ground, buildings, flora, and shadows were generated together, so every
object-to-ground interaction (worn earth at thresholds, grass meeting
foundations, grounding shadows) is baked in by construction. Our pipeline
decomposes the spike into standalone sprites and recomposes them in-engine
(`src/render/town/village_render.gd`), and nothing in the pipeline has ever
graded the SEAMS between an object and the ground it sits on. Eight prior QA
passes optimized enumerable ground-texture defects while the two tells Scott's
eye caught instantly (contact shadows that read pasted-on; flora showing a
literal octagonal alpha-mask edge) were known-and-deferred. This round rewrites
the acceptance target to grade the COMPOSED SCENE at 1x
(`.pka/round007/composition/qa-rubric-composed-scene.md`, binding) across four
dimensions: D1 object grounding / contact shadow, D2 object-terrain interaction
/ worn zones, D3 flora integration / no cutout edge, D4 scene-level lighting
coherence. Texture fidelity is out of scope and frozen.

## Proposals (phase 1, blind)

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/016-composition` | `dcbd23ec1065ad89cdf1e9ef3773bfcedb40b266` |
| codex-worker | `codex/016-composition` | `4e0ee74ba63ead63a0ce28ee5acf278706ac71e2` |
| agy-worker | `agy/016-composition` | `b906ac6afe719a8fba4c8d0608efd833d8b89aaf` |

**claude** framed three of the four tells as one phenomenon ("the object does
not interact with the ground it stands on") and proposed a single RUNTIME-
rasterized RGBA ground-space interaction field
(`village_render.gd::_build_object_field()`) consumed by `ground.gdshader`: R =
worn apron coverage folded into the frozen dirt `dirt_amount`, G = contact AO,
B = a directional cast smeared toward one scene `LIGHT_DIR`, scaled by object
height. Plus a separable OFFLINE flora edge bake (de-fringe, alpha-trim,
feather, per-kind tonal nudge). Argued a per-object decal can never agree with
the ground's own light.

**codex** proposed an OFFLINE deterministic seam kit: per-object committed seam
PNGs (contact mask from basal alpha, short directional cast, interaction decal)
under `assets/village/seams/`, composed as a per-object Node2D bundle drawn
under each sprite to preserve painter's order; `ground.gdshader` kept
byte-frozen. Flora via ground-aware matte + RGB decontamination against the
estimated background + 1-2px feather. Offline lighting normalization (measured
per-kit color matrix), CanvasModulate demoted to a mild fixed final grade. Hand-
authored per-kit door direction for asymmetric threshold wear.

**agy** proposed the cleanest D1-D4 split: bake per-object contoured shadows
(alpha shear + Gaussian blur), bake `footprint_mask.png` from the sim layout by
reusing the decision-011 lane-bake pipeline and sample it in `ground.gdshader`
modulated by the existing `lane_density`, a runtime `flora.gdshader` alpha-
smoothstep + ground-color blend, and an `object.gdshader` luminance-to-palette
remap replacing the global CanvasModulate.

## Critique (phase 2, adversarial)

| Worker | Critique commit SHA |
| --- | --- |
| claude-worker | `c615220a4a7554544b48260d4166baf5d60e00f8` |
| codex-worker | `d6b4bc7392dbc6778a6fce87f1f1caef4ff2ac16` |
| agy-worker | `c707ff1fa135155627d4d43da929e640f1fe7b60` |

The round converged through explicit mutual concessions rather than agreement:

- **On the worn zone (D2), all three converged on the ground shader.** agy
  conceded (its own words) "Claude is right that the worn apron (D2) MUST
  interact with the actual ground shader logic to avoid pasting a foreign
  texture over the procedural dirt. A separate offline decal (Codex) cannot do
  this without breaking the noise threshold." codex conceded its per-object
  interaction decal is weaker for color continuity and expansion and that
  ground-shader coupling "is already proven by the export gate." claude and both
  peers verified a static offline decal cannot reproduce the runtime noise /
  lane / detail compositing, so its soft edge reads as a pasted patch.
- **On the seam SHAPES (D1 contact/cast, D3 flora matte), all three converged on
  OFFLINE.** claude and codex both require offline RGB decontamination for flora
  (a runtime alpha-smoothstep, agy's D3, provably cannot remove grey RGB
  contamination because the polygon-cropped flora is alpha 255/0 with no
  intermediate values to feather). agy conceded "Codex is right that the seam
  shapes (D1, D3) should be baked offline as alpha/greyscale masks to ensure
  pixel-perfect 1x resolution."
- **Two hard, tree-verified findings decided sub-questions.** (1) codex proved
  claude's runtime cast length, "the inn casts longer than a bush," is FALSE for
  the current manifest: `native_px.y - anchor` is 1 for the inn and 10 for
  `tree_large` (verified). (2) The offline shadow pipeline ALREADY EXISTS:
  `tools/art/process_assets.py:157 derive_shadows()` derives cast + contact from
  a basal `footprint_slice` with a `light_vector` and `GaussianBlur` (verified),
  and there is already a background-matte Gaussian feather at line 120. So the
  offline path extends proven code; agy's plan to invent a GaussianBlur in
  GDScript reinvented it, and claude's runtime raster bypasses it.
- codex + agy both showed reusing `lane_density` (baked from seed 7007 for lane
  shoulder wear) as foundation wear is semantically wrong; the footprint field
  needs its OWN wear channel plus explicit door metadata.
- claude + codex showed agy's D4 (delete CanvasModulate, per-pixel luminance
  remap) de-grades the ground and has no material guard (roof highlight and bush
  leaf can share a luminance); `test/active_path/test_smoke_grade.gd` pins a
  CanvasModulate. The ground's final grade stays fixed.

## Decision (phase 3, synthesis)

Grade and fix the seams as a COMPOSED SCENE. The converged approach, taking the
better side of each conflict and grafting the winning parts of every proposal:

1. **D2 worn zone: an OFFLINE-baked, layout-derived ground field, sampled in
   `ground.gdshader`.** A new offline baker (extending the decision-011 lane-bake
   pattern) reads `build_inn_green_district()` and emits a committed
   export-visible field at lane-mask resolution (16 texels/cell, i.e. 256x224,
   NOT claude's 128x112), as a signed distance / coverage field to building
   footprints, with its OWN deterministic wear channel and explicit per-kit door
   metadata (grafted from codex). The shader samples it at a NAMED insertion
   point that leaves the frozen lane core / plate / detail semantics unchanged
   (this is "sampling the ground for a seam treatment," permitted; it does not
   retune any dirt bake). This is agy's footprint-via-lane-bake insight and
   claude's ground-space continuity, resolved OFFLINE per codex.

2. **D1 grounding shadow: offline basal-alpha contact + SHORT directional cast,
   extending `process_assets.py::derive_shadows` (which already exists).** One
   measured light vector inferred from the spike drives all casts. Shadows render
   on a below-sprite ground-plane layer (NOT a per-object bundle at the object's
   own z, which agy showed paints A's shadow across B's roof), and casts stay
   SHORT grounding pools so codex's long-cast painter's-order crossing never
   arises. The generic symmetric `shadow_decal.png` ellipse is retired. Basal
   silhouette, not the full-sprite shear (agy's shear projects roof/canvas and
   is invalid).

3. **D3 flora: offline ground-aware rematte + RGB decontamination + tight 1-2px
   feather + keep small leaf/flower components + per-kind tonal nudge + a basal
   contact nest.** Applies to `bush_a/b`, `flower_cluster_a/b`, `tree_large`,
   `crown_foliage` (crown gets decontamination + tonal only, no ground contact).
   Runtime alpha-smoothstep alone is rejected (cannot remove grey RGB). Paid
   Meshy regeneration is declined for the primary path (regen yields new cutouts
   with the same seam). HARD-STOP FALLBACK: if the one-hour matte spike proves
   the flora boundary RGB is not explained by a recoverable background (the
   `provenance: slice` polygon crops may carry painted grass from the spike, not
   uniform grey), stop destructive erosion and escalate a SCOPED regeneration
   rather than erasing petals.

4. **D4 lighting coherence: one measured shared light vector + measured per-kit
   tonal transforms with material guards, ground grade held FIXED.** The single
   light vector (item 2) plus per-kit tonal targets that protect roof / flower /
   highlight ranges bring the objects into one key. The village CanvasModulate
   stays as the fixed final grade; agy's per-pixel luminance remap is rejected.

Everything is render-side (`src/render/town/`, `assets/village/`, `tools/art/`);
`src/sim/` stays texture-ignorant (the offline baker reads the texture-free
layout, which is not a sim/render violation, confirmed by both peers). All bakes
are pure functions of their inputs (determinism holds) and ship through
`ResourceLoader` off `res://assets/village/` (export-safe), with a byte-stability
/ layout-drift CI assertion added (grafted from codex).

### The one contested synthesis question, and its ballot

The genuine fork was RUNTIME raster field (claude) vs OFFLINE-baked field
(codex, agy). Four ballots, read from the committed proposals and critiques:

- orchestrator: OFFLINE. Runtime raster is a regression in inspectability and
  byte-stability against the established decision-011 bake contract, it bypasses
  the already-existing offline shadow pipeline, and claude's specific runtime
  cast-height ordering is broken on the current manifest.
- codex-worker: OFFLINE (its proposal + critique argue this explicitly).
- agy-worker: OFFLINE (its proposal bakes `footprint_mask.png` offline).
- claude-worker: RUNTIME (held in its proposal and not conceded in critique).

**Result 3-1 for OFFLINE.** A 3-1 result decides without the critic seat (the
critic is invoked only on a 2-2 split, per decision 004). Ruling: OFFLINE-baked
field. claude's dissent is recorded verbatim below.

## Division of labor

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| Offline bakes: footprint SDF/coverage field with its own wear channel + door metadata; extend `derive_shadows` for basal contact + short cast under one light vector; flora ground-aware rematte + RGB decontamination + feather + tonal targets; manifest schema; byte-stability / layout-drift tests | codex-worker | Codex claimed this and is strongest at reproducible pixel processors, precise data flow, and making the export/byte contract testable. It is the bulk of the new machinery and extends the Python `process_assets.py` it already reasons about. |
| Render integration + tuning: sample the baked field in `ground.gdshader` at a named insertion point (lane core semantics unchanged); wire the below-sprite short-cast/contact shadow layer, retiring `shadow_decal.png`; apply per-kit tonal transforms; keep the CanvasModulate grade; run the capture-inspect loop against the spike across D1-D4 at 0.5x/1x/2x | claude-worker | claude claimed the render/GDScript/shader core and demonstrated the capture-inspect visual loop pulling the live composed frame. This slice needs that loop to tune the seams to Scott's eye. |
| Composed-scene QA seat: apply the binding `qa-rubric-composed-scene.md` (D1-D4 at 1x vs the spike), decode the committed PNGs, verdict CONFUSABLE / NOT-CONFUSABLE with precise tells | agy-worker | agy is the round's QA seat; its footprint-via-lane-bake insight is adopted into codex's slice, and its Gemini-family read is the independent third eye on the composed result. |

The two build slices pipeline (codex bakes assets + fixes the schema; claude
consumes them and tunes against captures), with cross non-author sign-off each
way, then agy's QA against the new rubric. If QA clears CONFUSABLE, the build is
surfaced to Scott for his OWN playtest verdict before any village expansion.

## Dissent

claude-worker held the RUNTIME field against the 3-1 offline ruling. Its
position, verbatim from its proposal
(`dcbd23ec1065ad89cdf1e9ef3773bfcedb40b266`):

> This is CPU computation of DATA into `Image.create` +
> `ImageTexture.create_from_image`, NOT the banned `Image.load` of a game
> texture. It is the exact pattern lanes used before decision 011 baked them
> offline; footprints come from sim placement at runtime so they cannot be a
> committed offline bake without re-baking per layout, which is why this one
> stays runtime.

And its scale argument, verbatim from its critique
(`c615220a4a7554544b48260d4166baf5d60e00f8`):

> My field is O(1) textures regardless of building count and any placement
> grounds automatically.

This objection did not claim a constitution violation, so it is decided by the
orchestrator rather than escalated. It is answered in the ruling: the current
map is a single frozen authored district, so re-baking per layout is a bounded
offline step with a CI drift guard, and the inspectability / byte-stability of a
committed field outweighs runtime O(1) generation for a finite authored map. If
and when arbitrary runtime placement lands (a later milestone), a runtime field
extension is revisited then rather than adopted now.

No other losing objection survived phase 2: codex conceded its per-object
interaction decal and agy conceded its D1 shear, D3 runtime feather, and D4
luminance remap, each in its own critique.

## Protected paths touched

None. This decision covers `src/render/town/`, `assets/village/`, and
`tools/art/`, none of which appear in `.github/protected-paths.txt`. `src/sim/`
is protected and is explicitly out of scope for this round.
