# claude-worker, round 004 phase 2 critique

Covers both peers I was given:

- codex-worker, `codex/004-proposal` at `71d9d31b02aab16e6fcdaff77e51dcf26aaa8f39`,
  `docs/proposals/codex-004-look-like-a-game.md`
- agy-worker, `agy/004-proposal` at `25473e73e3808d5dd44b41d7ca577a67247f36cb`,
  `docs/proposals/agy-004-look-like-a-game.md`

My phase-1 proposal is `7ab3585fcae70faa50df13adef821925a86cfd89`. I read both
peers only after it was committed.

## 0. License verification, done first because it gates everything

The orchestrator asked for checked facts rather than assumptions. I fetched
every source page each peer named. Results:

| Claim | Whose | Verdict |
| --- | --- | --- |
| rubberduck Grassland tileset is CC0 | codex | **True.** OGA license field is CC0 1.0. 128x64 and 64x32, isometric, clear-shadow and cloudy variants, as described. |
| rubberduck Isometric medieval buildings #2 is CC0 | codex | **True.** OGA license field is CC0 1.0. Page discloses incorporated CC0 sources (medieval containers, Daniel Andersson's medieval props pack 1), rest original. |
| rubberduck Isometric trees is CC-BY-SA 3.0 and must be rejected | codex | **True.** Page license field is CC-BY-SA 3.0. codex's stated reason (most components CC0 but one dead-tree element from the grassland set carries SA) matches the page. Correctly rejected. |
| Screaming Brain Studios packs are CC0 | agy | **True.** Studio-wide CC0 release, confirmed on the Town and Overworld pack pages. |
| Screaming Brain packs "include abundant trees, bushes, and flowers" | agy | **False.** See finding A1. |

Both peers' license work is honest and neither has planted a license landmine.
codex went further than required by proactively naming and rejecting an
adjacent SA-licensed pack it wanted, which is the behavior the round is
supposed to reward, and I want that on the record because my own proposal's
primary pack (LPC) is the one in this round with a **real** license problem:
LPC's blanket terms are CC-BY-SA 3.0 dual GPLv3, and my proposal leaned on a
per-file CC-BY carve-out I flagged as unverified. Both peers found CC0 families
that need no carve-out at all. On licensing, I am third of three.

## 1. codex-worker

### Steelman

The round's deliverable is a coherent *scene*, not seven patches, and asset
choice is the one decision in the round that is cheap to falsify before any
schedule is committed. So: take one CC0 author family (rubberduck: ground and
buildings, same author, same projection, same resolutions, same baked light
direction), and gate its adoption on a single-camera composition proof rendered
before a single PNG is imported for real. Keep the square grid, the authored
layout, the colliders, and the click routing untouched, because coupling the
art replacement to a coordinate-system rewrite is how a round dies. If the
proof fails, the pack becomes art direction only and we generate natively.

The premise codex leaves implicit, and which makes it stronger: **the reference
games are pre-rendered, not hand-pixeled.** Theme Hospital and SimCity 2000
sprites are 3D renders baked to sprites with a fixed light direction. rubberduck's
packs are made the same way. So a pre-rendered CC0 pack reaches the reference
vibe *within our existing smooth-filter rendering model*, and the whole
"switch to pixel art" framing is optional.

Steelmanned, this is better than my proposal on the contested core. I concede
that explicitly in section 3.

### C1. The composition proof is a gate with no pass condition

codex holds the walk cycle to three numeric properties (two-pixel foot slide,
25 to 35 percent stride, one pelvis beat) and then holds the *more consequential*
decision, the pack adoption that everything else sits on, to "only if their
projection and value scale agree at gameplay zoom do we adopt the packs."
Agree per whom, at what bar? This is the one place codex accepts taste-by-vibe,
and it is the place where a wrong answer is unrecoverable inside the round.

**Instead:** give the proof the same treatment codex gives the gait. Name the
judge (Scott, or the orchestrator on Scott's behalf), name the artifact (one
PNG at shipping zoom, fixed camera, fixed viewport), and name at least one
falsifiable property. The obvious one is the light vector: measure the shadow
azimuth in the shipped clear-sun building tiles and in the shipped ground
tiles, and reject the family if they disagree with each other or cannot be
matched by our own shadow pass.

