# Codex proposal: village feel round

## 1. Approach

I would treat this as three mergeable slices with one integration gate, in the
given priority order. The shipping gate is a playable town where a click moves
the character around buildings, the camera zooms without changing gameplay,
and the character has a legible eight-facing walk at the actual 160 pixel
character height. Flora remains a stretch slice and does not consume time until
that gate passes.

### Character animation

I would stop asking an image generator for a finished sheet in one composition.
The two rejected sheets show that a model can preserve costume and approximate
layout while silently duplicating gait phases. A third full-sheet prompt is too
likely to spend another revision budget on the same failure.

Instead, I would use the existing generated character as the design reference
and build the cycle in controlled parts:

1. Generate paired opposite contact poses and paired opposite passing poses for
   one facing at a time, with the preceding accepted pose supplied as a visual
   reference. Each request names the visible near leg, far leg, planted foot,
   arm opposition, foot baseline, and unchanged torso. Do this for down, up,
   right, down-right, and up-right. The three rightward rows are mirrored for
   left, down-left, and up-left, producing eight facings without asking the
   generator to maintain ten independent rows.
2. Assemble and normalize the accepted poses with
   `tools/art/process_assets.py`: fixed cell bounds, feet anchor, transparent
   background, consistent character height, and the existing moss, burgundy,
   and slate-blue appearance treatment. Small hand-authored corrections to
   boot overlap and silhouette are in bounds when a generated pose is coherent
   except for the gait read. The source images and exact prompts remain under
   `tools/art/` as the reproducible art evidence.
3. Reject frames mechanically and visually before integration. A small art
   validation command checks exact row and column count, dimensions, alpha,
   and nonempty cell bounds. Contact frames 1 and 3 for every source row are
   then overlaid and viewed both as a difference image and as a looping cycle
   at 160 pixels tall. Acceptance requires an unmistakable leading-leg reversal
   in all five source rows, opposite arm swing, stable feet anchor, no identity
   drift, and no apparent backward step. This directly tests the defect that
   both earlier candidates missed.

`scenes/player.tscn` changes from `Sprite2D` to `AnimatedSprite2D` with named
idle and walk animations for eight facings. A render-side animation component,
either in `src/render/town/player_controller_2d.gd` or a small sibling script,
selects facing from actual velocity, keeps the last facing at rest, advances
walk frames by distance traveled rather than input events, and stops on an idle
frame when motion stops. Mirrored directions use sprite flipping and adjusted
frame names, not duplicate assets. The current appearance variants continue to
select equivalent processed sheets.

The art is accepted in a running game at shipping size, not from the raw image.
The capture should include horizontal, vertical, and diagonal loops, sudden
direction changes, stopping, zoom extremes, and partial occlusion by a cottage.

### Zoom control

I would add `zoom_in` and `zoom_out` actions to `project.godot`, with mouse
wheel defaults plus keyboard defaults that users can rebind. A new
`src/render/town/overhead_camera_2d.gd` on the player's `Camera2D` owns a small
ordered set of zoom levels, clamps at both ends, and eases toward the selected
level. Discrete levels make scroll behavior predictable and testing exact.
The script preserves the existing town limits, keeps the cursor's world point
approximately fixed while zooming where limits permit, and ignores wheel input
consumed by UI. Zoom never enters `src/sim/` because it changes only the view.

Headless tests verify action presence, default bindings, step and clamp
behavior, and that zoom has no effect on a route or player speed. A manual
check covers camera-limit behavior at all four town edges.

### Click-to-move

I would remove `move_up`, `move_down`, `move_left`, and `move_right` from the
active controller and active input map. Keeping them as an alternate movement
path would contradict the stated replacement and create two authorities for
movement.

