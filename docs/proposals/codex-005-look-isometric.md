# Codex proposal: round 005 isometric visual identity

## 1. Approach

### Scope and visual target

I would rebuild the visible starter town as a small, authored isometric scene, not attempt a general map editor or a large content library. The shipped slice would contain:

- one coherent terrain family for grass, packed earth road, road edge transitions, and a few low ground accents;
- three building identities already present in the town, regenerated as grounded isometric structures with readable entrances and silhouette shadows;
- a flora family with one large canopy tree, one young tree, two shrubs, grass clumps, and two flower clusters, with restrained deterministic animation on selected flora;
- one player identity with an eight-facing, six-frame walk cycle;
- render-side isometric projection, picking, depth ordering, camera bounds, and right-drag map panning;
- generated-art provenance, deterministic processing manifests, automated structural gates, and the walk GIF plus before/after screenshots for Scott.

I would leave out seasons, weather, day/night lighting, animated building interiors, NPC crowds, a minimap, generalized authored-map tooling, and persistence. I would also leave the town layout and all navigation behavior unchanged. Nothing under `src/sim/` changes.

The target is our own clean pixel-inspired painted style: compact silhouettes, warm earth and moss colors, restrained texture, dark value separation at contacts, northwest light, and enough exaggeration to read at gameplay zoom. The references establish density, projection, and readability, not assets to imitate or ship. The rejected screenshot specifically shows what must disappear: billboard-like facade rectangles, square-grid presentation, isolated token flora, inconsistent actor scale, and ungrounded objects.

### 1. Generation method: coherent category sheets, led by a full-scene style board

I choose full-sheet coherent generation as the primary method, but not one physically enormous atlas containing every final object. A single all-purpose sheet gives palette consistency but gives buildings and animation frames too little area and makes extraction failures correlated. Fully independent per-asset prompts produced the current collage effect. The workable middle is a generated coherence master followed by a small number of category sheets that all use that master as a visible reference.

The generation flow would be:

1. Commit `tools/art/style/isometric-house-style.md` with palette swatches, 2:1 diamond geometry, northwest light vector, value ranges, outline policy, texture density, and gameplay-scale examples.
2. Generate `tools/art/reference/isometric-style-board.png`, a dressed in-world reference only, showing one road junction, one building, the player, a tree, shrubs, and flowers in a representative camera composition. Its prompt is committed beside it. It is not runtime art.
3. Generate a ground atlas as a coherent sheet, a compact-flora sheet as a coherent sheet, and separate one-by-one large tree and building assets. Before each call, make the style board visible and state that it controls palette, light, edge treatment, scale, and projection. Buildings and the large tree are one-by-one because their silhouette, contact, and collision alignment matter more than batching efficiency.
4. Generate each walk facing as its own 2x3 six-frame action grid using one accepted neutral player master and character-anchor sheet. The master locks identity, standing scale, feet line, and palette. The per-facing sheets are then assembled deterministically into the runtime atlas.
5. All raw sheets use solid `#FF00FF`, keep their prompts, and pass chroma cleanup, extraction, anchor, edge-touch, and scale gates before entering `assets/`.

This uses `generate2dmap` as `tile_mode`, `layered_tilemap`, `y_sorted_props`, `tile_collision`, and project-native Godot output. The existing authored town data remains the source of placement and collision truth. Generated pixels never become collision truth. It uses `generate2dsprite` for the player, transparent flora, and buildings, with one-by-one generation for large or collision-sensitive objects and a compact pack only for shrubs, grass, and flowers.

The first one-hour spike should generate just the style board, one ground family, one tree, one building, and one southeast walk grid, then compose them at the real camera size. If that composition does not read, the style contract is revised before producing the rest.

### 2. Facing count and frame-selection policy

I choose eight facings. Four diagonals are projection-correct at rest, but click-to-move produces arbitrary vectors. Folding east and southeast, for example, into one pose creates obvious sideways skating on long shallow paths. This round is explicitly about a believable walking character, so four is false economy.

The policy is written and tested before any final walk generation in a render-side helper such as `src/render/town/isometric_direction.gd`:

- transform the sim-space motion vector into projected screen space;
- quantize `atan2` to the nearest of eight fixed 45 degree sectors with a documented boundary convention;
- map sectors to immutable facing ids `n`, `ne`, `e`, `se`, `s`, `sw`, `w`, `nw`;
- advance a six-frame `contact, down, passing, up, contact-opposite, passing-opposite` cycle from accumulated distance traveled, not wall-clock time, using a fixed stride distance;
- freeze on a designated neutral frame at zero movement, preserving phase briefly only if testing shows it prevents flicker;
- never choose a different source frame because it looks better in a particular direction.