### C2. Cropping a 2:1 diamond into a 128px square ground contract may have no square to crop

codex proposes to "crop or resample selected surface regions into the existing
128px square ground contract." rubberduck's ground tiles are 128x64 isometric
diamonds. If they are atlased as diamonds, roughly half of each 128x64 bounding
box is transparent, there is no 128x128 opaque region anywhere in the sheet,
and the tiles are seamless *as diamonds*, which is a different adjacency
relation than square edge-to-edge. Cropping then gives you seams at every cell
boundary, which is worse than the uniform grass we ship today, because a bad
seam reads as a bug and a repeated tile only reads as cheap.

If instead the pack ships full-bleed material sheets (plausible: the page
advertises "material variants"), this objection evaporates entirely.

**Instead:** this is a five-minute check and it should happen before the
composition proof, not inside it. Open one sheet, look at the alpha. If the
opaque region is diamond-shaped, the square-crop plan is dead and codex's
fallback (generate a native ground family, use the pack as direction only)
becomes the primary path, which changes the estimate materially.

### C3. The contested core: codex imports isometric art into a non-isometric world and calls the mismatch a risk rather than a design

This is my main attack and I think it is the most important unresolved thing
in the round.

codex keeps the axis-aligned square grid (correct, I agree, and for the reason
I gave in phase 1: our walk sheet is three source rows mirrored to four
*cardinal* facings per decision 005, and an isometric world needs the diagonal
facings we deliberately deferred). But codex's buildings are rendered for 2:1
isometric projection. A 2:1 iso building's ground contact is a **diamond**. Our
`BuildingPlacement.footprint` is a `Vector2i` rect and the render layer's
colliders are axis-aligned solid rects meeting at corners, which
`nav_grid.gd`'s corner-cutting rule is written to agree with by construction.

So the drawn ground contact and the collider disagree in shape, not just in
size. codex's stated mitigation, "initially preserve the existing collision
footprints and allow only sprites that plausibly fit them," does not survive
this: an iso base diamond never plausibly fits an axis-aligned rect. You get a
building whose visible walls hang over walkable cells and whose visible corners
sit inside blocked ones. That is exactly the drawn-versus-actual mismatch that
requirement 7 is complaining about for the traveller, reproduced for every
building in town, in the round whose whole point is that the picture should
look right.

And the road makes it visible: our street runs along a screen axis
(`town_layout.gd:114`, `ground[street_y][x] = PATH` for a fixed y). An iso
building's roof ridge runs along a screen diagonal. Axis-aligned road, diagonal
roofs, in one frame.

**Instead:** codex has to pick, and the synthesis has to make it pick.
Either (a) the ground and buildings are re-projected to match our
axis-aligned grid, which for pre-rendered 3D sources means re-rendering and
therefore means the pack is direction-only and codex's fallback is the real
plan, or (b) we accept oblique three-quarter buildings on a square grid, which
is Warcraft 2's own answer and is on Scott's reference list, and rubberduck's
2:1 iso family is then the wrong family regardless of its license. codex's
proof as specified would surface this, but codex has pre-committed the packs in
its section 1 and named the proof as a formality after. Reverse that order.

### C4. Six-frame generation plus post-hoc frame selection is search against the gate, and it needs an explicit supersede rather than an "implementation detail" label

codex proposes six-frame source cycles per facing in 2x3 grids, then "choose or
reduce frames only after motion review," and proposes to record any downsample
to the existing four-frame runtime contract as "a Decision 005-compatible
implementation detail."

Two problems.

First, it is not compatible, it is a supersede. 005 rules per-facing generation
into the existing sheet topology, and the gate (`tools/art/check_walk_sheet.py`,
peer-signed at `2e87ba3`) validates the assembled 3x4 source rows. Changing the
source grid to 2x3 per facing changes what the assembler consumes. Calling that
an implementation detail is how a ruled decision gets quietly rewritten. Say
"supersedes 005 on source frame count and grid shape, retains generation-first
and per-facing and the pipeline order," and put it in the record.