The sim slice would add `src/sim/town_navigation.gd`, a headless `RefCounted`
route model over `TownLayout`. It accepts a start world position and clicked
world position, maps them onto the authored grid, resolves a blocked click to
the nearest walkable cell with a deterministic distance then coordinate
tie-break, and runs deterministic A* over eight neighbors. Diagonal transitions
cannot cut between blocked orthogonal neighbors. Its output is an ordered list
of world-space cell-center waypoints, with the exact clicked point appended
when that point is inside its walkable destination cell. Neighbor ordering and
tie-breaks are fixed, so identical layout, start, and destination values produce
an identical route. It uses no Godot scene, viewport, camera, input, physics,
or RNG APIs.

The route model owns destination intent, route replacement, cancellation, and
waypoint progression. `src/render/town/player_controller_2d.gd` converts a
left-click from screen to world coordinates, submits it, steers the
`CharacterBody2D` toward the current waypoint, calls `move_and_slide()`, and
reports arrival or obstruction back to the route model. Physics and collision
stay render-side because they are Godot scene behavior. If motion makes no
meaningful progress for a short fixed interval, the controller replans from its
current cell once, then cancels and shows an unreachable cursor state rather
than vibrating against geometry. A new cursor/target node in
`scenes/starter_town.tscn` shows hover intent, accepted destination, and a brief
unreachable response. Clicking again replaces the route immediately; clicking
the player or pressing Escape cancels it.

This intentionally chooses authored-grid A* over direct steering with collision
avoidance. Direct steering is smaller but will wedge behind the rectangular
building footprints that already exist. It also chooses a narrow navigation
contract rather than moving `CharacterBody2D` into sim, preserving the hard
sim/render boundary while making movement intent portable to a future server.
Tests cover blocked destinations, boundaries, deterministic equal-cost routes,
no corner cutting, route replacement, cancellation, and all eight resulting
movement facings.

### Visual-feel pass

The supplied references consistently favor a fixed isometric or high oblique
view, readable silhouettes, compact footprints, warm earth paths against rich
greens, strong roof colors, contact shadows, and dense edge detail. Their towns
feel inhabited because roads, fences, trees, plots, and buildings form clusters,
not because every surface is highly detailed. The current large square tiles
and sparse three-building field weaken that read.

For this round I would not convert the game to a 3D camera or rewrite it as a
true diamond-tile engine. That would be an engine and architecture escalation,
and would endanger animation and movement. I would keep the current 2D world
coordinates and y-sort contract, then make the authored scene read as oblique
through coordinated art and composition:

- Refresh grass, path, cottage, and store assets as one palette family: warm
  ochres and browns, deep but not neon greens, saturated roof accents, crisp
  silhouette edges, consistent upper-left light, stronger contact shadows, and
  detail sized to survive the default zoom.
- Replace the perfectly uniform ground with a small deterministic set of tile
  variants selected from authored cell coordinates, and soften path edges with
  corner and shoulder pieces. Any selection function is position-derived and
  order-independent. No stateful RNG is introduced.
- Tighten `src/sim/town_layout.gd` into a village cluster with a small square,
  narrower paths, coherent entrances, and deliberately framed negative space.
  Existing buildings may move, but no NPC or NPC logic is added. The reserved
  plot can remain data, while its translucent render marker should be removed
  from the player-facing scene because it reads as debug art.
- Add render-side contact shadows and restrained color and light polish that
  preserve the ambient chimney smoke. Smoke remains attached to cottages and
  is checked at every zoom level.

The modern part of "but for 2026" is clean scaling, stable motion, restrained
easing, readable cursor feedback, coherent lighting, and layered depth. It is
not blur, bloom, or dense shader effects over mismatched assets.

The stretch flora slice adds a deliberately small authored kit: one canopy tree,
one fruit or flowering tree, two bushes, grass tufts, flowers, and fence
segments. `TownLayout` would record placements and collision footprints;
`starter_town.gd` would render them in the same y-sorted world and apply
collision only to trunks and fences. Placement is hand-authored, with no RNG.
If priorities 1 through 3 are not solid, I cut the entire flora slice rather
than ship scattered placeholder vegetation.

