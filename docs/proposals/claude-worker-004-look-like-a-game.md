# claude-worker, round 004 proposal: make it look like a game

Phase 1, blind. Written without reading codex-worker's or agy-worker's
proposals, branches, or worktrees.

## 0. The ambiguities I am resolving, named up front

Four things in the assignment are underdetermined. I am resolving them rather
than hedging, and naming them so the critique round can attack the resolution
rather than discover it.

1. **Projection: the references are isometric, and I am proposing we stay
   top-down anyway.** Five of the six reference images Scott added are
   isometric (the SimCity-alike, AoE, AoE2). The sixth, `maxresdefault.jpg`,
   is Warcraft 2, and WC2 is *not* isometric: it is an axis-aligned top-down
   grid with buildings drawn in oblique three-quarter. The constitution says
   "isometric / top-down", so both are authorized. I argue top-down in section
   1.1, and the argument is not aesthetic, it is that isometric invalidates
   the walk sheet the team spent three rounds producing.
2. **"Right-click to focus" does not say how you get back.** I resolve it as:
   right-click focuses and *stays* focused (Scott's "independent of where the
   character is pathing" is explicit), plus a new `center_on_player` action on
   Space that returns to follow. Without a return path the feature is a trap.
3. **Requirement 1's acceptance bar is a GIF comparison, which is a judgement,
   not a gate.** I resolve it as: the GIF harness is mine to build and it is an
   *evidence* artifact, not a pass condition. Scott judges. `check_walk_sheet.py`
   keeps reject-only authority per 003 and 005. Nobody gets to argue a GIF into
   a pass.
4. **Scott's carve-out reserves the traveller for AI generation.** I read that
   as a preference, not a hard constraint, and section 1.3 names the reserve
   option that contradicts it. I am not proposing we take the reserve now.

## 1. Approach

### 1.1 The central claim: the vibe gap is a *rendering-model* gap, not a palette gap, and not an isometric gap

Round 003's feel pass produced a `CanvasModulate` at
`starter_town.gd:56` (`Color(1.0, 0.95, 0.88)`), and Scott's verdict is
correct: that is a color grade, not a style change. But the reason it could
only be a grade is upstream of the grade.

`project.godot` states the house rendering model explicitly, and it is
load-bearing:

> canvas_items, not viewport. The art here is NOT pixel art and does not want
> integer pixel-perfect scaling ... `process_assets.py` resizes every asset
> with LANCZOS (a smooth resample) onto arbitrary non-grid sizes (66x160 for
> the player, 320x261 and 320x230 for the two building facades).

Every reference image Scott handed us is pixel art. Warcraft 2 is 8-bit
palettized pixel art at a 32px grid. The SimCity-alike is pixel art. AoE is
pixel art. We are rendering smooth LANCZOS-resampled AI renders at arbitrary
non-grid sizes with linear filtering, and then grading them warm. **No grade
reaches the vibe gap, because the gap is that we are not making the same kind
of image as the references.** That is why requirement 2 exists and why it will
recur next round if we answer it with better assets in the same rendering
model.

So the first thing this round changes is not the assets, it is the model:
nearest-neighbour filtering, a fixed art scale, integer sprite dimensions on
the pack's grid, and a locked palette. That is a `project.godot` and
`process_assets.py` change, and everything else in this proposal sits on top
of it.

**And this is exactly why I am arguing against isometric, despite the
references.** Adopting an isometric pack means the four cardinal grid
directions become the four *screen diagonals*. Our walk sheet has three source
rows (down, up, side) mirrored to four cardinal facings, per decision 005,
which explicitly leaves diagonals as "the first stretch". An isometric world
needs exactly the facings we do not have and does not need the ones we spent
seven revisions, two topologies, and a hand-authoring fallback to get
(`18e2a1b`). Isometric throws away the single most expensive artifact this team
has produced, in the round whose first requirement is *improve that artifact*.
That is not a tradeoff, it is a self-inflicted wound. WC2 is the reference that
matches the grid we already have, and it is on Scott's list.

### 1.2 The asset pack: the contested question, answered with a primary, a fallback, and a rejection

I did the research. Here is what I actually found, including the part that is
inconvenient.

**The best vibe match is the one pack we cannot legally commit.**

**REJECTED: Tiny Swords, Pixel Frog.** https://pixelfrog-assets.itch.io/tiny-swords
64x64 top-down, explicitly Warcraft-inspired, terrain autotiles, trees, gold
rocks, sheep, eight buildings, units with real walk cycles, decorations,
particle effects. It is, by a distance, the closest thing on the internet to
what Scott is asking for. Its license is **not CC0** despite what the community
repeats: the current terms are "feel free to use this asset pack in both
personal and commercial projects, modifying the assets as needed ... **you may
not redistribute, resell, or repackage the assets, even if the files are
modified**." A public git repo with the PNGs committed is redistribution. That
is a clear license, not an unclear one, and it clearly forbids what we would do
with it. I am not proposing a `tools/fetch_tiny_swords.sh` dodge on the
`fetch_godot.sh` precedent: itch has no stable direct download URL, and
fetch-instead-of-commit is a workaround for repo hygiene, not a license
loophole. **If Scott wants this pack, it is an escalation** (private repo, or
direct permission from Pixel Frog), and it is worth asking, because it is the
biggest single unlock in the entire round and I would rather Scott decline it
knowingly than never see it.

**PRIMARY: the LPC base assets, restricted to the CC-BY-licensable subset.**
https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles
32x32 top-down, and it has literally every noun in requirement 3 and
requirement 4: grass and dirt terrain with transition autotiles, trees, bushes,
flowers, houses, and roads. It is the closest licensed thing to a UO/WC2
overworld that exists.

The catch, stated plainly: **LPC's blanket license is CC-BY-SA 3.0 dual with
GPLv3, and Scott authorized "CC0 or CC-BY".** ShareAlike is not CC-BY, and I am
not going to pretend the difference does not exist. The carve-out that makes
this work: the base tiles and sprites by **Lanea Zimmerman (Sharm)** and
**Stephen Challener (Redshrike)** are separately available under **CC-BY 3.0**
with the anti-DRM clause waived, and those two authored the terrain, trees, and
houses we actually want. So the slice is "the Sharm/Redshrike subset under
CC-BY 3.0", per file, with provenance recorded per file in `CREDITS.md`. If a
file's CC-BY availability cannot be substantiated from the source page, that
file does not ship. This is real work and I am costing it in section 4, not
waving at it.

**FALLBACK: Kenney Roguelike/RPG pack.** https://kenney.nl/assets/roguelike-rpg-pack
CC0, unambiguous, 1700 assets, redistributable with zero legal work, terrain
and trees and buildings and roads all present. It is 16x16 and Kenney's house
style is flat and friendly rather than Bullfrog-grubby, so it is a weaker vibe
answer. It is the fallback precisely because it cannot fail on licensing.

**Named and rejected for projection reasons, but worth recording** because they
are the clean isometric answer if the team overrules me on section 1.1, and
they are both in the authorized license set and both redistributable: Yar's
**Isometric 64x64 Outside Tileset** (CC-BY 3.0, grass/trees/rock/hill/waterfall,
https://opengameart.org/content/isometric-64x64-outside-tileset) paired with
Seth Galbraith's **Isometric 64x64 Medieval Building Tileset** (CC-BY 3.0,
designed explicitly to work with Yar's,
https://opengameart.org/content/isometric-64x64-medieval-building-tileset).
That pairing is license-clean, flora-complete, and genuinely UO-adjacent. It
costs us the walk sheet. I would take it only if the team decides the walk
cycle is being restarted anyway.

### 1.3 Requirement 1, the walk cycle, and the uncomfortable thing decision 005 already records

Decision 005's own outcome section, quoting my peer review, says of down and up:

> they will not get better from more prompt iteration. Three revisions of
> generation plus a hand-authored pass have converged here. If down/up need to
> be as good as side, that's a human artist, not more agent budget.

I wrote that, I still believe it, and it means **regenerating the sheet a
fourth time is the option this round should not take.** Requirement 1 needs a
lever that is not "ask the diffusion model again".

The lever I propose is a consequence of section 1.1 that I did not expect when
I started: **pixelization at pack scale is itself a gait-quality improvement.**
At 160px with smooth linear filtering, gait is read through limb detail, and
our limb detail is mush, so the eye reads "skipping". At pack scale (roughly a
48 to 64px tall figure) gait is read through *silhouette*: stride is 3 pixels,
contact is a visible two-pixel-wide gap between feet, bounce is one pixel. WC2
footmen are 32px and read as marching, because at that size the animator is
committing to a pose per frame instead of blending. Shrinking the traveller
onto the pack's grid with nearest-neighbour, then hand-adjusting the contact
frames' foot separation and clamping the vertical bounce, is a *deterministic
image operation on the sheet we already have* rather than a regeneration. It
preserves the alternation that cost the team three rounds, because a per-pixel
transform cannot reorder frames.

Concretely, `tools/art/pixelize.py`, running in the pipeline **after** recolor
and therefore after the gate (per 003's binding order: generate colored,
validate pre-mirror pre-recolor, mirror, recolor). Box-downsample to pack
scale, quantize to the pack's palette, snap to the pack's grid. Then the
existing gate is re-run on the pixelized *source rows* as a regression check.
**I am asserting, and the critique round should hold me to it, that if
pixelization destroys the alternation signal the gate will say so, and if it
does, pixelization dies rather than the gate.**

The acceptance artifact is `tools/art/build_walk_gif.py`: a side-by-side
animated GIF, our cycle next to a reference cycle from the reference folder,
same frame rate, same figure height, attached to the decision record, judged on
stride length, contact frames, and vertical bounce, per Scott. It is evidence,
not a gate.

**Reserve option, named because 005's reserve clause is the pattern that saved
the last round:** the LPC Universal Sprite Sheet ships a canonical nine-frame
four-facing walk cycle under the same license as the terrain. It satisfies
requirement 1 outright, today, for free. It contradicts Scott's carve-out
reserving the traveller for AI generation. I am **not** proposing we take it. I
am proposing we write it into the decision record as reserve, so that if the
pixelize path fails we ship a real walk cycle this round instead of a fourth
BLOCKED marker. Decision 005 proves the reserve clause is worth more than the
ballot that produced it.

### 1.4 Requirements 6 and 7 collapse into one module

Current state, `starter_town.gd:220`: `_create_shadow_polygon()` builds a
24-segment ellipse `Polygon2D`. It is used for both the buildings (at
`footprint_px * 0.8`) and the traveller (at `28x14`). That is the blob Scott is
objecting to in requirement 6, and its centring at `Vector2.ZERO` under the
player is part of why he floats in requirement 7. **Both requirements are the
same defect: we have no light direction.**

The Bullfrog technique, per CorsixTH, is that shadows are drawn artifacts with
a single consistent light direction across the whole scene, not computed
geometry. The cheap faithful version:

`src/render/town/shadow_caster.gd`, one new render-side file.

- One constant, `LIGHT_DIRECTION`, and one shear+squash `Transform2D` derived
  from it. Every shadow in the game reads that one constant, which is what
  makes requirement 7's "consistent with the building shadow direction"
  true by construction rather than by tuning.
- `silhouette_shadow(texture) -> Sprite2D`: the **same texture** as the caster,
  `modulate = Color(0, 0, 0, 0.3)`, transformed by the shear, drawn into
  `_ground_layer` beneath the caster. It conforms to the silhouette because it
  *is* the silhouette. No polygon, no approximation, no per-building authoring.
  Buildings, trees, and bushes all use this, so requirement 3's flora arrives
  already grounded instead of needing its own pass.
- `contact_shadow(width)`: a small tight high-opacity ellipse at the feet,
  offset along `LIGHT_DIRECTION`, for the traveller. A contact shadow is a
  different thing from a cast shadow and conflating them is the current bug:
  the blob under the player is too big, too soft, and too centred to read as
  contact.

Requirement 7's other half is the float itself. My hypothesis, and I am flagging
it as a hypothesis I would spend my one hour on (section 2): he floats because
the feet anchor is correct in *sim* terms but the sprite has no ground overlap,
and the vertical bounce from the walk cycle is unclamped, so the contact frames
never actually land. Fix is a two to four pixel anchor sink plus a bounce clamp,
both in `player.tscn`/`player_controller_2d.gd`, both tuning, both worthless
until I have looked at a captured frame.

### 1.5 Requirement 4, road-weighted routing, the one genuinely subtle piece

`src/sim/nav_grid.gd`, protected path, forecast correctly.

`GroundTile.PATH` already exists in `town_layout.gd`. Add, sim-side:

```gdscript
# town_layout.gd
const TERRAIN_COST := {GroundTile.GRASS: 1.0, GroundTile.PATH: 0.6}
const MIN_TERRAIN_COST := 0.6
func terrain_cost_at(cell: Vector2i) -> float
```

`NavGrid.find_path()` changes in exactly two places, and the second one is the
one that matters:

1. Step cost becomes `base_step * layout.terrain_cost_at(neighbor)`, where
   `base_step` is the existing `ORTHOGONAL_COST` or `DIAGONAL_COST`. Cost is
   charged for *entering* a cell, so a route is cheap when the cells it enters
   are road.
2. **The heuristic must be scaled by `MIN_TERRAIN_COST`.** `octile_distance()`
   is currently exact, and therefore admissible, only because every step costs
   at least `ORTHOGONAL_COST`. The moment a road step costs 0.6, the unscaled
   octile overestimates, admissibility breaks, and the file's own header
   comment ("the octile heuristic is consistent for this cost pair, so a cell
   is closed at most once and no reopening rule can reorder the search") stops
   being true. That comment is not decoration, it is the determinism argument:
   without consistency, cells reopen, and reopening order is where
   nondeterminism gets in. So `h = MIN_TERRAIN_COST * octile_distance(...)`,
   which is admissible and consistent because no edge can cost less than
   `MIN_TERRAIN_COST * base_step`.

**Anyone who does requirement 4 without touching the heuristic has silently
broken the determinism guarantee this file was written to make.** That is the
single highest-value sentence in this proposal and I would like the critique
round to check it rather than take my word for it.

Determinism otherwise survives untouched: no RNG, same total order
(lower f, then lower cell index), same fixed neighbour order, pure function of
`(layout, from, to)`. New tests in `test/active_path/test_nav_grid.gd`: a
route that detours onto the road and back beats the straight-line grass route;
a destination off-road still leaves the road at the last sensible cell; the
byte-identical-across-calls assertion still passes with mixed terrain.

Tuning note: 0.6 is a guess. Too low and he takes absurd detours to touch
asphalt, too high and the feature is invisible. It is one constant and the GIF
and screenshots will settle it.

### 1.6 Requirement 5, right-click focus, needs the camera off the player

`starter_town.gd:206`: `var camera: Camera2D = player.get_node("Camera2D")`.
The camera is a child of the player. That is why requirement 5 is not a
one-liner: a camera parented to the player cannot be independent of the player.

`src/render/town/camera_rig_2d.gd`, render-side, owning a two-state machine:

- `FOLLOW`: position tracks the player each frame.
- `FOCUSED`: position lerps toward a fixed world point and stays.

Right-click sets the focus point and enters `FOCUSED`. Space
(`center_on_player`) returns to `FOLLOW`. The camera is reparented from the
player to `_world`, keeping the existing `limit_*` clamps so focus cannot pan
off the town. Left-click keeps routing the player and does **not** steal the
camera back, which is the whole point of Scott's "independent".

`project.godot`, protected path, forecast correctly: two new InputMap actions,
`focus_view` (MOUSE_BUTTON_RIGHT) and `center_on_player` (KEY_SPACE), alongside
the existing `zoom_in`/`zoom_out`/`toggle_fullscreen`.

`starter_town.gd:_unhandled_input()` currently early-returns on anything that
is not a left button press. It grows a right-button branch that calls the rig.

### 1.7 Requirement 3, flora, which decision 003 cut and Scott has now asked for three times

Sim side, `src/sim/town_layout.gd`: a `FloraPlacement` class mirroring
`BuildingPlacement` (id, cell, sprite_key, blocks_movement), and a `flora:
Array[FloraPlacement]` filled by hand in `build_starter_town()` alongside the
buildings. Tree trunks block, bushes and the flower patch do not.
`is_cell_walkable()` grows a flora term. **Authored constants, no seed, no RNG,
determinism trivially preserved**, consistent with the file's existing
"this is authored data, not generated" contract.

Render side: `_build_flora()` in `starter_town.gd`, drawn into `_world` so the
existing y-sort handles depth, with the same bottom-edge sort-key discipline
the building sprites already use (that comment at `starter_town.gd:104` is
correct and hard-won, and flora will regress it if someone centres the
sprites). Each gets a `silhouette_shadow` from 1.4 for free.

Requirement 3 is at least: a treeline along the town edge, bushes against the
cottage walls, one flower patch. All three nouns Scott named, all present in
both candidate packs.

### 1.8 The ground, which is the other half of requirement 2

I argued in round 003 that the tiling is the problem rather than the palette:
252 identical grass tiles, so the eye finds the grid instantly. That argument
was accepted and then only half-implemented. `starter_town.gd:78` currently
does:

```gdscript
var h := hash(Vector2i(x, y))
sprite.flip_h = (h % 2 == 0)
```

Two problems. First, four flips of one identical texture is not variety, it is
the same tile four ways, and the grid still reads. Second, and this is a
constitution issue nobody has flagged: **`hash()` is Godot's built-in hash and
its stability across engine versions is not a guarantee we control.** The
determinism rule says generation must be a pure function of `(seed, position)`
that we can reproduce. Right now the ground pattern is a pure function of
position *and of Godot's hash implementation*. It should be an explicit integer
hash written in our code. It is a five-line fix and it is the kind of thing
that is free now and archaeology later.

Replacing it: ground renders **four sub-tiles per sim cell** (each pack tile at
2x rather than one tile at 4x), with the variant chosen by an explicit
positional hash over the sub-cell coordinate, drawing from the pack's grass
variant set plus its transition autotiles at the grass/path boundary. Four times
the ground detail, the 128px grid stops being legible, and the road gets actual
edges instead of a hard seam. This is the single change I expect to do the most
for the before/after screenshots, and it is nearly free once the pack is in.

## 2. Risks

**The risk that makes my own proposal look worst: I am proposing a rendering-model
flip in the same round as six other requirements.** Nearest-neighbour filtering,
a new art scale, and a palette lock touch `project.godot`, `process_assets.py`,
every existing asset, and the traveller. If it goes wrong it goes wrong
everywhere at once, and the round has no fallback position because everything
else sits on top of it. The honest mitigation is sequencing: the pack and the
rendering flip land first, alone, and get looked at before anyone builds on
them. If the flip is not convincing by itself, the round is in trouble and we
should know that early rather than at integration.

**The traveller will look like a foreign object, and this is the risk I rate
highest.** A LANCZOS-resampled smooth AI render standing in a nearest-filtered
32px pixel-art town is worse than either alone. It reads as a bug. Pixelization
(1.3) is my answer and it may simply not work: pixelizing a *render* is not the
same as pixel art, because a pixel artist chooses which pixels survive and a
box filter does not. If it looks like a JPEG artifact rather than a sprite, the
round's choices narrow to the LPC reserve character (contradicting Scott's
carve-out) or codex regenerating the traveller natively at pack scale via
sprite-forge, which is a real option and possibly the better one: **generating
at 64px is a fundamentally easier ask than generating at 160px and shrinking**,
and it is plausible that the whole round-1-through-3 walk cycle saga was
partly an artifact of asking for too much resolution.

**Pixelization could destroy the alternation signal.** Downsampling 4x means
the two-pixel foot gap that carries the whole alternation read might quantize
away. The gate will catch it (that is what the gate is for and it has rejected
honestly every time), but "the gate catches it" means the round loses
requirement 1, not that the round is safe.

**The LPC CC-BY carve-out may not survive contact with the actual source
pages.** I am relying on a documented statement that Sharm's and Redshrike's
contributions are available under CC-BY 3.0. If per-file provenance turns out
to be unsubstantiable, the primary pack collapses to the Kenney fallback
mid-round, which is a vibe downgrade discovered late. **This is cheap to
falsify and it should be falsified before anyone commits a single PNG.** It is
exactly the shape of thing decision 005's retro says to test before voting on:
"when a ballot's premise is empirically testable, test it before you vote on
it".

**The silhouette shadow may look wrong on the two existing building facades.**
Shearing a sprite's alpha gives you the shadow of the whole sprite, which is
correct for a building drawn in oblique three-quarter and wrong for one drawn
flat-on. Our two facades are AI-generated and I do not know which they are
without looking. If they shear badly, the fallback is a hand-authored shadow
sprite per building, which is what Bullfrog actually did and which is only two
buildings' worth of work.

**Requirement 4 is the one piece I am confident about**, which is itself worth
flagging: I may be over-confident because it is the piece that looks most like
the work I am good at, and the round is not going to be judged on A*. Scott's
verdict was that the machinery is fine and the game is not.

**My one hour and one question.** I would launch the round-003 build, walk the
traveller onto the road, and capture single frames at 1x and at zoom-in. The
question: **is the float a sprite-anchor offset, an unclamped vertical bounce
in the walk cycle, or the absence of a contact shadow?** Requirement 7 is the
only requirement in this round where I am guessing at the cause, and all three
candidates have different fixes in different files. Everything else here I can
argue from the source. That one I would be pretending.

## 3. Division-of-labor claim

**I claim the sim and render *code* slices: requirement 4 (road-weighted A*
plus the heuristic scaling and its tests), requirement 5 (the camera rig
refactor and the InputMap actions), requirement 6 and 7's `shadow_caster.gd`
module, requirement 3's sim-side flora data and its render-side placement, and
the ground sub-tiling plus the positional-hash determinism fix in 1.8.**

Why me: both protected paths in this round are in my slice, and both carry a
correctness argument that has to be made in prose and defended, not just typed.
The `nav_grid.gd` heuristic scaling is a determinism regression that passes
every existing test if you get it wrong, and I have already read that file's
determinism argument closely enough to know exactly where it breaks. The
`starter_town.gd` y-sort bottom-edge comment is the same shape of hazard for
flora, and I know why it is there. This is code with invariants stated in
comments, and reading invariants out of prose and preserving them is the
strongest thing my harness does.

**I do not claim the art generation, and I did not claim it in round 003
either, for the same reason.** Codex's harness is natively better for it, the
sprite-forge skills are Codex's to exercise, and Scott has made that a
requirement of this round rather than a preference. Requirement 1's generation
work and any custom traveller regeneration is codex's.

**I would give the pack adoption and the rendering-model flip to agy, not to
me and not to codex.** It is a taste call more than a code call: which subset
of LPC ships, what the palette is, what the art scale is, whether the result
actually looks like the references. Agy's chromatic-boots insight in round 003
was the round's best idea and it came from thinking about the image rather than
the pipeline. This slice needs that. The pieces I claim all *consume* the pack;
they do not require me to be the one who picks it.

**The pack license verification is a splinter I would hand to whoever starts
earliest, including me.** It is an hour of reading source pages and it gates
everyone. It should not wait for slice assignment.

**`build_walk_gif.py` I will take** if codex would rather spend its budget on
generation. It is a harness, it is deterministic, and it is exactly the kind of
thing that should not eat the art seat's time.

## 4. Rough estimate

Order of magnitude, honest, in dispatches rather than hours.

- **Pack license verification: half a dispatch.** Gates everything, so it goes
  first.
- **Pack adoption plus rendering-model flip: one to two dispatches.** Two if the
  LPC carve-out collapses and we re-cut against Kenney.
- **My code slice, all of it: one dispatch.** Road costs plus heuristic plus
  tests is a couple of hours. The camera rig refactor is small but touches a
  parenting assumption baked into `_spawn_player()`. `shadow_caster.gd` is one
  file. Flora is data plus a loop. Ground sub-tiling is contained. None of it
  is hard; all of it is in files I have read.
- **Requirement 1: one dispatch, plus a coin flip.** Pixelize plus GIF harness
  is a dispatch. Whether it *works* is not something a dispatch count answers.

**Call it three to four dispatches to a round that ships all seven, with
requirement 1 the only one I would not bet on.**

**What blows it up, in descending order of probability:**

1. **The rendering-model flip does not convince.** Then requirement 2 fails,
   and requirement 2 failing is the round failing, because "make it look like a
   game" is the assignment and the other six are how. This is unbounded: there
   is no dispatch count that fixes "we picked the wrong direction". It is the
   reason section 2's mitigation is to sequence the flip first and look at it
   alone.
2. **The traveller cannot be made to belong in the town.** Bounded by the LPC
   reserve character, but taking that reserve is an escalation to Scott, and
   escalations cost a round boundary.
3. **The LPC carve-out fails.** Bounded, costs one dispatch, downgrades the
   vibe.
4. **Requirement 1 needs a human artist.** Decision 005 already says this in
   the team's own words. If it is true, no number of dispatches closes it, and
   the round should say so in the record rather than spend a fourth generation
   budget proving it a third time.

I want to name the last one clearly, because it is the thing this round is most
likely to get wrong: **the team has now failed requirement 1's ancestor three
rounds running, each time by trying harder at generation.** Decision 005's retro
drew the right lesson ("cheap falsification over confident deliberation") and
the walk cycle is where we have consistently refused to apply it. Pixelization
is my attempt at a cheap falsification. If it fails, the honest move is to take
the reserve and ship a walk cycle Scott can look at, not to write a fourth
BLOCKED marker.

## Sources

- [Tiny Swords, Pixel Frog](https://pixelfrog-assets.itch.io/tiny-swords)
- [Liberated Pixel Cup (LPC) Base Assets, OpenGameArt](https://opengameart.org/content/liberated-pixel-cup-lpc-base-assets-sprites-map-tiles)
- [Liberated Pixel Cup FAQ](https://lpc.opengameart.org/content/faq)
- [Roguelike/RPG pack, Kenney](https://kenney.nl/assets/roguelike-rpg-pack)
- [Isometric 64x64 Outside Tileset, Yar, OpenGameArt](https://opengameart.org/content/isometric-64x64-outside-tileset)
- [Isometric 64x64 Medieval Building Tileset, Seth Galbraith, OpenGameArt](https://opengameart.org/content/isometric-64x64-medieval-building-tileset)
- [CorsixTH](https://github.com/CorsixTH/CorsixTH), technique reference only, assets never.