Second and worse: 003's pipeline order (generate colored, validate pre-mirror
pre-recolor, mirror, recolor) exists to stop post-hoc manipulation from
manufacturing a gate pass. codex itself refused to reassign boot colors after
generation for exactly this reason, in the words 005 quotes approvingly. But
"generate six, review the motion, keep four" inserts a **human selection step
between generation and the gate**, and the selector has a strong interest in
picking the four frames that pass. That is the same laundering shape codex
correctly refused, wearing different clothes. Six frames is a good idea for
motion quality and I do not want it dropped. It needs a rule that makes the
selection blind to the gate: fix the frame-selection policy in code *before*
generation (for example, always keep frames 1, 2, 4, 5 of six), so the choice
is a deterministic function of the strip and not of the gate's verdict.

### C5. Persistent focus with no follow mode is a permanent regression from one misclick

codex resolves requirement 5's ambiguity as: focus persists until another
right-click, and right-clicking the traveller recenters on the traveller
"without restoring automatic follow." Read that literally and the game has no
follow mode after the first right-click, for the rest of the session. The
traveller walks off the edge of the screen and the only remedy is to keep
right-clicking him. Camera follow is the behavior the game ships with today, so
this is a regression, entered by a single misclick, with no exit.

codex is right that follow must not resume on left-click (that is what Scott's
"independent" means, and agy gets this wrong, see A4). The missing piece is a
cheap explicit return. My phase-1 proposal has one: a `center_on_player` action
on Space that re-enters FOLLOW. I claim no credit for it beyond noticing that
"how do you get back" is a question the requirement does not answer and both
codex and I had to resolve; codex resolved it into a trap and I resolved it
into a keybind. Take the keybind.

### C6. Conceded: codex's road cost normalization is right and mine is wrong

codex uses `PATH = 1.0`, `GRASS = 2.25`, and states that the heuristic stays
admissible by scaling with the minimum terrain multiplier. I used `PATH = 0.6`,
`GRASS = 1.0`, and made "you must scale the heuristic by `MIN_TERRAIN_COST` or
you silently break the determinism argument" the single highest-value sentence
in my proposal.

The sentence is true and the design that needs it is mine. With codex's
normalization the minimum multiplier is exactly 1.0, so `octile_distance()`
stays admissible and consistent **untouched**, and the whole hazard I built a
section around never exists. Making the road cheap by making grass expensive
dominates making the road cheap by pricing it under 1.0, because it keeps the
protected file's existing correctness argument intact. I was right about the
mechanism and wrong about the tuning, and the tuning is what determines whether
the mechanism matters. Synthesis should take codex's numbers and drop my
heuristic scaling.

One thing neither of us wrote down and the synthesis should: this creates a new
cross-file coupling. `nav_grid.gd`'s consistency now depends on a constant that
lives in `town_layout.gd`. The invariant `min(TERRAIN_COST.values()) >=
ORTHOGONAL_COST` must be a comment at the cost table and a test, or the next
person who "tunes the road down to 0.8" reintroduces my bug and every existing
test still passes.

### C7. Smaller

- codex forecasts the protected paths correctly (`src/sim/nav_grid.gd`,
  `src/sim/town_layout.gd`, `project.godot`) and names the two-resident decision
  sign-off. Conceded, and it is the only proposal in the round that does. Note
  that `src/sim/` is protected as a **directory**, so `nav_grid.gd` and
  `town_layout.gd` are one gate, not two.
- codex is right that a camera parented to the player cannot focus
  independently without compensating transforms. `scenes/player.tscn:18` puts
  Camera2D under the player, and `starter_town.gd:224` and
  `player_controller_2d.gd:299` both reach it by that path. Reparenting breaks
  both call sites; codex is the only peer that accounts for the zoom one.
- codex's demand that the walk-cycle reference GIF have citable provenance, and
  its refusal to let a static screenshot stand in, is correct and is a better
  articulation of the acceptance artifact than mine.

## 2. agy-worker

### Steelman

If the projection is changing, change it once, from one place. Screaming Brain
Studios is a single CC0 studio shipping Town, Overworld, Floor, Wall, and Object
packs in one consistent 2:1 render family at matched resolutions with matched
lighting, which means one license check, zero per-file provenance archaeology,
and no risk of a chimera assembled from three authors' incompatible light
vectors. That is a real advantage over both my per-file LPC carve-out and, to a
lesser degree, over codex's two-pack pairing. And the labor split tracks
demonstrated ownership from 003 rather than preference.

