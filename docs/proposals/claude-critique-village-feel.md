# Critique: village-feel round, phase 2 (claude-worker)

- **Worker:** claude-worker
- **Branch:** `claude/village-feel`
- **My proposal:** `b7faf4046a00871fdd0eb1a39f5bed623fdc4bc1`
- **Critiquing:** `codex/village-feel` @ `5effb7dbf12ebc1ddbff624c8a6a6deeba96c324`,
  `agy/village-feel` @ `05e62658a1a6b0a650328e5e29c921392378dfd8`
- Both read after my own proposal was committed. No phase-1 contamination.

Claims below that rest on repo state were checked, not remembered. The checks
are named inline so they can be refuted with a command.

---

## Part 1: Codex

### Steelman

Codex's proposal is the one that correctly identifies that *the acceptance
gate, not the prompt, is what failed in round 1*, and it is the only one of the
three that puts the fix in the right place: the art is accepted in a **running
game at shipping size**, under motion, at zoom extremes, under partial
occlusion, with direction changes. That is a strictly better gate than either
my pixel-arithmetic script or agy's implicit eyeball, because the defect Scott
rejected was never "the alpha masks are insufficiently divergent," it was "this
does not read as walking." Codex is testing the actual criterion. Everything
else it proposes is downstream of taking that seriously.

The implicit premise worth supplying, because it makes the proposal stronger
than it argues for itself: **supplying the previously accepted pose as a visual
reference is the thing that defeats my round-1 objection to per-pose
generation.** Codex raised cross-call identity drift against exactly this plan
in round 1 and was right; feeding the accepted pose back in is the mechanism
that answers its own objection, and Codex under-sells it as step 1 of a list
rather than as the load-bearing move. If image-to-image reference works, Codex's
workflow dominates mine, because mine anchors identity in Python post-hoc
(baseline alignment) while Codex's anchors it in the generation itself.

**Concession, explicit:** the in-game capture gate is better than my
`check_walk_sheet.py` gate, and I was wrong to frame mine as "the part I care
most about." Mine is a cheap pre-filter that rejects known-bad sheets before a
human spends attention on them. It is not a quality gate and I should not have
implied it approached one. The synthesis should take Codex's gate as primary and
demote mine to what it actually is: a fast reject on the one defect we already
know we produce, run before the expensive in-game capture, and never authorized
to *pass* anything.

### Attack 1: eight facings expands scope along the exact axis that has failed twice

Round 1 asked for **3 source rows** and produced 0 acceptable rows, twice.
Codex's response is to ask for **5 source rows** (down, up, right, down-right,
up-right), 4 frames each, 20 generated poses plus 3 mirrored rows to 32 total
cells.

This is not a small increase in an orthogonal dimension. Codex's own risk
section concedes the two mechanisms that make it worse than linear:

1. Identity drift is now measured across 20 poses instead of 12, and drift is
   cumulative in a chained-reference workflow (each pose references the last
   accepted one, so error compounds along the chain rather than being
   independently sampled).
2. Diagonal facings are a *harder pose class* than cardinals. A 3/4-rear walk
   contact pose has more self-occlusion and a less canonical training prior than
   a straight-on one. We are adding the hardest poses to the round that has not
   yet cleared the easiest.

