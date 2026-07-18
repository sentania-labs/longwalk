# claude-007: Two Rivers village at spike fidelity

Proposal for round 007. Author: claude-worker. Blind phase-1 submission.

## The one insight that drives everything

Round 006 tried to reach the spike bar by generating 3D (Meshy/Blender) and
rendering it down to iso sprites, and BOTH candidates missed: A was NPR
under-tuned, B was texture-space photoreal-clash (TEAM-STATE 07078d1). That is
two independent failures of the same family of method against this exact bar.

The reason is a medium mismatch. `docs/art/iso-five-asset-spike.png` is a
PAINTERLY 2D composition: hand-painted slate roofs with moss stipple, painted
timber grain, soft painted grass, painterly cast light. A 3D-render-to-sprite
pipeline has to reconstruct that painterliness from geometry plus shaders, and
it lands either flat (under-tuned NPR) or too clean/photoreal (clash). You are
fighting the medium.

So the highest-confidence path to "confusable with the spike" is to STAY in the
spike's own medium and, better still, to BOOTSTRAP FROM THE SPIKE'S OWN PIXELS.
The spike is not just a style target, it is already a kit: two half-timbered
cottages, a blacksmith with anvil and grindstone and lean-to, a mature tree,
flowering bushes, wooden fences, a sign post, flower beds, rocks, stone stairs,
and a painterly grass field with a dirt lane. That is most of a village
already, at literally-spike fidelity, because it IS the spike.

## 1. APPROACH

### 1a. Art production method: slice-the-spike, then style-locked 2D variants

Primary method, zero Meshy credits: cut the spike's own objects into individual
anchored iso sprites. Each becomes a PNG with a transparent background and a
recorded ground-contact anchor, run through the round-006 `process_assets.py` +
`manifests/process-iso.json` anchoring pipeline (reused verbatim, it already
does anchor + resize + contact-shadow slicing). Output kit from the spike alone:

- `cottage_large` (left building), `cottage_small` (front building),
  `blacksmith` (right building + lean-to + anvil + grindstone as one sprite)
- `tree_oak`, `bush_flowering`, `fence_wood` (tileable segment), `sign_post`,
  `rocks`, `flowerbed`, `stairs_stone`
- `grass_field` (tileable crop of the painted grass), `dirt_lane` (painted
  path sprite / edge pieces)

That kit is spike-fidelity by construction. It carries the whole first
buildable milestone with no generation risk and no credit spend.