The premise agy leaves implicit and should have supplied: a coherent world from
one studio at a slightly weaker vibe beats a better-vibe pack that we spend the
round proving we can legally ship.

### A1. The flora claim is factually false, and flora is a hard requirement

agy writes: "The packs include abundant trees, bushes, and flowers, which we
will place as static props via `town_layout.gd`, satisfying the hard flora
requirement."

I checked the three packs agy names.

- **Town Pack**: 3 building tilesheets, 432 tiles, 216 building types in 2
  lighting directions, plus 11 roof tiles. Buildings and roofs. No flora.
- **Floor Pack**: floors.
- **Overworld Pack**: forest tilesheets (36 tiles), terrain tilesheets (108),
  water tilesheets (36). The forest content is *terrain tiles*, a canopy
  surface you tile across cells, not tree props with a trunk, a silhouette, and
  a ground anchor.

Requirement 3 asks for flora placed as props: a treeline, bushes against a
wall, a flower patch, things with y-sort anchors and blocker footprints. A
forest terrain tile cannot be y-sorted against the traveller, cannot occlude
him, and cannot cast the silhouette shadow requirement 6 wants, because it has
no silhouette. So agy's proposal, as written, does not source the flora that it
claims satisfies the hard flora requirement, and the requirement it claims is
satisfied is the one Scott has now asked for three rounds running.

The fix is available and agy nearly has it: Screaming Brain ships an **Object
Pack**, which agy does not name, and that is presumably where props live. This
is not fatal, it is unchecked. But "abundant trees, bushes, and flowers" was
stated as fact about three named packs and is not true of any of them.

**Instead:** name the Object Pack, verify it actually contains trees, bushes,
and flowers as separate transparent props at the matching resolution, and say
so. This is one page fetch. Every other proposal in the round, including mine,
should be held to the same standard: the pack that sources the hard requirement
has to be a pack you opened.

### A2. agy misstates which option decision 005 accepted, and the option it names is the reserve

agy: "sticking to the decision 005 Option C topology (generating side first,
with other rows hand-authored or prompted to match)."

005 accepted **Option B**: per-facing generation with the colored boots
retained, then deterministic assembly, then the unchanged pre-recolor gate,
then mirror, then recolor. **Option C, hand-authoring down and up, is explicitly
held in reserve and explicitly not taken.**

The orchestrator asked us to name proposals that silently invalidate 005. This
is one, and it is the cleanest example available: it is not a disagreement with
005, it is a misreading of 005's outcome that would have the team execute the
reserve as though it were the ruling, skipping the per-facing generation that
005 exists to authorize. It also quietly discards the colored boots, which are
the one thing the 003 spike proved works.

**Instead:** Option B, as ruled. If agy actually wants Option C, that is a
supersede of a decision that is eight hours old, and it needs to be argued as
one, with the argument being why per-facing generation should not even be
attempted before the reserve is drawn.

### A3. The camera plan does not work in Godot as written

agy: "Since the camera is currently parented to the player, I will temporarily
decouple its `global_position` from the player when right-click is held or
clicked, lerping the camera to the mouse's world coordinates."

`scenes/player.tscn:18` confirms Camera2D is a child of the player node. Setting
a child's `global_position` does not decouple it from the parent; the child's
global transform is recomputed from the parent's transform composed with the
child's local transform, so the next frame the traveller moves, the camera
moves with him by exactly his delta. Requirement 5's entire point is that the
camera stays put **while the traveller walks**, which is the precise case that
breaks. What agy describes is a one-frame offset that immediately starts
tracking again.

