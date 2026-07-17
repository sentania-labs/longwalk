# claude-worker, round 005 phase-1 proposal: make longwalk look isometric

Blind proposal. I have not read the other residents' proposals, branches, or
inboxes.

## What the rejection actually shows

Scott's `seriously-this-is-terrible.png` is not a palette problem. It is a
*staging* problem, and staging is what isometric fixes:

- The view is dead-flat top-down. Buildings are 2D grid-textured squares lying
  on the grass with no third dimension, no roof pitch read, no facade.
- Nothing is grounded. Buildings, trees, and flowers all float; there is not a
  single believable contact shadow in the frame.
- The world is a checkerboard of two tiles (flat green, flat brown) with a
  visible per-cell noise stipple. No transitions, no depth, no layering.
- Trees are orange blobs. Flora reads as decals, not objects with mass.
- An `Instance base is null.` error is painted over the top of it.

The reddit city-builder sheet in the reference folder (the existence proof) is
the exact inverse of every one of those: true diamond projection, buildings
with pitched roofs and side facades and hard cast shadows, layered ground,
flora with silhouette and shadow, and a status bar that literally reads "drag
the map to pan." That last detail is Scott's camera requirement, already
sitting in his own reference. This round is about closing the staging gap, and
the projection change is the lever that makes the rest legible.

## 1. Approach

### The spine: a render-side isometric projection, sim untouched

Everything isometric lives behind one small render-side module,
`src/render/iso/iso_projection.gd`. The sim keeps its square grid, integer cell
coordinates, `TownLayout`, and `NavGrid` byte-for-byte unchanged. No file under
`src/sim/` is touched. The projection is a pure function of a grid coordinate:

```
# src/render/iso/iso_projection.gd  (render-only, no sim dependency)
const TILE_W := 128   # diamond width  in screen px
const TILE_H := 64    # diamond height in screen px (2:1 iso)

static func cell_to_screen(cell: Vector2) -> Vector2:
    return Vector2((cell.x - cell.y) * TILE_W * 0.5,
                   (cell.x + cell.y) * TILE_H * 0.5)

static func screen_to_cell(screen: Vector2) -> Vector2:
    var a := screen.x / (TILE_W * 0.5)
    var b := screen.y / (TILE_H * 0.5)
    return Vector2((b + a) * 0.5, (b - a) * 0.5)   # inverse, for picking
```

`cell_to_screen` takes *fractional* cells so a continuously-moving player
projects smoothly, not just tile centers. `screen_to_cell` is the picking
inverse used by both click-to-move and camera drag.

**The Y-sort falls out for free, and that is why this shape is right.** Godot's
built-in `y_sort_enabled` orders siblings by `position.y`. If every entity's
node `position` is its *projected* screen position, then its `position.y` is
`(cell.x + cell.y) * TILE_H * 0.5`, which is exactly iso depth: things further
back (smaller x+y) sort behind things further front. We do not write a custom
depth comparator; we feed Godot the projected position and its existing y-sort
becomes correct iso ordering. This is the single most load-bearing claim in the
proposal, so attack it first.

### Data flow, concretely

`starter_town.gd` is reworked (render-side) so that:

- **Ground.** Instead of one axis-aligned `Sprite2D` per cell at
  `cell * TILE_SIZE`, each cell draws a diamond ground tile at
  `IsoProjection.cell_to_screen(Vector2(x, y))`, centered, under a non-y-sorted
  `GroundLayer`. Ground is always behind everything, so it does not participate
  in the entity y-sort; it draws in row-major (x+y) order into its own layer.
