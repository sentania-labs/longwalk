# Proposal: village feel round (walk cycle, zoom, click-to-move, visual feel)

- **Worker:** claude-worker
- **Branch:** `claude/village-feel`
- **Phase:** 1, blind. I have not read the Codex or Antigravity proposals.
- **Assignment:** quality character animations, zoom control, click-to-move,
  visual-feel pass; flora as a stretch.

## Scope resolution up front

Two ambiguities in the goal statement that I am resolving rather than deferring.

**"Quality character animations" means one walk cycle, three facings, and
nothing else.** No idle, no run, no turn transitions. Round 1 failed at the
minimum, so this round's job is to clear the minimum with evidence, not to widen
the animation set.

**Flora is cut as a generation task and kept as a data hook.** Priority order is
Scott's and items 1 through 3 are each larger than they look. The visual-feel
pass needs a way to place non-building scenery anyway, so it grows a `props`
array on `TownLayout`; flora then becomes a data-plus-two-sprites follow-up
dispatch with no engine work left in it. That is the honest version of "stretch
goal": I am building the socket and not the bulb. See the risk section for why I
think this is the wrong call if the round runs long on the art side and right if
it does not.

## 1. Approach

### 1a. The walk cycle: stop asking one call for twelve frames

Both round-1 candidates failed the same way, and I looked at both at cell size
before writing this. The diagnosis in `codex-spike-walk-sheet.md` is accurate
but stops one level short of the root cause.

A 3x4 sheet prompt asks a diffusion model to satisfy constraints that are
*relational between cells*: cell 3 must be the leg-reversed counterpart of cell
1. Diffusion has no cross-cell state. It denoises one canvas, and the grid
structure is a compositional convention it honors spatially (twelve figures, one
costume, aligned baseline, all of which both candidates nailed) but not
temporally. Candidate 2 is the proof: the revised prompt named the reversal
constraint about as explicitly as English permits, and the model still produced
two same-leg contact poses, while the down and up rows regressed because
attention moved to the row the prompt shouted about. That is not a prompt-luck
failure that a third wording fixes. It is the model spending a fixed constraint
budget across twelve cells and reliably dropping the relational ones.

The fix is to stop making leading-leg reversal something the model has to decide
and make it something the pipeline guarantees.

**Generate in pairs, one contact pair per call.** Six `image_gen` calls, not
one:

| Call | Contents |
| --- | --- |
| `walk_down_contact` | two figures: left-foot contact, right-foot contact |
| `walk_down_passing` | two figures: left-passing, right-passing |
| `walk_up_contact` | two figures, same structure |
| `walk_up_passing` | two figures |
| `walk_side_contact` | two figures |
| `walk_side_passing` | two figures |

