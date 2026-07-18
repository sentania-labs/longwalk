# 009: Two Rivers village art-production method (spike-fidelity, free-cam)

- **Status:** accepted
- **Date:** 2026-07-18
- **Assignment:** "Build me Two Rivers in that style. No NPCs, no PC, just a
  disincorporated move around the map. Just show me you can build a full-on
  village in that style." (Scott, via dalinar relaying req c3ffe894,
  2026-07-18T03:30Z). The style/bar is the spike itself,
  `docs/art/iso-five-asset-spike.png`.
- **Orchestrator run:** round 007, opened 2026-07-18 (`round/007-village` from
  `main` @ `07078d1`).
- **Lane:** full protocol (design-level, contested; touches protected paths).
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

Round 006 tried to reach the spike bar by generating 3D (Meshy) and rendering it
down to isometric sprites, and both candidates missed: A was under-tuned NPR
(muddy), B was a texture-space photoreal clash. Scott then ruled that the spike
IS the style and the bar (not a candidate to tune toward), and redefined the
milestone to a full Two Rivers village at spike fidelity, rendered in the running
game, with NO player character and NO NPCs, navigated by a free
("disincorporated") camera. Method is unmandated (Meshy available; use it,
don't, or mix), judged only on whether screenshots are confusable with the spike.
A mandatory carry-forward finding: authored art in a `.gdignore`d tree loaded via
raw `Image.load`/`FileAccess` off `res://` is excluded by a stock Godot export,
so a packaged build silently ships default art. The village art hits the same
problem, so an export-safe, export-PROVEN asset story is in scope.

This record covers the whole round-007 approach and the one contested question
that went to a four-ballot: the primary pixel-production method.

## Proposals (phase 1, blind)

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/007-proposal` | `cc83cb956d052880a65de9ea9254f7b8668e2606` |
| codex-worker | `codex/007-proposal` | `17d30086bee1a34b9d0124753fcf96917c4491ef` |
| agy-worker | `agy/007-proposal` | `87d4550800e23ab4feb12f941445ced740a7e8c0` |

- **claude (slice-the-spike):** cut the spike's own pixels into anchored iso
  sprites placed on the tile grid (zero-credit, spike-fidelity by construction);
  optional image-to-image variants conditioned on the slices; explicit
  `setup_free()` no-PC free-cam via a sibling village scene; export-safe via
  `res://assets/village` + a packaged-export verify. Diagnosed round-006 failure
  as a medium mismatch (a 3D-render pipeline cannot reconstruct painterliness).
- **codex (generated painterly districts):** freeze a brief + isometric blockout
  from the spike, generate six overlapping 2048px painterly district PLATES,
  assemble a master mosaic, extract only occlusion-crossing objects as separate
  layers. Argued AGAINST independent sprites ("stickers"); Meshy/Blender as a
  composition-guide fallback only; the strongest export gate (isolated packaged
  capture, non-placeholder assertion).
- **agy (3D-render):** Meshy 3D base models (20-40 credits) rendered through the
  round-006 Blender iso pipeline to grid sprites, stylized/img2img for
  painterliness; sprites-on-grid composition; free-cam via a null-player default;
  a static `Image.load` ban.

## Critique (phase 2, adversarial)

| Worker | Branch | Critique commit SHA |
| --- | --- | --- |
| claude-worker | `claude/007-critique` | `e30bee2e44d91f024987a36fbb0553aeb8586fe4` |
| codex-worker | `codex/007-critique` | `0c2914866d32f11bafb229da998097c12eeedbb6` |
| agy-worker | `agy/007-critique` | `dcc696d5ffd36d08a65b30601b807fa33e4247d4` |

A genuinely adversarial round, not "looks good." The load-bearing findings:

- **Against slice-first (codex, agy):** the kit does not exist as separable
  objects inside the flattened spike (occluded rear faces, hidden pixels, baked
  shadows/grass fringes); `process_assets.py` normalizes/anchors a supplied RGBA
  image but does NOT segment a painting or inpaint hidden pixels, so "reuse
  verbatim" is overstated; three source buildings cannot yield a 12-16 structure
  village without visible cloning (flips reverse roof pitch/facade/directional
  light; recolors preserve silhouettes); zoom-in exposes only source resolution;
  committing `.import` sidecars is wrong because the repo `.gitignore` ignores
  `*.import`/`.godot/`; the `is_prop` flag leaks render category into sim data.
- **Against plates (agy, claude):** baking flora/props/trees into static plates
  makes them non-entities in `src/sim/town_layout.gd`, which breaks sim/render
  separation AND the CLAUDE.md-declared future ecology sim (flora regrows, fauna
  hunt) -- agy's precise constitution-grounded objection; plates blur when the
  free-cam zooms IN (2048px native vs ~9200 screen px at zoom 2.0) and cannot
  depth-sort a returning PC; six-plate seams break on any single-plate re-gen;
  the fallback is the round-006 render family that already missed the bar.
- **Against 3D-render (codex, claude):** it repeats round-006's twice-failed
  experiment with no new falsifiable technique ("stylized shader" re-invites B's
  clash; "img2img" either warps the geometry that justified going 3D or drifts
  per-sprite); Meshy is not wired for agy's seat, so agy's own DoL claim to own
  it is unexecutable; 180MB raw-source storage untenable at scale.
- **Conceded across the board:** claude's sprite-on-grid composition and codex's
  isolated-packaged-capture export gate are the strongest and should survive
  synthesis whichever method wins.

## Decision (phase 3, synthesis)

Most of the round converged after critique and is ruled directly:

1. **Composition = sprites-on-grid** (discrete per-object sprites, each with its
   own `building_contact_cell`), NOT baked district plates/mosaic. codex conceded
   its plates are architecturally weaker for moving actors; agy's sim/render-
   separation + future-ecology critique is decisive. Ground/grass/lane may be a
   painted base layer; every vertical/interactable element is a discrete sprite.
2. **Export gate = codex's isolated-packaged-capture audit, adopted verbatim** +
   claude's non-placeholder assertion: stock export, copy the PCK/EXE to a temp
   dir with NO source tree, run headless, assert every declared village asset
   resolves through `ResourceLoader` with nonzero dims, capture, FAIL if the
   capture matches the placeholder/default fixture or a manifest asset is absent.
   The visual-judgment screenshot comes from that isolated packaged build.
3. **Asset location + mechanism:** runtime art under `res://assets/village/`
   (export-visible, not `.gdignore`d). Commit SOURCE PNGs, run the pinned engine
   `--headless --import` in the build/verify step, then export. Do NOT commit
   `.import` sidecars (repo `.gitignore` ignores `*.import`/`.godot/`). Do NOT add
   an include glob to the protected `export_presets.cfg` (it uses `all_resources`).
4. **`src/sim/town_layout.gd` stays viewport-free and texture-IGNORANT authored
   data:** semantic placement kind + footprint/collision policy only; texture
   paths, anchors, screen coords, render category live in the render layer. No
   render-driven `is_prop` in sim.
5. **Free-cam = an explicit `setup_free(layout, ...)` no-PC mode:** the village
   scene runs `spawn_player=false` (no `scenes/player.tscn`, no click marker, no
   click-to-move, no name label, no player collision); camera starts `State.FREE`
   centered on bounds; RMB drag-pan + cursor-preserving wheel zoom only; a test
   asserts no `CharacterBody2D` in the running scene and camera starts FREE. The
   existing `setup(player, layout)` FOLLOW path is preserved untouched.
6. **Drop 3D-Meshy-render as the primary pixel source.** Retain Blender /
   `blender_calibration.py` / the scale contract (`32*sqrt(6)` px/m upright) as an
   OPTIONAL projection/scale/landmark-registration guide only.
7. **Adopt agy's static `Image.load`/`FileAccess.get_file_as_image()` ban** for
   game assets in `tools/run_tests.sh` (backstopped by the real isolated-package
   gate). Keep agy on multimodal QA of every produced asset against the spike.
8. **Micro-cluster baking:** bake a tight multi-object cluster (tree+bush+fence-
   corner; the smithy-with-anvil-grindstone-lean-to as the spike paints it) as a
   SINGLE sprite where nothing will ever need to occlude BETWEEN members, to
   recover the spike's shared-light/shared-shadow integration. Each cluster keeps
   one contact cell; if a future ecology milestone needs one member individually,
   that cluster is un-baked in the render layer with no change to sim data.
9. **First buildable milestone:** ONE inn-green district at final pixel density
   (the inn/anchor building + 2-3 cottages + a lane junction + a large tree +
   fences + flowers + rocks + >=5 prop groups + >=1 separately-sorted foreground
   crown), free-cam, no PC/NPC, PROVEN from the isolated packaged export beside
   the spike, landmark-registered to `projection.gd` at 0.5x/1x/2x zoom. Method
   failure at that gate changes the method, not just the asset count. Expansion to
   the full ~12-16-structure village follows only after that district passes.

**Contested question (four-ballot): primary pixel-production method.** Options: S
(slice-first, claude's emphasis), G (generate-first, codex's emphasis), H (hybrid
graft). Ballots:

| Voter | Vote | Ballot SHA |
| --- | --- | --- |
| orchestrator | H | (this record) |
| claude-worker | H | `e2ab0c3819e77dbe5d75dab1ac470f8c0f0fffb7` |
| codex-worker | H | `10e0d69ddc8ba2cea9df417799e94337929ea162` |
| agy-worker | H | `828296b88f810a66320408544618671da6b71ac9` |

**Tally: 4-0 for Option H.** Decided without the critic (critic is invoked only
on a 2-2 split). Notably claude-worker, the author of Option S, voted against its
own proposal, conceding codex's occlusion critique is decisive.

**Ruling (Option H, hybrid graft):** SHIP the cleanly-separable, unoccluded spike
objects as sliced sprites (front cottage, tree, bushes, fence, sign, rocks,
ground/grass/lane): literal spike fidelity, zero credits, zero drift. GENERATE
complete RGBA objects via image-to-image conditioned on an accepted spike-derived
style crop for everything occluded or net-new (the rear cottage face, the compound
smithy split at planned occlusion boundaries, added building variety), with a
per-object provenance manifest each. A MANDATORY first-district gate at 0.5x/1x/2x
zoom + four-landmark `projection.gd` registration runs BEFORE any batch Meshy/
generation spend. H beats S because occluded objects have no pixels to slice and
must be generated complete; it beats G because it does not discard the spike's own
pixels (already at the target, zero drift) on objects that separate cleanly. The
pre-spend gate inverts round 006's spend-then-judge into judge-then-spend.

## Division of labor

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| Asset production: clean slicing, complete-object image-to-image generation, per-object provenance manifests, anchor + scale + landmark registration, the isolated-packaged export audit | codex-worker | Owns and built the round-006 art pipeline (`process_assets.py`), the scale contract, and the export-audit design; sprite-forge mandate. |
| Render integration: village scene + `setup_free()` no-PC free-cam, expanded `town_layout.gd` authored dataset (under this record), render-layer placement + depth against `projection.gd`, the `Image.load` static ban | claude-worker | Read the frozen projection/depth + camera contracts closely in phase 1/2; Godot scene/export/test-harness plumbing is its strength; keeps the layout/camera-geometry seat separate from the art-fidelity seat. |
| Multimodal QA of every produced asset against the spike at each gate; optional Blender guide renders | agy-worker | Can visually compare produced pixels to the spike directly (its genuinely differentiated card); separating the fidelity-judging seat from the seat owning the pixels prevents either flattering the other. |

All three accepted their slice in their ballots.

## Dissent

None. The four-ballot was 4-0 for Option H, no worker claimed a constitution
violation in the converged-and-ruled synthesis, and all three accepted their
division-of-labor slices. This is not a rubber-stamp "None": phase 2 was
genuinely adversarial (recorded above), and Options S and G lost on their merits.
The author of the losing Option S (claude-worker) voted for H over its own
proposal and stated the reason on the record (ballot
`e2ab0c3819e77dbe5d75dab1ac470f8c0f0fffb7`): "codex's occlusion critique is
correct, it is decisive, and my own proposal already conceded it in a footnote
instead of building around it."

## Protected paths touched

src/sim/
export_presets.cfg
project.godot

## Sign-offs

    Signed-off-by: claude-worker <claude@sentania.net> 2026-07-18T05:25:08Z
    Signed-off-by: codex-worker <codex@sentania.net> 2026-07-18T05:03:08Z
    Signed-off-by: agy-worker <agy@sentania.net> 2026-07-18T06:22:51Z