The estimate reflects this ("two to three days if a controlled pose workflow
converges after the first facing"), but the priority order does not. Scott's
item 1 says "a real multi-facing walk cycle for the PC **at minimum**", and
"minimum" is doing work in that sentence: it is the floor, and the floor is what
round 1 missed. Spending the round's variance budget on facings 4 through 8
before facing 1 is proven is optimizing the thing that is not the named defect.

Codex half-anticipates this and offers 4 cardinals as "an honest scope
reduction ... that needs explicit synthesis approval, not a quiet
implementation shortcut." Agreed on the procedure, wrong on the default. **The
fallback should be the plan and eight facings should be the stretch**, for the
same reason Codex itself gives for cutting flora: an unproven priority-1 does
not get to borrow time from the thing that failed. Ship 3 source rows (down, up,
side), mirror side to left, prove them in-game at 160px, and *then* spend
whatever budget is left extending to diagonals. Note that this reordering is
free: the diagonals are additive rows on the same sheet with the same pipeline,
so nothing is thrown away by deferring them. There is no architecture cost to
being wrong about the order, only to being wrong about the floor.

### Attack 2: cursor-anchored zoom is not implementable as the scene is built

Codex: "keeps the cursor's world point approximately fixed while zooming where
limits permit."

`scenes/player.tscn:18` declares `Camera2D` as a **child of the player node**,
and `starter_town.gd:160-165` sets its `limit_*` to the town's pixel bounds.
A child camera's world position is the player's position plus a fixed offset. It
does not move independently. Keeping a cursor's world point fixed under a zoom
change requires translating the camera by a computed delta each notch, which the
current rig structurally cannot do: any offset you write is either overwritten
by the parent transform next frame or permanently decouples the camera from the
player, which changes what "the camera follows the player" means.

So this feature costs one of:

- Reparent the camera out of `player.tscn` into the town scene and write a
  follow controller (a real change to a scene contract two other slices depend
  on for the player origin and feet anchor, which Codex itself says must be
  agreed before implementation begins), or
- A camera offset property blended against the follow target, which is a
  drag-pan system in all but name and is not in anyone's estimate.

Codex prices zoom at "one to two days" **shared with the entire coordinated
palette, ground, building, and flora pass**, and this is inside that. That is
not a schedule, it is an omission.

Codex's hedge is "approximately" and "where limits permit." I do not think the
hedge survives contact: near the town edges the camera is limit-clamped, in the
middle it is player-locked, and the union of those two regions is the whole
town. There is nowhere it works.

**What should happen instead:** cursor-anchored zoom is cut, and zoom is
player-centered discrete steps with easing, which is what agy and I both
proposed and what the camera rig already supports for free. If Scott wants
cursor-anchored zoom, it is a camera-rig dispatch with its own scene-contract
change, not a line item inside a palette pass.

My own proposal is not clean here either and I will concede it now: I flagged
the camera-limit-versus-viewport interaction and derived a zoom-out floor from
it, but I did not notice the camera was parented to the player, and my "camera
lerping toward the target each frame" phrasing is loose in the same direction.
Player-centered zoom happens to be what I specified, so the plan survives, but
I did not earn it.

### Attack 3: two residents are assigned the same protected file in the same round

Codex's division of labor:

- The sim/pathfinding peer owns `TownNavigation`, which reads `TownLayout`.
- The zoom-plus-feel peer owns "Tighten `src/sim/town_layout.gd` into a village
  cluster with a small square, narrower paths, coherent entrances ... Existing
  buildings may move."

`src/sim/` is a protected path (`.github/protected-paths.txt`, "Sim-layer
contracts", directory-wide, and the comment explicitly names `town_layout.gd`).
This design has two residents editing one protected file across two concurrent
PRs, and the dependency is worse than the merge conflict:

- Nav tests assert routing **around `cottage_a`** at its authored cell. My
  proposal names that test; Codex names "deterministic equal-cost routes" and
  "no corner cutting," which are *more* layout-sensitive, not less, because
  equal-cost ties depend on the specific obstacle geometry.
- The feel slice moves the buildings.

So the nav slice's tests are written against a fixture the feel slice is
concurrently rewriting, and whichever lands second re-does its test expectations
against a layout it did not choose. Codex sees the shape of this ("visual
composition and navigation need a shared fixture rather than separate
late-stage integration") and then does not act on it in the labor split. Naming
a risk is not mitigating it.

Also: the round's decision record has to enumerate the protected-path touch, and
"two slices, one file, one round" is a consensus-record question, not an
implementation detail to be sorted out at merge time.

**What should happen instead:** layout composition is not in this round.
Deterministic tile variants, contact shadows, and the color grade all move the
village toward the reference vibe **without moving a single building**, which is
the whole point of my 1d argument that the tiling is the problem and not the
palette. If the building arrangement is genuinely wrong, that is its own
dispatch with its own record, sequenced after nav lands and can be re-tested
against the new layout. It is not a free rider on a palette pass.

### Attack 4: the reserved-plot marker removal is right and is not Codex's to bundle

Small, but it is a pattern. "The reserved plot ... its translucent render marker
should be removed from the player-facing scene because it reads as debug art."
Correct, and I missed it. But it is a scene-visible gameplay-adjacent removal
bundled into a slice already carrying a palette rewrite, a layout rewrite, zoom,
and optional flora. Codex's own PR-hygiene position is one PR per owned slice;
this slice is four slices wearing a coat.

---

## Part 2: Antigravity

### Steelman

Agy's proposal contains the single best idea in the round, and neither Codex nor
I thought of it: **make the model's attention track the legs by making the legs
visually distinguishable, then undo it in post.** The insight underneath is
sharper than agy's own writeup argues. The reason a 3x4 sheet fails is that
"left leg" and "right leg" are *semantically* distinct but **visually
identical**, so the model has no image-space signal to bind the constraint to,
and its attention has nothing to latch onto across cells. Magenta and cyan boots
convert a semantic constraint the model keeps dropping into a chromatic one it
demonstrably holds (both round-1 candidates preserved one costume across twelve
cells without being asked twice, which is exactly the class of constraint agy is
proposing to convert the problem into).

Supplying the premise agy leaves implicit: this is not a "hack," it is
**changing the constraint's modality to the one the model is empirically good
at.** Framed that way it is a more principled fix than my pair-per-call ladder,
because mine only *reduces the number* of relational constraints and hopes the
model spends its budget better, while agy's *changes the kind* of constraint so
it stops competing for that budget at all. And the recolor is cheap and already
half-built: `process_assets.py:133` `recolor_tunic()` is exactly this operation
(HSV mask on a hue range, hue-shift in place), and `TUNIC_HUE_RANGE = (40, 80)`
is nowhere near magenta (~300 degrees) or cyan (~180), so the boot masks and the
tunic mask cannot collide.

**Concession, explicit and load-bearing:** this is better than my pair-per-call
plan and I want it in the synthesis. My ladder's rung 1 costs six generation
calls to test a theory about constraint budgets; agy's costs one call to test a
theory about constraint modality, and it is compatible with the 3x4 single-sheet
composition that already succeeds at costume and baseline consistency. Agy's
"if I had one hour" question (run one `image_gen` with colored boots, check the
edges at game scale) is the right first hour of this round, and it is better
than my proposed first hour.

### Attack 1: color-coding makes the defect visible, not absent, and agy has no gate

This is the load-bearing flaw and it is not the one agy is worried about.

Agy's stated risk is halo artifacting at the recolor boundary. That is a real
but small risk with a known fix. The unexamined risk is: **what does the
pipeline do when the model paints magenta-forward in both contact frames?**

Nothing in agy's proposal answers this. The recolor pass maps magenta and cyan
to leather brown *unconditionally*. So a sheet with the exact round-1 defect
goes through the pass and comes out as a sheet with the exact round-1 defect,
having had its one diagnostic signal deliberately destroyed. The hack's entire
value at that point was to make the failure legible, and the pipeline's last
step is to make it illegible again before anyone looks.

Agy's proposal contains no acceptance criterion for the walk cycle at all. Not
a script, not an in-game capture, not a stated pass condition. Round 1 failed
twice under a look-at-it-and-judge gate, and agy is proposing a third attempt
under the same gate plus a step that erases the evidence.

**What should happen instead, and this is my main synthesis ask:** the recolor
is the *last* step and the check runs **on the pre-recolor image**, where it is
trivial. Do not compute alpha-mask first moments about a body centerline (my
proposal's arithmetic, which is fiddly and which I conceded above is calibrated
against two samples and zero known-good ones). Just ask which boot is forward.
With colored boots that is a **hue lookup at a pixel**: in the bottom-40 percent
leg region of each cell, find the magenta centroid and the cyan centroid, and
assert that the sign of (magenta - cyan) along the stride axis **flips** between
frame 1 and frame 3. That is a handful of lines, it needs no threshold
calibration, it has no false-positive story I can construct, and it is a
*direct* measurement of the named defect rather than a proxy for it.

This is the composition I want: **agy's generation trick, my verification
discipline, Codex's in-game gate.** Agy's trick is what makes my check trivial
instead of fiddly, which is a better argument for agy's trick than agy makes.
And it means the pre-recolor image is the artifact of record and must be kept
under `tools/art/`, not discarded as an intermediate.

### Attack 2: mirroring flips the boots, so left-facing is a wrong-footed cycle

Agy proposes `flip_h` for the left facing (implicitly, via the standard 3-row
sheet; Codex proposes it explicitly for three of eight rows; my proposal does
too). Under the color-coding scheme this interacts badly and nobody has noticed:

A magenta **left** boot, mirrored horizontally, is a magenta boot on the
character's **right** side. If the recolor runs before mirroring, this is
harmless, because both boots are brown by then and the mirrored cycle is
correct. But if any part of the verification runs **after** mirroring, or if the
colored intermediates are ever used to reason about the left-facing row, the
left/right binding is inverted and every conclusion drawn from it is backwards.

Worse, it means the colored intermediate **cannot** be the artifact used to
validate the mirrored row, because that row's colors are lies. The check must
run on the five (or three) *source* rows only, pre-mirror and pre-recolor, and
the mirrored rows are correct by construction from a validated source. That is a
fine answer, but it has to be *stated*, because the natural implementation
(assemble sheet, then validate the assembled sheet) does exactly the wrong
thing. This is a pipeline-ordering constraint that belongs in the decision
record: **generate colored, validate colored per source row, then mirror, then
recolor.**

### Attack 3: click-to-move with no pathfinding is a constitution-adjacent scope failure and contradicts the goal

Agy: "We have no navmesh. Click-to-move on a flat plane means the player will
get stuck sliding against cottage walls if they click behind a building. **This
is acceptable for this milestone**, but it will feel unpolished."

It is not acceptable, and I want to be precise about why rather than just
asserting it.

Scott's 2b says click-to-move **replaces WASD as the primary control scheme**.
A primary control scheme that cannot reach a destination behind a building is
not unpolished, it is non-functional, and the fallback is gone by the same
instruction that created the requirement. `town_layout.gd` builds an 18x14 grid
(`town_layout.gd:101-102`) with buildings in it; "behind a cottage" is not an
edge case in a town that size, it is most of the reachable area from most spawn
points. `_spawn_player()` puts the player at cell (9, 7), center of the map,
with buildings on multiple sides.

Agy defends the omission on cost. That defense does not survive its own
estimate: agy prices "the input/sim work (click-to-move and zoom)" at **a fast
2-hour job** and the whole round at 1-2 days, against Codex's 4-7 worker-days
and my 3-4 sessions. A* over an 18x14 grid of `is_cell_walkable()` (which
`town_layout.gd:67` already provides) is not what makes this round expensive.
Agy is cutting the cheap correct thing to save time on the item that is not the
bottleneck, and both other proposals independently priced pathfinding as
affordable. Two independent estimates disagreeing with yours by 3x is a signal
about the estimate, not about the scope.

### Attack 4: agy's sim/render split is backwards, and I say this as a constitution conformance claim

**This is a claim that agy's proposal violates the constitution.** The rule is
CLAUDE.md's "Simulation/rendering separation (hard rule)": sim code "lives in
its own module tree (`src/sim/`) and has zero dependencies on viewport, camera,
or UI nodes. It must be runnable headless." The proposal is `agy/village-feel`
@ `05e62658a1a6b0a650328e5e29c921392378dfd8`. Flagging it in these terms per
the phase-2 instruction, so that if this objection loses it escalates rather
than being settled at the orchestrator's desk.

Two distinct problems:

**(a) Sim moves the player body.** "In `src/sim/`, the player entity gains a
`target_position`. During `_physics_process`, the sim calculates the vector to
the target and moves the player at `SPEED`." The player is a `CharacterBody2D`
in `scenes/player.tscn` and moving it means `move_and_slide()`, which is scene
physics against `StaticBody2D` colliders that `starter_town.gd` builds. Sim
cannot move it without holding a reference to a scene node, which is a
dependency on the scene tree the rule forbids, and it cannot run headless in a
test that does not instantiate the town. Note `_physics_process` itself is not
the violation (`game_state.gd` is an autoloaded `Node` today and stays sim-side
legitimately, because it holds plain data). The violation is the *body
reference*. Codex gets this exactly right and says so in the words the rule
would use: "Physics and collision stay render-side because they are Godot scene
behavior."

**(b) Sim receives raw viewport pixel coordinates.** "`player_controller_2d.gd`
detects the click, calls `get_global_mouse_position()`, and sends this
coordinate to the sim layer (e.g., `GameState.set_player_target(pos)`)." Agy
presents this as the clean part, and it is the part I would push back on
hardest. `GameState` is the character-creation carrier
(`game_state.gd`: name and appearance variant, plus `reset()`); bolting live
per-frame movement targets onto it makes the session carrier a movement
authority, which is precisely the "shader settings, cursor state, animation
names, camera state" leak Codex correctly warns about for `TownLayout`, applied
to the other sim file. And `src/sim/` is protected, so this leak lands with a
consensus record attached to it.

I want to be fair about (b): world coordinates are not viewport coordinates,
and `TownLayout` already speaks pixels (`TILE_SIZE = 128`, `pixel_size()`), so
a world-space `Vector2` crossing into sim is defensible on its own. The
violation is (a) and the design smell is putting it on `GameState`. But taken
together they describe a sim layer that is a remote control for a scene node,
which is the shape the rule exists to prevent, and CLAUDE.md's rationale
section is explicit that this boundary is what makes the lab-hosted server "a
move, not a rewrite."

**What should happen instead:** the shape Codex and I converged on independently
(pathing is a pure or narrowly-stateful sim contract over `TownLayout`, physics
and steering stay in `player_controller_2d.gd`). Two of three proposals reached
this separately, which is about as close to a settled question as this round is
going to produce.

### Attack 5: the golden-hour grade will fight the assets, not unify them

Agy: `CanvasModulate` for a "warm, late-afternoon golden hour tint ... unifying
the generated assets," and separately, update the prompts for warmer palettes.

I proposed a `CanvasModulate` grade too, so this is partly self-criticism, but
agy's version has a specific problem mine does not: agy is doing **both** at
once and calls the grade the unifier. If the prompts are rewritten for warm
golds and deep greens *and* a golden-hour multiply lands on top, the warmth is
applied twice and the assets are graded relative to a target they already met.
A `CanvasModulate` multiplies; it cannot add light, only tint and darken. Push
it far enough to unify genuinely mismatched assets and you have crushed the
saturation range that made them readable, which is the opposite of the
Warcraft 2 reference where the read comes from *high local contrast* and warm
tint is a small part of it.

The grade is worth having, but it is a **finishing** step of small magnitude
over assets that already agree, not a **unifying** step over assets that do not.
If the assets do not agree, the fix is the assets. Codex is right on this and
says it well ("the modern part ... is not blur, bloom, or dense shader effects
over mismatched assets"), and Codex's projection-and-palette proof (one
building, one path junction, the player, shadow, smoke, in-game, before
producing variants) is the correct gate for it. I did not propose that gate and
I should have; my 1d assumes tonal agreement across 3 grass and 2 path variants
and then lists "variants that do not tonally match" as a risk without a gate to
catch it, which is the same failure mode I criticized round 1 for.

---

## Part 3: Where I was wrong

Recording these so phase 3 can synthesize instead of re-litigating.

1. **My verification script is not the gate.** Codex's in-game capture at
   shipping size, under motion and occlusion, is the gate. Mine is a cheap
   pre-filter. I over-claimed and I am withdrawing the claim.
2. **My pair-per-call ladder is inferior to agy's color-coding**, and the
   ladder's rung 1 should be dropped in favor of it. Six calls to reduce
   constraint count is worse than one call to change constraint modality. The
   ladder survives only as a fallback if colored boots fail, and the rung I
   would actually go to is Codex's reference-image workflow, not my rung 2.
3. **I missed that the camera is parented to the player**
   (`scenes/player.tscn:18`) while writing a section about camera limits. My
   zoom plan happens to be unaffected, but I did not earn that.
4. **I missed the reserved-plot debug marker.** Codex caught it. It should
   still not ship inside the feel slice.
5. **My first-hour question is superseded.** I asked whether `image_gen` accepts
   an input image. Codex's proposal asserts the reference-image workflow as a
   plan, which suggests it knows the answer, and agy's one-hour test is cheaper
   and more decisive regardless. If Codex has that answer, it should be stated
   as a fact in the record rather than assumed by one proposal and asked about
   by another. This is the single highest-value thing to resolve before phase 3
   closes, because Codex's entire art workflow is unbuildable without it.

## Part 4: What I think the synthesis is

Stated plainly, since the round's job is to converge:

- **Art generation:** agy's color-coded boots, on the 3x4 single-sheet
  composition that already works, three source rows only (down, up, side).
  Codex's reference-image anchoring as the fallback if identity drifts, its
  chained-reference workflow as the fallback below that. Pipeline order is
  fixed: generate colored, validate per source row pre-mirror, mirror, recolor.
- **Art gate:** hue-centroid sign-flip check on the colored pre-recolor image
  (cheap, no calibration, direct), then Codex's in-game capture at 160px under
  motion, occlusion, and zoom extremes as the accept/reject authority.
- **Diagonals:** stretch, after three rows are proven in-game. Additive, so
  deferring costs nothing.
- **Navigation:** grid A* in sim over `TownLayout`, physics and steering in
  `player_controller_2d.gd`. Not on `GameState`. Two of three proposals reached
  this independently.
- **Zoom:** player-centered discrete steps with easing. Cursor-anchored zoom is
  cut and is its own camera-rig dispatch if Scott wants it.
- **Feel:** deterministic `(x, y)`-hash tile variants, contact shadows, a small
  finishing grade, Codex's one-building palette proof before any variant
  generation. **No building moves this round.**
- **Flora:** cut. All three of us said so.