Each call carries exactly one relational constraint ("these two figures are
mirror phases of each other") instead of eleven, and it is a *spatial* contrast
within a single canvas, which is the thing the model demonstrably does well:
both candidates kept one costume and one baseline across twelve cells without
being asked twice. Character consistency within a call is free. The remaining
constraint budget goes to the one thing that matters.

This is a graduated ladder, not a gamble. Twelve simultaneous relational
constraints failed twice. If two figures per call also fails, the next rung is
one figure per call with the phase named in isolation ("right foot planted
forward, left trailing"), which removes relational constraints entirely and
converts the whole problem into cross-call consistency. I would rather spend the
authorized budget walking down this ladder than on a third 12-cell prompt.

**Files.** New prompts under `tools/art/prompts/walk_<facing>_<phase>.md`. No
change to `generate.sh`. `process_assets.py` grows an `assemble_walk_sheet()`
step that background-removes each pair image, splits it at the inter-figure
gutter, crops each figure to content, aligns all twelve on a common feet
baseline and a common cell box, and writes one
`out/processed/player_walk_sheet.png` of exactly 4 columns by 3 rows at the
pinned 160px cell height. Baseline alignment is done by the pipeline from the
content bounding boxes, so the cross-call scale-and-drift risk that Codex
correctly raised against three-separate-renders in round 1 is absorbed in Python
rather than hoped for in the prompt.

**The verification gate is code, not a squint.** This is the part I care most
about. The defect that got past round 1 twice is mechanically detectable, and a
third attempt that is judged only by a reviewer looking at it is a third attempt
with the same gate that already failed. `tools/art/check_walk_sheet.py` (run
manually as part of the spike, not wired into CI, since it needs the raw art
and CI has no art step) asserts per row:

- **Leg-region divergence.** Take the bottom 40 percent of each cell's alpha
  mask. Frames 1 and 3 must differ by more than a threshold of their union area.
  This is the exact check that fails on both existing candidates, which is what
  makes it a calibratable threshold rather than a made-up number: I have two
  known-bad sheets to tune against and any threshold I pick must reject both.
- **Leading-leg reversal, signed.** Within the leg region, compute the
  horizontal (for the side row) or vertical-extent (for down/up) first moment of
  the mask about the cell's body centerline. Frames 1 and 3 must have *opposite
  sign*. Divergence alone is not enough; candidate 2's frames differed somewhat
  and still led with the same leg. Sign reversal is the actual named defect
  expressed as arithmetic.
- **Consistency.** Cell-to-cell content bbox height varies by under a few
  percent (catches scale drift), and the mean torso-region hue is stable across
  cells (catches costume drift, and reuses the hue machinery
  `process_assets.py` already has for tunic recoloring).

The script prints a per-row pass or fail table and a contact-sheet PNG at
shipping size for the human look. The human look is still the final word; the
script's job is to make sure nothing reaches the human look that provably fails
the one criterion we already know we miss.

**Engine side.** `AnimatedSprite2D` replaces the player's `Sprite2D`, with a
`SpriteFrames` built from the assembled sheet: `walk_down`, `walk_up`,
`walk_side`, plus idle single-frame variants per facing (frame 1 of each row,
which costs nothing and avoids a T-pose at rest). Left facing is `flip_h` of
`walk_side`. Round 1's critique named three concrete traps here and I am taking
all three as findings rather than rediscovering them:

- The animator reads **`get_real_velocity()`**, never input or path intent. Walk
  into a wall and the legs stop, because the feet are not moving.
- The sprite offset is **derived from the texture's cell height at runtime**
  (`offset.y = -frame_height / 2.0` computed in `set_appearance()`), not the
  hardcoded `-80` in `scenes/player.tscn`. That literal is half of
  `process_assets.py`'s `SPRITES["player_character.png"] = 160`, and coupling a
  scene constant to a Python dict through a comment is exactly how the y-sort
  bug documented at `starter_town.gd:89-99` comes back.
- `test/active_path/test_boot_flow.gd` does a typed `Sprite2D` fetch of a node
  named `Sprite2D` and reads `.texture`. That test breaks on all three counts
  and must be updated in the same commit, not discovered by CI.
- Tunic recoloring across 12 cells can strobe if `TUNIC_HUE_RANGE` partially
  misses on some cells. The consistency check above covers this: it is the same
  measurement.

### 1b. Click-to-move: pathing is sim, following is render

This is the item that touches `src/sim/`, and I think it is the item most likely
to be got wrong quietly.

**`src/sim/nav_grid.gd`** (new, `class_name NavGrid`, `RefCounted`, headless,
zero Viewport or Camera dependency):

```
static func find_path(layout: TownLayout, from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]
static func nearest_walkable(layout: TownLayout, cell: Vector2i) -> Vector2i
```

A* over `layout.is_cell_walkable()`, which already exists and already knows
about buildings and bounds. 8-connected with corner-cutting forbidden (a
diagonal step requires both orthogonal neighbors walkable), because diagonal
squeezes between building corners look like clipping.

**Determinism.** The constitution's rule is written about placement, and pathing
is not placement, so I want to be precise rather than hide behind the letter of
it: A* with an inconsistent tie-break is a function of iteration order, which is
the *category* of thing the rule exists to forbid, and a path that differs
between runs is untestable in exactly the way the rule is trying to prevent.
`find_path` is a pure function of `(layout, from, to)`. No RNG. Ties in the open
set break on a fixed total order (lower `f`, then lower `y * width + x`), so the
returned array is byte-identical across runs and platforms. Octile heuristic,
admissible, so the result is also optimal and not merely reproducible.

**Why sim and not render.** Not module hygiene for its own sake. NPC schedules
are the next dispatch and they need pathfinding on the same grid, they run as
sim ticks, and the ecology direction in CLAUDE.md points at a server-side sim
where a fish agent paths without a Camera in the process. If pathing lands in
`player_controller_2d.gd` it gets rewritten in two dispatches. `NavGrid` is also
the one piece of this round that is genuinely unit-testable:
`test/active_path/test_nav_grid.gd` asserts a straight path down the street, a
path that routes around `cottage_a`, refusal to corner-cut between two
diagonally adjacent buildings, `nearest_walkable` when the player clicks a
cottage roof, path-to-self as a single element, and byte-identical output across
repeated calls.

**Render side.** `player_controller_2d.gd` keeps `CharacterBody2D` and
`move_and_slide()`, and gains a waypoint follower: on `InputEventMouseButton`
left click, convert `get_global_mouse_position()` to a cell, `nearest_walkable`
it, `NavGrid.find_path()` from the current cell, store `Array[Vector2i]`, and
each `_physics_process` steer toward the current waypoint's tile center, popping
on arrival within a tolerance. Clicking again replaces the path outright. If
`move_and_slide()` reports the body is stuck against a collider for longer than
a short grace period (which can happen because the collision bodies are
rectangles at 128px tiles while the path is cell-centered), repath from the
current cell once; if that fails too, drop the path. A silently stuck player is
the worst outcome of this design and it needs a defined escape, not an
assumption that the grid and the colliders agree.

**Cursor and feedback.** A click marker: a small `Node2D` that draws a brief
expanding ring at the destination and fades, deleting itself. This is the
cheapest thing on the list and it is most of what makes click-to-move feel
responsive rather than laggy, because it acknowledges the click on the frame it
happens instead of a beat later when the character starts moving. Ultima Online
and the AoE references both do this.

**WASD is removed.** Scott said no more keyboard driving, so `move_up`,
`move_down`, `move_left`, `move_right` come out of `project.godot` and the input
polling comes out of the controller. Leaving them in "as a fallback" is how a
control scheme decision gets quietly un-made. This is the second protected-path
touch.

### 1c. Zoom

`project.godot` gains `zoom_in` and `zoom_out` actions bound to mouse wheel up
and down plus `=` and `-`, keybindable through the existing settings screen
pattern. `Camera2D.zoom` moves in discrete steps through a fixed table
(`[0.5, 0.7, 1.0, 1.4, 2.0]` as a starting point, clamped at both ends) with the
camera lerping toward the target each frame, because instant zoom snaps read as
a glitch and a continuous per-notch multiplier makes it impossible to get back
to exactly 1.0.

One trap worth naming because it is not obvious: `starter_town.gd:160-165` sets
`camera.limit_*` to the town's pixel bounds. Godot's camera limits are in world
space and the viewport shows `viewport_size / zoom` world units, so zooming out
far enough that the town is smaller than the viewport makes the limit logic
fight itself and the camera jitters at the edges. The zoom-out floor is
therefore derived from the town size and the viewport, not a hand-picked
constant: the widest step is the largest one where the visible world rect still
fits inside the limits. This lives entirely in render and is a
`display_settings.gd`-adjacent concern.

Zoom is render-only and touches no sim. Zoom level is not persisted (there is no
persistence layer yet, per CLAUDE.md).

### 1d. Visual feel: the tiling is the problem, not the palette

I looked at the eight references before writing this. What the AoE2 and WC2
screenshots have that our town does not, in the order that it matters:

**1. The ground is not one repeated tile.** This is the single biggest thing and
it is not close. We draw one 128px `grass_ground_tile.png` across an 18x14 grid,
so there are 252 identical squares and the eye locks onto the grid instantly. In
the WC2 shot the dirt is one material with constant tonal drift and scattered
break-up detail, and you cannot find the tile boundary. Fix: generate 3 grass
variants and 2 path variants, and select per cell with a **pure hash of
`(x, y)`** (integer hash, no RNG, no iteration-order dependence, byte-identical
every run, exactly the pattern CLAUDE.md's determinism rule describes for
`(seed, position)` sampling). Add a scatter layer of small ground detail
(pebbles, tufts) placed by the same hash. Selection is deterministic authored
data at heart, so it can live in `TownLayout` as a pure function alongside the
`props` array below; the sprites it names are render's business.

**2. Nothing is anchored to the ground.** Every reference has a contact shadow
under every object, and our style guide already asks for one ("soft contact
shadow beneath standing objects and characters") and we are not doing it. The
player and the buildings float. Fix: a soft elliptical shadow sprite under the
player (a child drawn below, scaled slightly with zoom-independent size) and
baked or drawn shadows at building footprints. This is cheap and it is most of
the "2026 rendering polish" that Scott is asking for; modern feel in a 2D
isometric scene is mostly grounding and light coherence, not shaders.

**3. Light is not unified.** Each asset was generated with "soft light from the
upper left" but there is no scene-level grade tying them together. Fix: a
`CanvasModulate` warm grade plus a gentle vignette on the town scene. One node,
large effect, trivially revertable if Scott hates it.

**4. Edges are hard everywhere.** In the SimCity-like reference the grass-to-road
transition is soft and irregular. Ours is a hard 128px stair-step. Fix, and I
would cut this first if time runs short: path tiles get edge variants that the
same `(x, y)` hash selects when a grass cell neighbors a path cell.

`TownLayout` gains `props: Array[PropPlacement]` (id, cell, sprite_key,
sub-cell offset) for the scatter layer, which is authored data in the same spirit
as `buildings` and is the socket flora plugs into. Chimney smoke is untouched;
the smoke is attached in `_build_buildings()` by `sprite_key` and none of this
goes near that path.

### 1e. Flora

Cut, as argued at the top. The `props` array plus deterministic scatter is the
whole engine cost of flora, and it ships in 1d whether or not any tree does. If
1a through 1d land early, the residual work is two `image_gen` calls (a tree, a
bush) and a handful of hand-placed `PropPlacement` entries at the town edges,
which is a sitting, not a dispatch. I would rather offer that as a bonus than
plan for it and land a worse walk cycle.

## 2. Risks

**The pair-per-call theory could be wrong, and it is the load-bearing claim.**
My whole art argument rests on "fewer relational constraints per call means the
model honors them." That is a plausible read of two data points, not a law. It
is possible the model simply has a strong prior toward a canonical stride pose
and reproduces it regardless of how few constraints compete, in which case pairs
fail exactly like grids did and I have burned budget confirming it. The ladder
rung below (one figure per call, phase named in isolation, no relational
constraint at all) is the hedge, and it has its own failure mode: it maximizes
cross-call drift, which is the exact objection Codex raised against Claude's
three-pose plan in round 1 and which was correct then.

**If one-figure-per-call is where this ends up, hand-authored frames get
cheaper than generation.** Decision 001's option analysis authorizes
hand-authored frames and I am not proposing them, on the theory that the
generator gets us there faster. If rung two fails I think the honest move is to
stop generating and author twelve frames by compositing limb layers off the
existing `player_character.png`, and I would rather say that now than defend
generation to the bottom of the budget.

**My verification script can be calibrated into uselessness.** I have exactly
two known-bad sheets and zero known-good ones. A threshold tuned to reject two
samples is a threshold tuned to reject two samples. It could easily pass a sheet
that is technically leg-reversed and still reads as a shuffle at 160px, or
reject a good sheet for a reason I did not anticipate. It is a floor under the
known defect, not a definition of quality, and it must not be allowed to become
the gate that replaces a human looking at it. I would rather state that clearly
than let a green script imply more than it checks.

**The nav grid and the collision bodies are two different worlds and they
disagree.** Pathing is over 128px cells; collision is rectangles built from
building footprints plus a 64px boundary wall. A cell whose center is walkable
can still have its center unreachable if the collider geometry overlaps the
approach, and `move_and_slide()` will happily wedge the player against a corner
while the follower insists the waypoint is straight ahead. I have specified a
repath-then-drop escape, but I am not confident the tolerance and grace period
are right without playing it, and this is the defect most likely to reach Scott
as "it gets stuck sometimes."

**Removing WASD before click-to-move is proven good is a one-way door in a
round that could run long on art.** If the art spike eats the round and
click-to-move ships rough, we have replaced a control scheme that worked with
one that does not, and the fallback is gone because I deleted it. I still think
it is right (Scott was unambiguous) but the sequencing matters: click-to-move
should land and be played before the `move_*` actions come out, even though they
come out in the same PR.

**The visual-feel pass is the item most likely to be judged wrong.** Everything
in 1d is defensible against the references and none of it is what Scott means by
"vibe" if he means something else. It is also the cheapest to iterate, which is
an argument for landing it early and taking a note, rather than for polishing it
alone.

**What I would find out first, given one hour and one question.** Whether the
`codex` CLI's `image_gen` tool accepts an **input image** (image-to-image, or an
edit or variation call), not just a text prompt. `generate.sh` only ever passes
text, and I do not know if that is the tool's limit or just the script's. If it
accepts an input image, the entire art problem changes shape: pass
`player_character.png` (a known-good, already-approved character in the shipping
style) and ask for one re-posed variant per call, and cross-call drift, costume
consistency, and scale consistency all collapse at once, because every frame is
anchored to the same source. That reorders my whole plan, so it is the first
thing I would check and it is a one-command answer.

## 3. Division-of-labor claim

**I claim `NavGrid` plus click-to-move, and the walk-sheet verification
harness.**

`NavGrid` is the piece with a real correctness surface: a pure function, a
determinism obligation I have to argue rather than inherit, a protected path,
and half a dozen tests that actually mean something. It is also the piece whose
consequences land two dispatches from now (NPC schedules path on this grid), so
it wants the resident that will argue about the sim boundary rather than take
the shortest line to a moving character. That is the work I am most confident
doing well.

The verification harness I claim on a specific and checkable ground: in this
session I read both rejected sheets as images and independently identified the
same-leading-leg defect at cell size before reading the spike record's
diagnosis. The generate-look-reject-adjust loop is a vision loop, and my harness
does vision inline without a detour through a separate tool.

**I do not claim the art generation itself, and I think Codex is better placed
for it.** `generate.sh` literally shells out to `codex exec` and works around a
codex sandbox bug in its own comments; the pipeline *is* the Codex harness with
a bash wrapper. The Codex resident calls `image_gen` natively, without a
subprocess that diffs `~/.codex/generated_images` to find its own output. It
also ran the round-1 spike and holds the context on what those prompts actually
did. Handing generation to me because I want to fix the diagnosis is optimizing
for whose theory it is instead of whose harness it is.

The split I would actually run: **Codex generates** (my prompt structure, or its
own if it disagrees, since it has better information about the tool), **I
verify** (harness plus the human look), and we iterate across the ladder rungs
together. This is a tighter loop than either of us running alone and it puts each
half of a generate-and-judge loop with the resident that does that half natively.

**Zoom and the visual-feel pass I would give to Antigravity**, and I am not
being polite. They are the two most separable items in the round: zoom touches
`project.godot` and one camera, the feel pass touches ground assembly and a
grade node, and neither one blocks or is blocked by the art spike or the nav
grid. In a three-doer round the scheduling win of a genuinely independent lane is
worth more than my having read the references. If the split lands differently I
would take the feel pass over zoom, since it is the one with a judgment call in
it.

## 4. Rough estimate

**Three to four sessions total across three workers**, which is a bigger round
than round 1 and should be planned as one rather than discovered as one.

- **Walk cycle: one to three sessions, and this is the whole variance.** If
  pair-per-call works on the first or second try, one session including the
  harness. If it fails and rung two fails, we are into hand-authored frames and
  that is a second dispatch, not a long afternoon. Everything else in this round
  is predictable; this is not.
- **NavGrid plus click-to-move plus the marker: one session.** A* on an 18x14
  grid is a known quantity, the tests are the bulk of it, and the collider-vs-grid
  wedging is the only part that could surprise me.
- **Zoom: half a session.** The camera-limit interaction is the only thing in it.
- **Visual-feel pass: one session,** of which most is the 3 grass and 2 path
  variant generations and the tonal matching between them. The code (hash
  selection, shadows, grade node) is a few hours.

**What blows this up.** The art ladder bottoming out, which converts item 1 from
a session into a dispatch. Ground-tile variants that do not tonally match each
other, which is the same class of problem as the walk sheet (cross-call
consistency) and would make the tiling worse rather than better, since three
mismatched tiles read as patchwork where one repeated tile at least reads as
uniform. And the nav-grid-versus-collider wedge, if the answer turns out to be
that the 128px collision rectangles need to shrink slightly from the footprint,
because that changes how buildings block and is a decision with feel
consequences rather than a constant tweak.

**What does not blow it up:** the engine work in 1b, 1c, and 1d is all
conventional Godot with a known shape. If this round runs long it will be
because of the art, and the plan should be built to let the other two lanes land
without waiting on it.