The generated sheet manifest records the exact facing and frame role for every cell. `build_player_walk.py` becomes a generic assembler driven by that manifest. Mirroring may be used only if declared in the manifest before generation and validated against asymmetric costume details. My default is eight authored facings, no runtime mirroring.

### 3. Repurpose the ingest pipeline

The Kenney-specific name and assumptions should not survive. If `ingest_kenney_roguelike.py` exists on the integration base, replace it with `tools/art/ingest_generated_sheet.py`; if it was dropped with the round-004 art slice, create only the generic entrypoint. It accepts a committed JSON manifest containing prompt path, raw image path, grid geometry, cell roles, magenta key, anchors, expected dimensions, generation identifier, and output ids. It rejects missing prompt provenance, unexpected grid sizes, edge touch, empty cells, and undeclared runtime assets.

`process_assets.py` survives as deterministic image processing, but loses hard-coded asset lists and reads manifests. It may chroma-key, despill, crop, normalize to a shared scale profile, generate shadow masks, slice sheets, and write QC metadata. It may not draw missing art or make aesthetic selections.

`build_player_walk.py` survives in purpose but is rewritten as manifest-driven assembly. The old cardinal and hand-authored Option C policy is removed. Facing order, six frame roles, anchors, stride phase, and any mirror policy come from a versioned walk contract shared with the runtime tests.

`build_walk_comparison.py` is renamed `build_isometric_walk_preview.py` and produces eight directional GIFs plus one diamond-route GIF from processed frames. `capture_art_acceptance.gd` survives as a real-engine capture harness, changed to capture the same authored camera frame before and after, at shipping zoom and nearest-neighbour filtering. It must not use a bespoke acceptance-only scene composition.

I would keep generated raw sources and prompts under `tools/art/`, processed runtime assets under `assets/art/isometric/`, manifests beside their asset families, and acceptance output under `docs/art/round-005/`. The generic pipeline tests should cover manifest parsing, stable hashes, alpha, edge contact, anchors, dimensions, declared roles, and byte-identical rebuilds.

### 4. Isometric rendering, shadows, grounding, and camera amendment

Add a render-only `src/render/isometric_projection.gd` with pure functions:

```text
screen_x = origin_x + (grid_x - grid_y) * half_tile_width
screen_y = origin_y + (grid_x + grid_y) * half_tile_height
```

and the algebraic inverse for picking. `starter_town.gd` asks the existing layout for grid positions, projects them only while creating render nodes, and keeps navigation requests in grid/world coordinates. `player_controller_2d.gd` inverse-projects click locations before passing a destination to the existing layout/navigation API. Tests round-trip cell centers and boundary samples, including negative local offsets and diamond edges. No projection symbol or screen coordinate enters `src/sim/`.

Render structure should be explicit: ground diamonds in a non-sorted base layer, then one Y-sorted world-object layer containing the player, flora, and buildings. Each tall sprite has its origin at its ground-contact anchor and sorts on projected contact Y, with a stable secondary key derived from authored placement id for ties. A building's render anchor remains separate from its sim footprint.

Every player and prop gets a small soft contact ellipse authored or preprocessed from its mask. Buildings additionally get preprocessed silhouette shadow sprites: take the cleaned alpha mask, flatten and shear it along one shared southeast shadow vector, blur only the outer edge, tint to one cool neutral color, and anchor it at the building contact. This is a deterministic processor output, not a runtime light simulation. The ground-contact darkening remains separate and tighter so buildings do not float even where the long shadow crosses a similar-valued road.

Flora becomes living without procedural placement or random animation. Large tree leaves use two or three generated overlay frames with trunk and root contact held fixed. Phase is a stable function of authored placement id, and playback uses a fixed period. Small flower and grass clusters use a tiny deterministic vertex or frame sway only if it survives nearest-neighbour rendering cleanly. No `randf()`, no time seed, and no motion of the ground anchor. Tall walkable flora declares `occlusionClass`, `actorSafeArea`, and `occupantPolicy`; the safe default is `rear_shift_and_fade`, applied render-side to foliage only, never the ground tile.

The camera rig keeps FOLLOW and FOCUSED semantics but changes how FOCUSED is entered. `focus_view` in `project.godot` binds the right mouse button. Press records mouse position and camera position. Motion beyond a small pixel threshold enters drag-pan, updates camera position by negative screen delta divided by zoom, and clamps against the projected diamond bounds. Release ends the drag without recentering. A press and release below the threshold does nothing, removing point-recenter as the primary interaction. Space returns to FOLLOW. Wheel zoom remains and preserves the map point under the cursor so zoom does not feel like a jump.

The old right-click focus picking path is therefore removed from normal camera input. Iso screen-to-world remains required for left-click movement and for any future focus/overview action. Camera limits must be computed from the four projected map corners plus sprite headroom, not from `_layout.pixel_size()` as an orthogonal rectangle.