Expected protected paths are exactly the forecast ones: `src/sim/` for the
navigation contract and layout composition, and `project.godot` for input
actions. Both require the signed round decision. I do not expect to touch
`ARCHITECTURE.md`, engine version files, export settings, or parked procedural
code. A true projection or engine change would require escalation and is not
part of this proposal.

## 2. Risks

The largest risk is still art quality. Generating poses separately improves
gait control but increases identity, scale, camera-angle, and lighting drift.
Mirroring also exposes asymmetric gear. Hand correction can repair feet and
anchors, but it cannot cheaply rescue a character whose torso changes between
frames. I would spend the first hour proving one complete right-facing cycle,
including a game-size loop, before generating the other facings. My one
question would be whether that controlled per-pose workflow produces a stable
enough identity when the previous accepted pose is used as reference.

Eight facings are substantially more art than the previous three-row spike.
If generation remains unstable, the honest scope reduction is four cardinal
facings with diagonal movement choosing the dominant axis. That meets
multi-facing but makes click-driven diagonal travel less polished, so it is a
fallback that needs explicit synthesis approval, not a quiet implementation
shortcut.

Grid A* can look angular at 128-pixel resolution, especially around corners.
Appending the exact click and removing line-of-sight-redundant waypoints can
help, but smoothing must be collision-aware or it reintroduces corner cutting.
The current render colliders and sim footprints must agree. Dynamic blockers
do not exist this round, but the proposed stuck-and-replan behavior is only a
limited bridge to them, not a full avoidance system.

Cursor-anchored zoom is easy in the middle of the town and subtle near camera
limits. Easing can also make repeated wheel ticks feel delayed. Discrete target
levels, short easing, and explicit edge tests limit this risk.

The feel pass can turn into a wholesale asset rewrite and starve the first
priority. It can also create projection mismatch if buildings imply one camera
angle while ground and character imply another. I would require a single
in-game palette and projection proof with one building, one path junction, the
player, shadow, and smoke before producing variants. Layout changes can break
existing test assumptions and collision, so visual composition and navigation
need a shared fixture rather than separate late-stage integration.

Finally, `TownLayout` is protected and is starting to carry more concerns.
Navigation queries and authored decoration records are reasonable sim data,
but shader settings, cursor state, animation names, camera state, and sprite
paths must not leak into it. If the implementation requires those leaks, the
design is wrong and should stop for review.

## 3. Division-of-labor claim

I am best suited to own the character-animation art pipeline and its runtime
integration. The previous Codex spike is direct context: I know the exact
failure at shipping scale, the prompts that failed, and the evidence standard
that must become stricter. My harness can iterate on image generation,
processing scripts, sprite resources, animation selection, and headless checks
in one worktree, which makes this a coherent single-owner slice instead of an
art handoff with ambiguous acceptance.

I would pair that ownership with the final in-game animation capture and gate,
but not claim navigation or the whole visual pass. A peer with stronger
simulation and pathfinding focus should own the `TownNavigation` contract and
click controller integration. The remaining peer should own camera zoom plus
the coordinated village palette, ground, building, and optional flora pass,
since those share visual tuning and camera-scale inspection. All three slices
need one agreed player origin, feet anchor, world scale, and test fixture before
implementation begins.

## 4. Rough estimate

This is a multi-day round, roughly four to seven focused worker-days across
three residents, plus review and synthesis latency. Character animation is
about two to three days if a controlled pose workflow converges after the first
facing. Navigation and click feedback are about one to two days. Zoom plus the
core feel pass are about one to two days. Flora adds another day and is the
first cut.

The estimate blows up if pose identity cannot survive separate generations,
if eight-facing art needs full manual repainting, if projection changes are
approved, or if click-to-move expands into dynamic obstacle avoidance. Without
those expansions, the slices can proceed in parallel after the navigation and
sprite contracts are agreed.