- **Buildings, flora, player.** All go under the existing y-sorted `World`
  node, each positioned at the projection of its *ground-contact* cell (the
  footprint's front/base cell for a building, the feet for the player). Tall art
  is drawn upward from that anchor via `Sprite2D.offset`, exactly the anchor
  trick the current code already uses at `starter_town.gd:121`; it carries over
  unchanged in principle, only the anchor position becomes projected.
- **Colliders / nav.** Unchanged in the grid. The nav grid already guarantees
  clearance by construction (decisions 003/006), so movement correctness does
  not depend on pixel-space physics.

### The player: steer in grid space, project for display

`player_controller_2d.gd` is reworked so the player's authoritative position is
a **continuous grid coordinate** (fractional cell), not world pixels. It steers
along the cell-center waypoints `NavGrid.find_path` already returns (in grid
units), lerping between them; each frame the render layer sets the node
`position = IsoProjection.cell_to_screen(grid_pos)`. This is the honest cost of
the override: the controller stops moving in square pixels. I would drop
`move_and_slide` for movement (nav is authoritative; colliders become advisory
for future dynamic obstacles) rather than try to run physics through a diamond.
All of this is render-side; `src/sim/` never learns it is drawn as a diamond.

**Facing (contested Q2), fixed in code before any art exists.** Facing is
chosen from the *screen-space* velocity vector (the projected delta between grid
positions), quantized by a fixed sector table:

```
# render-side, data-driven so 4 today and 8 later is a data change, not a rewrite
const FACING_ANGLES := [45, 135, 225, 315]   # SE, SW, NW, NE screen-space, deg
func facing_for(screen_velocity: Vector2) -> int:
    return nearest_sector(screen_velocity.angle(), FACING_ANGLES)
```

My call: **ship 4 diagonal facings this round** (the diamond's four screen
diagonals are the natural iso travel directions), with the selection code
data-driven on the angle table so adding the 4 cardinals to reach 8 is a
one-line data edit plus regeneration, not a code change. The walk sheet is the
most expensive artifact this team produces; 8 doubles that cost for a smoothness
gain Scott has not asked for. The sector table is committed *before* generation,
which satisfies decision 006 ground 7's no-laundering rule: the frame/facing
selector is blind code, never an eyeballed per-frame pick.

### Generation method (contested Q1): coherent plates, not per-asset, not one mega-sheet

My read: **the vibe gap is a method problem, and per-asset generation is the
proven failure.** The rejected screenshot *is* the output of per-asset
generation against a shared `style.md` harness; that method already shipped and
Scott rejected it emphatically. A shared text style guide does not enforce
shared lighting, shared palette quantization, or a shared horizon; each render
re-rolls them, and the set reads as unrelated pieces pasted together, which is
finding-for-finding what the screenshot shows.

But a single monolithic sheet for *everything* is too rigid: you cannot
regenerate one bad building without disturbing the player, and Godot wants
individually anchored sprites anyway.

The synthesis I propose is **coherent plates**: generate related assets *in
groups that share one render*, one plate per family:

- Plate A: ground diamonds (grass, path, and the grass/path transition edges).
- Plate B: buildings (the general store + cottage, drawn in the same iso frame,
  same light, same roof language).
- Plate C: flora (2-3 trees + 2-3 bushes/flower clusters, same plate).
- Plate D: the player walk cycle (its own coherent sheet, per decision 005's
  surviving method).

Coherence comes from two locked things, not from prose: (1) a **fixed
generation spec** committed to `style.md` giving the exact iso angle (2:1),
light vector (upper-left), and a named palette ramp; and (2) **carry-forward
reference**, feeding an accepted earlier plate back in as a style anchor for the
next plate so palette and lighting propagate across plates, not just within one.
This is the reddit sheet's coherence mechanism reproduced deliberately.

### Repurposing the ingest pipeline (contested Q3)

- `tools/art/ingest_kenney_roguelike.py` is **deleted and replaced** by
  `tools/art/ingest_sheet.py`: a generic plate slicer that takes a plate PNG
  plus a committed JSON slice manifest (`plates/<name>.json`: cell grid, per-cell
  output name, and the ground-contact anchor point per sprite). The anchor in
  the manifest is the contract the projection depends on; it is authored code,
  not eyeballed at runtime.
- **Survives generic, retargeted:** `process_assets.py` (background flood-fill,
  crop-to-content, resize, tunic recolor) and `build_player_walk.py`
  (deterministic option-C walk assembly) carry over as-is; they were never
  Kenney-specific. `build_walk_comparison.py` and `capture_art_acceptance.gd`
  survive as the **acceptance-artifact generators**, retargeted to render the
  iso scene for Scott's GIF and before/after screenshots.
- The Kenney-specific atlas-layout assumptions and any `CREDITS.md` Kenney entry
  are removed; no third-party pack appears in any merged result.

### Shadows and grounding (contested Q4)

Two shadows per grounded object, per decisions 006 grounds 6/7 regenerated for
iso, and this is the direct fix for the "everything floats" defect:

- **Contact shadow.** A small squashed *iso* ellipse (a diamond-proportioned
  `Polygon2D`, ~2:1) drawn on the ground plane at the object's base, tight and
  dark. This replaces the current oversized centered blob
  (`starter_town.gd:_create_shadow_polygon`) that decision 006 ground 7 already
  flagged as "too big, too soft, too centered to read as contact."
- **Cast shadow.** A preprocessed silhouette mask (a `process_assets.py` pass,
  baked offline, *not* a runtime facade shear which 006 ground 6 rejected),
  projected along the fixed upper-left light vector and drawn on the ground
  layer *under* the entity so it is not y-sorted against it.

### Camera: drag-pan (contested Q5)

Rework `CameraRig2D` (agy-worker's round-004 rig is the base, not discarded).
Add a `DRAG` state to the existing `FOLLOW`/`FOCUSED` machine:

- Right-mouse-button **press** enters `DRAG`; while held, accumulate
  `InputEventMouseMotion.relative` and move `position` inversely (scaled by
  `1/zoom`), clamped to the existing `limit_*` extents. Release returns to the
  prior state. This is Scott's (a), THE requirement.
- `project.godot` gains a `pan_drag` action bound to the right mouse button.
  Right-click-to-focus (the old `focus_view`) is retired as the primary verb;
  drag replaces it, matching Scott's "OK but not what he wants" verdict.
- Space still returns to `FOLLOW` (survives). Edge/scroll pan (Scott's (b)) I
  scope as an **optional** follow-on if the drag lands with time to spare;
  minimap recenter (his (c)) is a stated design seed for later, explicitly out.
- **Picking amendment:** click-to-move picking in `starter_town.gd:166` and the
  drag/focus math stop using `world_to_cell` (square) and route through
  `IsoProjection.screen_to_cell`. This is the render-side iso-picking amendment
  decision 006 ground 5 called for.

### What ships vs. what I cut

Ships this round: the iso projection spine + reworked ground/building/player
render, drag-pan camera + iso picking, iso shadows/grounding, one coherent
plate set (ground + 2 buildings + a few flora + 4-facing walk), and the
acceptance artifacts. Cut/deferred, stated plainly: 8 facings, animated flora,
building variety beyond the two we have, edge-pan and minimap, and any
persistence of the new delta layer. Flora is in scope because it is a hard
requirement asked three times; breadth of flora is not.

## 2. Risks

- **The Y-sort-by-projected-position claim is the whole spine. If it is wrong,
  the plan is wrong.** The known failure mode: a tall building whose anchor cell
  sorts correctly can still visually overlap a player standing in a cell it does
  not strictly occupy, because a 2:1 sprite covers cells behind its anchor. This
  is the classic iso "large object straddles the sort line" problem. Mitigation:
  keep footprints small (1-2 cells) this round and split any building wider than
  its art can sort as. Given one hour and one question I would first stand the
  player behind and beside each building at shipping zoom and confirm the sort
  reads, before generating a single final asset.
- **Dropping `move_and_slide` for grid-space steering is a real behavior
  change.** If a future dynamic obstacle (an NPC) needs physics collision, this
  slice makes colliders advisory and that work returns. I judge that acceptable
  now (nav is authoritative, town is static) but it is a debt I am choosing, and
  it makes my own approach look heavier than "just reproject the sprite."
- **Generation coherence is a hypothesis, not a guarantee.** Carry-forward
  reference plates *should* propagate palette and light, but I cannot prove the
  generator honors an iso angle and a light vector consistently across four
  plates until we run it. This is the single biggest schedule risk and it is not
  mine to execute (see below). If plates come back incoherent, the fallback is
  fewer, larger plates (toward the mega-sheet end) to force one render context.
- **Anchor contract drift.** If the generated art's ground-contact point does
  not match the manifest anchor, buildings float again in iso. The manifest +
  `ingest_sheet.py` is the guard, but it only works if generation and projection
  agree on the anchor convention *before* art is made. That agreement is a
  cross-slice dependency I would nail down in the first hour.
- **The projection is not in `src/sim/`, but `TILE_SIZE` already sits in
  `town_layout.gd:18`.** I am not touching it, but the pre-existing pixel-space
  wart in the sim (flagged in decision 006) means a careless reviewer might
  think iso constants belong there. They do not; I keep all of `TILE_W`/`TILE_H`
  render-side and will say so loudly in review.

## 3. Division-of-labor claim

**I am best suited to own the render-side isometric spine: the projection
module, the `starter_town.gd`/`player_controller_2d.gd` rework, the y-sort
integration, the picking inverse, and the drag-pan camera rework.** This is the
architectural condition of the whole override (all iso math render-side, sim
untouched), it is pure GDScript I can reason about and verify in-engine, and it
is the piece every other slice depends on, so it should be owned by whoever will
also defend the sim/render boundary hardest in review. That is the work I did on
the round-004 road slice and the boundary argument in decision 006.

**The art generation execution is genuinely better owned by codex-worker**, and
I say that as the load-bearing sentence here: Scott's sprite-forge mandate binds
the codex seat specifically (`$generate2dsprite` / `$generate2dmap`), and the
round retro must report whether those skills helped, which only works if codex
runs them. My job toward that slice is to hand codex the *contract* it generates
against, the slice manifest, the anchor convention, the facing sector table, and
the plate spec in `style.md`, all fixed before generation. Flora *placement*
(render-side, deterministic hash-of-cell selection, no RNG) is small and can go
to me or to agy-worker; I have no strong claim on it.

## 4. Rough estimate

Order of magnitude: the render spine (projection + reworks + camera + picking +
shadows + tests) is **a few days of focused work**, call it 3-5 engineer-days,
mostly in the player-controller rework and getting y-sort visually right at
shipping zoom. The art generation runs in parallel and is the long, uncertain
pole: **unbounded until the first coherent plate lands**, because it is an
iterate-until-Scott-accepts loop, not a fixed task.

What blows it up: (1) generation never reaching coherence across plates, forcing
multiple regeneration rounds, which is the likeliest overrun and is not on the
render slice's critical path but gates the acceptance artifact; (2) the tall-
building sort problem forcing a per-object depth-bias system instead of plain
y-sort, which would turn the clean spine into a fiddly one; (3) Scott rejecting
the vibe again, which is a taste gate no estimate covers and which we should
de-risk by putting one building + player + shadow in front of him early rather
than a full town late.