Secondary method, for VARIETY so the village does not read as three copied
buildings: generate a small number of additional buildings by
image-to-image conditioned ON the sliced spike buildings themselves (Meshy
`meshy_image_to_image`, nano-banana-pro, 9 credits each), prompt = "same
painterly isometric half-timbered style, a [village inn / barn / mill /
Wisdom's cottage], slate roof, timber frame, stone foundation". Conditioning on
our own sliced pixels (not a text prompt from scratch) keeps style drift near
zero, which is the failure mode that killed the round-006 variants. Budget: 5
new buildings x 9 = 45 credits, hard cap. If drift shows, fall back to
recoloring/reroofing the sliced originals (0 credits) and ship fewer distinct
buildings. The build does not DEPEND on any generated asset: spike-slice kit is
the floor, generation is upside.

Why not 3D/Meshy-to-render again: it already failed this bar twice. Why not
hand-authored pixel art: it cannot hit painterly high-fidelity at village
volume in a round. Why not one giant painted scene: see 1b.

### 1b. Village composition: iso-placed sprites on the grid (extend, not repaint)

A composition of individual anchored building/prop sprites placed on the tile
grid, extending `src/sim/town_layout.gd` (authored DATA) and
`src/render/town/starter_town.gd` (the sprite/depth assembler). NOT one large
painted scene.

Rationale: the frozen projection + footprint-aware depth-sort contract
(`src/render/iso/projection.gd`: `cell_to_screen`, `building_contact_cell`,
`depth_key`) already solves back-to-front occlusion for placed sprites, and a
free-cam over a grid of sprites stays crisp at every zoom. A single painting
either pixelates when the free-cam zooms in or must be authored enormous, and
it throws away the depth spine and is not extensible toward the eventual
walkable/NPC village. Sprites on the grid is the architecture the rest of the
roadmap already assumes.

Data flow (unchanged shape from round 004/006, only bigger and prop-aware):
`town_layout.build_two_rivers()` returns ground tiles + an authored list of
placements (buildings AND props). `starter_town.gd` reads it, builds ground
diamonds, places each sprite at its projected contact anchor, ranks z by
`depth_key`. I extend `BuildingPlacement` with a lightweight `is_prop` /
non-colliding flag so trees, bushes, fences, signs place and depth-sort but do
not add physics bodies (no PC to collide this round anyway; keeps sim data
honest for later).

Scope of "full village" (I am resolving the ambiguity, and naming it): a
representative Two Rivers slice, roughly 12 to 16 structures, not the entire
canonical map. Concretely: a central Winespring-Inn-scale building (the one
generated large building), the smithy (spike blacksmith), a Wisdom's cottage, 6
to 9 cottages (spike cottages plus recolor/variant), the Green (an open grass
plaza the lanes ring), dirt lanes connecting them, and prop scatter (tree
clusters, bushes, fences, wells, sign, flower beds, rocks). Stretch, explicitly
cut from first-buildable: the two actual rivers with bridges (the namesake) as
painted water-tile bands with a bridge sprite. Also cut: interiors, day/night,
any NPC or PC, any interactivity beyond camera.

### 1c. Free / disincorporated camera: a clean no-PC mode

Minimal change, follow path preserved intact for future PC rounds:

- `CameraRig2D`: add `setup_free(layout)` alongside `setup(player, layout)`. It
  computes `_projected_bounds` and zoom levels exactly as today but leaves
  `_player == null`, sets `_state = State.FREE`, and positions at the CENTER of
  `_projected_bounds`. The existing `_process` FOLLOW branch already guards on
  `_player != null`, so it is inert. Drag-pan and cursor-preserving zoom already
  work in FREE/DRAG (they do not touch `_player`). `center_on_player` is
  rebound in free mode to recenter on the bounds center instead of a player.
- Rendering: rather than gut `starter_town.gd`, add a sibling scene
  `scenes/village_view.tscn` + `src/render/town/village_view.gd` that reuses the
  same ground/building/depth code (I will factor the shared assembly into a
  small helper or a `spawn_player := false` guard, whichever is the smaller
  diff) and simply does NOT call `_spawn_player()` / player-dependent
  `_build_click_marker`, and calls `_camera_rig.setup_free(_layout)`. The
  starter-town PC scene stays exactly as it is.

This is the smallest change that gives a genuinely disincorporated camera
without regressing the follow rig or the PC scene.

### 1d. Export-safe asset story (the gate that silently failed before)

The rule from the assignment: art in a `.gdignore`'d tree loaded via raw
`Image.load`/`FileAccess` off `res://` is EXCLUDED by a stock export, so the
`.exe` ships default art. Note the current code already smells of this: it
`load()`s from `res://tools/art/out/processed/...`, a tools/ subtree that is a
prime candidate for export exclusion.

Fix, three parts:

1. Final village art lives under `res://assets/village/` (a normal, NOT
   `.gdignore`'d resource tree), committed WITH its Godot `.import` sidecars so
   the exporter's dependency walker sees real imported `CompressedTexture2D`
   resources.
2. Loaded via `preload`/`load()` of the `res://assets/village/...` path (a
   resource reference the export dependency walker follows), never via
   `Image.load` of an arbitrary file path. `export_presets.cfg` gets an explicit
   include filter for `assets/village/*` as belt-and-suspenders.
3. Verified from a PACKAGED artifact, not from source. I add
   `tools/verify_export_assets.sh`: export a headless `.pck` (or the `.exe`),
   then run the acceptance harness against the PACKAGED build and assert each
   village texture loaded (non-null, correct dims) AND assert the pink
   placeholder path was NOT taken. A missing asset reds this check. This is the
   "cannot silently regress" guarantee and it is the difference between round
   006's deliverable and a provable one.

### 1e. Round-006 reuse (carry / drop, explicit)

Carry forward:
- `acceptance-harness` (`refs/archive/006/acceptance-harness`,
  adaf9a0): directly reusable as the confusable-with-spike screenshot harness
  and as the packaged-export asset check above. This is the single most valuable
  carry.
- `process_assets.py` + `manifests/process-iso.json` anchoring pipeline: reused
  verbatim to anchor sliced/generated sprites to the `building_contact_cell`
  contract.
- scale-contract / decision-010 render-scale math: reused to size building
  sprites consistently on screen (px/m), so the inn is not accidentally the same
  height as a cottage.
- Meshy provenance patterns (`*.generated.json` manifests) for any generated
  variant, so asset origin stays auditable.
- `nullfix` if it is the Godot null-guard I think it is; confirm on read.

Drop / do not rebuild:
- The Blender headless render + camera-calibration pipeline
  (`blender_calibration.py`, `blender_pose_rig.py`) and Meshy 3D generation for
  buildings. We are not rendering 3D this round; this is the machinery whose
  output missed the bar twice. Dropping it is most of why this proposal is
  cheaper and lower-risk.

### 1f. First buildable milestone

A packaged Windows build (or an isolated-project `.pck`, whichever the harness
proves faster) that: opens directly to a FREE drag-pan + zoom camera over a Two
Rivers village of at minimum the three spike-sourced buildings + tree + bushes +
fence + sign + rocks on an authored grid with painted dirt lanes and grass; NO
PC, NO NPC; and whose village art is PROVEN present in the packaged artifact by
the acceptance harness (screenshot + non-placeholder assertion). The
acceptance screenshot placed beside the spike is the pass/fail test.

## 2. RISKS

- Does slicing actually reach spike fidelity? This is the strongest part of the
  proposal (the assets ARE the spike) and its main failure mode is clean
  extraction: in the spike the front cottage overlaps the left one, the
  blacksmith sits behind a fence, and shadows are soft, so cutting clean alpha
  edges is fiddly manual masking. Mitigation: cut generous, keep the soft cast
  shadow with the sprite, and where an object is occluded regenerate just that
  one via image-to-image conditioned on the visible part. One hour + one
  question I would spend first: mask the three buildings and drop them onto a
  fresh painted-grass field at the projected anchors, screenshot, and eyeball
  against the spike. If that composite is confusable, the whole approach is
  de-risked; if it reads as pasted cutouts (edge halos, lighting seams), I learn
  that immediately and pivot the variant budget toward reroofed regenerations.
- Does the art survive a stock export? Believed yes via the `res://assets` +
  `.import` + packaged-verify plan, but the `.import` sidecars require the
  editor to have imported the assets once; a headless CI that never opens the
  editor can produce a `.pck` missing the `.ctex`. Mitigation: the verify script
  runs a `--headless --import` pass first, and asserts against the packaged
  artifact so a miss is loud.
- Style drift on generated variants: the round-006 killer. Mitigated by
  conditioning on our own sliced pixels rather than text-from-scratch, and by
  making zero generated assets load-bearing (spike slices are the floor).
- Tiling monotony: a village of three repeated sprites reads fake even at spike
  fidelity. Mitigated by variants + per-placement rotation/flip + recolor, and
  by prop scatter breaking up the grid. Residual risk if variant generation
  underdelivers; falls back to more recolors.
- Free-cam over a large grid: `projected_bounds` + zoom clamp already exist and
  are frozen; low risk. Watch that tall back-row buildings are not clipped by
  the bounds headroom (the contract already takes a headroom arg).

## 3. DIVISION-OF-LABOR CLAIM

I (claude-worker) am best suited to own the RENDER INTEGRATION + FREE-CAM +
EXPORT-SAFETY + ACCEPTANCE-WIRING slice, plus the Two Rivers LAYOUT DATA in
`town_layout.gd`. That is the GDScript-and-plumbing spine of the deliverable:
extending the sprite/depth assembler against the frozen projection contract
(which I have read closely here), the clean no-PC free-cam mode, and above all
the packaged-export verification that is the difference between a real build and
a silently-default one. This matches my strengths (careful reading of the frozen
contracts, Godot scene/export mechanics, test/harness wiring).

The pure ASSET-PRODUCTION slice (spike slicing, mask cleanup, image-to-image
variant generation, process-iso anchoring) is separable and is plausibly better
owned by codex-worker, which owned and built the round-006 art pipeline and
`process_assets.py` and has the deepest context on the anchoring manifests. I
would rather consume its anchored sprite kit at the frozen anchor contract than
rebuild that pipeline. If instead the team wants one owner end-to-end, I can take
the slicing too, since it is mostly masking + reusing the existing pipeline, but
the natural seam is asset-kit (codex) feeding scene-integration (me) at the
`building_contact_cell` anchor contract, exactly as round 006 seamed.

## 4. ROUGH ESTIMATE

Order of magnitude: a few focused work sessions, roughly 2 to 4 days of agent
work total across the slices.

- Asset kit (slice + mask + anchor + up to 5 image-to-image variants): ~1 day,
  ~45 Meshy credits max (0 if variants are cut).
- Layout data + render integration + free-cam + prop-placement: ~1 day.
- Export-safe move + packaged-verify script + acceptance harness wiring: ~0.5 to
  1 day.

What blows it up: (1) spike slices read as pasted cutouts and the village needs
mostly-regenerated buildings instead, pushing credits and iteration up; (2) the
headless-export `.import` mechanics fight the packaged-verify gate and eat a day
of build plumbing; (3) scope creep into the literal full Two Rivers map or the
two-rivers-and-bridges namesake before the first buildable proof exists. The
milestone is deliberately drawn to cut all three: prove the packaged free-cam
village with the spike-slice kit FIRST, add variety and rivers second.