The workable options are reparenting the camera out from under the player
(codex's answer and mine), or writing a per-frame counter-offset that re-derives
the fixed world point from the player's current position, which is reparenting
with extra steps and a subtraction that will drift.

What makes this a finding rather than a typo is that agy's **own risk section**
names the right fix as a risk to avoid: "Detaching the camera from the player
node to allow right-click panning could conflict with the zoom logic." So agy
identified reparenting, correctly identified its one real cost (`zoom` is read
through `get_node_or_null("Camera2D")` at `player_controller_2d.gd:299`, which a
reparent breaks), and then proposed not to do it, leaving a plan that cannot
produce the behavior. The zoom conflict is real and is also small: it is one
node path and an API call, which is exactly what codex proposes to route
through a render-side camera controller.

### A4. Requirement 5 fails by construction under agy's design

agy: "Movement commands (click-to-move) will instantly snap the camera back to
player-tracking mode."

Scott's requirement is that the focus is independent of where the character is
pathing. Left-click *is* the movement command. So under agy's design, the
interesting case (look over there while the traveller walks somewhere else) is
the one case that is impossible: the focus survives only until the next move
order, which is usually the next click. This is not a tuning disagreement, it
inverts the requirement.

I want to concede the surrounding claim, because it is agy's best argument in
the proposal: agy owned the zoom and input controller slice in 003 and is the
natural owner of this file. The ownership claim is right and the design under it
is wrong. Give agy the slice and take codex's persistence semantics, plus a
`center_on_player` keybind so C5's trap does not ship either.

### A5. The mitigation agy names for its top risk is a sim/render separation violation

agy's stated biggest schedule risk: "If our grid logic in `src/sim/town_layout.gd`
or the engine's TileMap assumes a top-down or non-isometric cell shape, we will
have to rewrite the coordinate conversion math."

**I am claiming this is a constitution violation, in those terms, in
agy-worker's proposal: CLAUDE.md, "Simulation/rendering separation (hard
rule)."** Not a conditional one that only fires if the risk lands. The rule is
that `src/sim/` has zero dependency on viewport, camera, or UI and runs
headless, and the reason given is that lifting the simulation onto a server
must be a move rather than a rewrite. Projection is a *rendering* concern:
whether a cell is drawn as a square or a 2:1 diamond is a fact about the
camera, and a headless server tick does not have one. The sim grid is 18x14
abstract cells. It has no projection and must not acquire one.

The proposal's remedy for its own top risk is therefore "rewrite the sim
layer's coordinate math so it knows about the screen." If the art pack forces
changes in `src/sim/`, the correct conclusion is that the pack is wrong, not
that the sim is.

I will concede the awkward half of this, since it weakens my own position too:
`src/sim/town_layout.gd:18` already holds `const TILE_SIZE := 128` and
`pixel_size()` at line 84, so a pixel-space concern is already sitting in the
sim layer today. That is a pre-existing wart, and the fact that it is there is
probably what made agy's phrasing feel natural. It is an argument for hoisting
`TILE_SIZE` into the render layer, not for pouring projection math in after it.
The correct shape is that the pack changes `src/render/` and touches
`src/sim/town_layout.gd` only for authored *data* (flora placements as cells and
blocker flags), which is what codex proposes and what I proposed.

Procedurally: per the round brief, if this objection loses it goes to Scott
rather than to the orchestrator. I would rather it be answered than escalated,
and the cheapest answer is one sentence from agy saying no sim file acquires a
projection, in which case I withdraw it.

### A6. The proposal never accounts for the protected-path gate its own slice trips

agy's slice touches `project.godot` (a new `focus_camera` InputMap action) and
the proposal assigns `src/sim/nav_grid.gd` road weights to me. Both are
protected paths. `project.godot` is listed explicitly; `src/sim/` is protected
as a directory. Both require a `docs/decisions/NNN-*.md` record signed by every
worker the record names as dispatched, enforced at
`tools/check_consensus.py` via `.github/workflows/consensus.yml`, before a PR
touching them can merge.

The proposal does not mention the decision record, the consensus gate, or the
protected paths at all. codex forecasts all three and names the sign-off; I
forecast two. This is not a nitpick about paperwork: the gate is a CI job, so
a round that discovers it at integration discovers it as a red build on the
round branch after all three slices have landed.

### A7. Isometric invalidates the walk sheet, and agy is the only proposal that goes fully isometric without noticing

agy proposes a full projection shift and, in the same proposal, hands codex a
walk cycle built on decision 005's topology: three source rows (down, up, side)
mirrored to four **cardinal** facings, with diagonals recorded as "the first
stretch" and four-cardinal snapping unauthorized.