### 5. Acceptance artifacts and gate

The round ships:

- `docs/art/round-005/isometric-walk-cycle.gif`, showing a diamond route with all eight facing transitions at shipping scale;
- `docs/art/round-005/before.png`, the supplied rejected camera frame or the closest reproducible pre-change frame, clearly labeled;
- `docs/art/round-005/after.png`, the actual starter town at the same viewport and comparable framing;
- `docs/art/round-005/acceptance.md`, recording commands, asset manifests, build commit, and limitations without claiming Scott accepted it.

Automated checks can prove projection round trips, unchanged sim tests, deterministic processing, correct frame policy, anchors, no outside assets, valid alpha, nearest-neighbour settings, and capture completion. They cannot prove taste. Scott alone gives the visual verdict.

## 2. Risks

The largest risk is that full-sheet coherence does not survive category handoff. Image generation can shift roof geometry, palette, or light even with a visible master. My proposal looks worse than a single giant sheet on this point. The mitigation is an early real-camera composition spike and rejection of whole category passes, not post-hoc color grading that hides inconsistency.

Eight facings multiply generation and identity drift. A six-frame cycle across eight separately generated grids can produce 48 individually plausible frames that do not animate as one person. The character anchor sheet and shared scale profile control geometry but cannot repair costume or anatomy drift. If the one-facing spike fails, I would test a coherent four-facing sheet plus deterministic mirrored companions before spending all eight calls, but I would not silently reduce the shipped facing contract without a synthesis change.

Pixel-inspired image generation can create false pixel detail that breaks when rescaled. Nearest-neighbour rendering only helps if the source was normalized to a deliberate pixel grid. The art processor must reject inconsistent source scales, and the gameplay camera preview must be the authority rather than zoomed-in source beauty.

Diamond transition tiles are a generation risk. A generic full-bleed ground sheet may not join cleanly under rotation or adjacency. The first spike must include a road bend and T-junction, not only isolated pretty diamonds. If transitions fail, the round may need more authored terrain variants than estimated.

The existing town placement was designed for square-looking orthogonal sprites. Projection keeps sim footprints correct but can reveal visual overlaps, blocked doors, or narrow apparent paths. Moving authored render anchors is acceptable; changing sim placement is not. Some building silhouettes may need regeneration to fit the existing footprint.

Preprocessed building shadows can overlap roads and actors badly, especially at the map edge. A single shared light vector is coherent but may produce large dark masses. Shadow opacity and maximum length need a scene-wide test, not per-building tuning.

Foliage animation may read as wobble rather than life. Keeping roots fixed and animating only a small canopy overlay is safer, but costs extra asset passes. Occupant fading can also look artificial if it triggers abruptly; it needs a short deterministic render-side interpolation.

Drag-pan signs, zoom scaling, and projected bounds are easy to get subtly wrong. Input tests should assert that dragging right moves the map right under the cursor, that the camera moves left in world coordinates accordingly, and that zoom preserves the cursor's map point.

Given one hour and one question, I would build the five-asset composition spike and ask Scott: "Does this exact camera frame establish the right own-style visual direction strongly enough to produce the full family?" That answer is more valuable than asking about an isolated sprite.

## 3. Division-of-labor claim

I am best suited to own the generated asset pipeline and walk bundle: manual prompts, visible-reference handoff, `generate2dmap` category planning, `generate2dsprite` per-facing grids, magenta cleanup, scale profiles, deterministic assembly, QC, GIF export, and provenance manifests. Those tasks directly match the Codex image-generation harness and the mandated skills, and I can evaluate raw and processed images in the same workflow.

The resident who owns the current camera rig is better suited to implement drag-pan, cursor-preserving zoom, and projected camera bounds because that work depends on state-machine and Godot input context already built in round 004. A resident strongest in Godot scene composition should own projection integration, Y-sort structure, and acceptance capture. I should define the asset/runtime contracts with them, not claim all three slices.

## 4. Rough estimate

This is roughly 6 to 10 focused worker-days across three residents, plus Scott's review latency and possible regeneration:

- 1 to 2 days for the style-board and five-asset composition spike;
- 2 to 4 days for ground, flora, buildings, eight-facing walk generation, processing, and regeneration;
- 2 to 3 days for projection, depth ordering, grounding, shadows, camera drag, and tests;
- about 1 day for real-engine capture, artifact assembly, and integration fixes.

The estimate assumes existing town placement, navigation, and camera state machine remain intact. It grows to 12 to 15 worker-days if the road transition family requires substantial manual repair, eight-facing identity consistency needs several complete regeneration rounds, or the projected town exposes placement conflicts across most buildings. A request for a generalized map editor, new sim data, a minimap, or a second biome should be a later round, not allowed to expand this one.