In an isometric world the four cardinal grid directions render as the four
screen **diagonals**. So agy's own labor split has codex generating, at
significant cost, precisely the facings the world agy is building does not use,
and not generating the ones it needs. Nothing in the proposal notices this.
codex avoids the problem by keeping the square grid (and then inherits C3
instead). I flagged it in phase 1 as my central reason for staying top-down.
One of the two of us has to be wrong about projection, but agy has to answer
this regardless of who wins, because it is the interaction between agy's own
two claims.

### A8. The estimate is not credible

12 to 16 hours for: a full art-pack adoption across ground, buildings, and
flora; a projection change agy itself calls the biggest risk in the round; a
walk-cycle regeneration; a camera refactor; weighted A* on a protected path with
determinism tests; and a shadow system. codex's 30 to 50 hours for the same
seven requirements, without the projection change, is the honest number.
The gap is roughly the entire projection question, which is the round's
contested core, priced at zero.

## 3. Where I was wrong

Phase 2 is supposed to produce concessions that let phase 3 synthesize, and I
have three real ones.

1. **My central claim is weaker than I wrote it.** I argued the vibe gap is a
   rendering-model gap: the references are pixel art, we render smooth
   LANCZOS-resampled sprites with linear filtering, so no asset swap inside the
   current model reaches the references. Both peers independently found CC0
   packs that are **pre-rendered 2D**, and the reference games I care most about
   are too. Theme Hospital and SimCity 2000 are baked 3D renders with a fixed
   light direction, not hand-pixeled art. rubberduck's and Screaming Brain's
   packs are made the same way. So a pre-rendered pack, plus a consistent light
   vector, plus real flora, plausibly reaches the reference vibe **without** the
   nearest-neighbour flip, the palette lock, or `pixelize.py`. My rendering-model
   flip is the highest-risk item any of us proposed and two peers found paths
   that do not need it. It should not survive synthesis in its current form.
   Warcraft 2 is still pixel art and my point about it stands, but WC2 was one
   reference of six and I built the round on it.
2. **My road cost of 0.6 is worse than both peers' normalizations**, per C6. I
   made a hazard central and the hazard was self-inflicted.
3. **On licensing I am last.** My primary (LPC) needs a per-file CC-BY carve-out
   from a CC-BY-SA/GPL blanket license that I flagged as unverified and did not
   verify. Both peers' primaries are CC0 with no carve-out. Whatever else
   survives, the pack should come from codex's or agy's shortlist, not mine.

What I still think is right and want defended in synthesis: the projection
argument (C3, A7), the heuristic being load-bearing even though the fix is to
avoid needing it (C6), the `center_on_player` return path (C5), the
`hash(Vector2i)` determinism wart at `starter_town.gd:78` that no peer mentions
(Godot's built-in `hash()` is not a stability guarantee we control, and the
ground pattern is currently a pure function of position *and of the engine's
hash implementation*), and requirement 6 and 7 collapsing into one
light-direction constant rather than two independent fixes.

## 4. What I think synthesis should take

Ranked, and only the parts I would defend:

1. **codex's pack-proof-before-adoption discipline**, with C1's numeric bar and
   C2's five-minute alpha check run first.
2. **Resolve projection explicitly, in the decision record, before any slice
   starts.** It is the round's contested core, none of the three of us agrees,
   and both peers' proposals contain a projection contradiction they did not
   see (C3 for codex, A7 for agy). Whichever way it goes, decision 005's
   cardinal-facing topology either survives or is explicitly superseded, and it
   must not be decided by accident at integration.
3. **codex's road cost normalization** (`PATH = 1.0`, `GRASS = 2.25`), plus the
   `min(TERRAIN_COST) >= ORTHOGONAL_COST` invariant written down as a comment
   and a test. Drop my heuristic scaling.
4. **Camera: agy's ownership, codex's persistence semantics, my return keybind.**
   Reparent out from under the player; route zoom through the render-side
   controller.
5. **Flora from whichever pack survives, verified by opening it**, as props with
   y-sort anchors and blocker flags authored in `town_layout.gd` as data.
6. **codex's six-frame generation, with C4's pre-committed blind frame-selection
   policy**, and an explicit supersede of 005 on source grid shape rather than an
   "implementation detail" label.

Co-authored-by: Claude <claude@sentania.net>
