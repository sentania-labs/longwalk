# Codex worker, round 005 phase-2 critique

## Claude-worker proposal

### Steelman

Claude's strongest argument is that isometric presentation should be a small,
pure render transform over an unchanged authored grid, with coherent family
plates providing substantially better visual continuity than independent
assets without making the entire art set hostage to one generation. Its
explicit acknowledgement that grid-space steering, tall-sprite sorting, and
plate coherence are real risks makes it the most technically candid proposal
of the two.

### Attack: four facings save the wrong cost

**What I attack:** Claude's choice to ship four diagonal facings and call eight
a later data-only expansion.

**Why it is wrong or costly:** Click-to-move does not constrain travel to the
four screen diagonals. With four 90-degree sectors, a character moving 10
degrees above screen east uses a northeast or southeast diagonal pose whose
body axis is roughly 35 degrees away from travel. On a long road this reads as
sideways skating for almost half of each sector. Adding four angle constants
later may be a one-line selector change, but supplying and validating the other
24 frames for a six-frame cycle is not a data-only change. It is a second
identity-consistency generation pass, manifest change, QC pass, GIF change,
and acceptance round. Claude counts only sheet area while omitting that
deferred integration cost.

**What should happen instead:** Commit and test eight fixed 45-degree sectors
before generation, advance frames from distance traveled, and generate all
eight as one accepted character contract. If generation cannot sustain 48
frames, use four authored facings plus four declared mirrors only after testing
the asymmetric costume. Do not ship a four-sector runtime contract while
describing eight as trivial.

### Attack: projection plus plain Y-sort is not a sufficient depth model

**What I attack:** The claim that Y-sort "falls out for free" from projected
anchor Y, together with the mitigation of keeping footprints to one or two
cells or splitting wide buildings.

**Why it is wrong or costly:** Anchor Y orders points, not footprints. Two
objects can share the same `x + y`, and a player can move behind the rear edge
of a 2x2 building while its single front anchor still sorts the whole sprite in
front. A stable tie policy is also absent. Splitting generated building art is
not free: every split needs seam-safe overlap, coordinated anchors, shadows,
and collision correspondence. At 200 props, per-building splits and depth
biases become asset-specific exceptions, precisely the scaling failure a
render spine should prevent.

**What should happen instead:** Define a footprint-aware render contract now:
contact anchors, stable authored placement IDs for ties, explicit occlusion
parts for multi-cell buildings, and tests placing the actor at every footprint
edge. Use plain anchor Y-sort only for point props proven to fit that contract.

### Attack: discarding physics changes more than presentation

**What I attack:** Replacing `CharacterBody2D.move_and_slide()` with fractional
grid interpolation and treating colliders as advisory.

**Why it is wrong or costly:** The current controller calls `move_and_slide()`
and active tests assert exact footprint collider geometry against
`TownLayout.TILE_SIZE`. Removing collision authority changes gameplay behavior
and invalidates a tested contract merely to make a render projection easier.
It also creates known debt as soon as scheduled NPCs or ecology agents become
dynamic obstacles. A server-side simulation cannot rely on a render node's
fractional grid interpolation, so this design risks two movement truths.

**What should happen instead:** Keep authoritative movement and collision in
the existing logical world coordinate space, then project the render proxy.
If the controller must separate logical and visual positions, make that split
explicit and test that navigation, collision, and rendering consume the right
side. Isometric rendering should not silently retire collision semantics.

### Attack: plate handoff and regeneration are not fully specified

**What I attack:** Four coherent plates linked by a prior accepted plate as a
style reference.

**Why it is wrong or costly:** Carry-forward references form a chain. Drift in
plate B becomes the reference for C and D, while ground and character never
share one scene-level check until late. Regenerating one building inside a
two-building plate either changes its sibling too or requires a new method.
The proposal also names a palette ramp but no automated measurement that can
reject a plate whose light direction, scale, or values drift.

**What should happen instead:** Start with a non-runtime style board containing
ground, actor, building, and flora at shipping scale, then use it as the same
reference for every family rather than chaining outputs. Generate compact
families together but large, collision-sensitive buildings individually.
Require manifests and a real-camera composition gate before producing all
assets. On this point, the style-board-led part of my proposal is stronger than
Claude's plate chain.

### Attack: camera ownership should follow state-machine context

**What I attack:** Claude's claim to fold drag-pan into the projection spine.

**Why it is wrong or costly:** `src/render/town/camera_rig_2d.gd` already owns
FOLLOW and FOCUSED transitions, zoom behavior, bounds, and the `focus_view`
input. Projection integration must provide projected bounds and inverse
picking, but it need not own camera input semantics. Giving both the projection
and camera changes to one slice increases the critical path and discards Agy's
round-004 context. This is a technical ownership issue, not a fairness issue.

**What should happen instead:** Agy should own camera state transitions,
drag-threshold semantics, cursor-preserving zoom, and tests. The projection
owner should supply pure transforms and projected map extents. Their interface
should be fixed before either implementation begins.

### Concessions

Claude is right, and my proposal should adopt this more explicitly, that the
projection module belongs entirely under `src/render/`, ground should not be
Y-sorted, and all object anchors must represent ground contact. Claude is also
right that one mega-sheet for unrelated runtime categories makes selective
regeneration unnecessarily destructive.

## Agy-worker proposal

### Steelman

Agy's strongest argument is that a single generation context maximizes palette,
lighting, proportion, and character identity coherence, while blind manifest
slicing prevents aesthetic frame selection from laundering a failed sheet.
Its claim to the camera work is technically strong because Agy authored the
existing state machine and can amend it with the least rediscovery.

### Attack: full-sheet generation correlates every failure

**What I attack:** Full-sheet generation for an entire 8-facing walk cycle or
full village set.

**Why it is wrong or costly:** An eight-facing, six-frame walk is 48 cells, not
merely an `8xN` abstraction. One malformed hand, edge-touching silhouette,
wrong facing, or drifting feet line either forces rejection of the entire
sheet or tempts exactly the manual exception the blind-slicing rule forbids.
A full village sheet couples even less compatible scales: ground transitions
need seamless edges, buildings need large silhouettes and accurate contact
anchors, and flora needs transparent margins. Giving all of them equal cells
wastes resolution on ground or starves buildings. It also makes regenerating
one bad building destructive to every accepted asset on the sheet.

**What should happen instead:** Use a scene-level style board as the coherence
master, compact category sheets for ground and small flora, individual large
props and buildings, and per-facing 2x3 walk grids tied to one accepted neutral
character master. The same visible reference should lead every call.

### Attack: the pipeline cannot survive untouched

**What I attack:** The assertion that `process_assets.py`,
`build_player_walk.py`, `build_walk_comparison.py`, and
`capture_art_acceptance.gd` survive untouched because they operate on extracted
frames.

**Why it is wrong or costly:** The repository describes
`build_player_walk.py` as deterministic Option C assembly, and its tests guard
that specific authored pipeline. The current scripts encode asset lists,
dimensions, frame policy, and acceptance assumptions. Eight facings introduce
facing order, frame roles, per-frame anchors, stride phase, possible mirroring,
and diamond-route preview requirements. A configured cell size alone carries
none of those contracts. "Untouched" therefore omits both implementation and
test migration.

**What should happen instead:** Make ingest and walk assembly manifest-driven,
version the eight-facing runtime contract, preserve deterministic image
processing only where it is genuinely generic, and update tests and previews
as first-class work. The processor may normalize anchors mechanically, but it
must not choose aesthetically preferred frames.

### Attack: center-of-mass alignment is the wrong stabilizer

**What I attack:** Center-of-mass alignment as the likely response to frame
drift.

**Why it is wrong or costly:** A walk cycle deliberately changes limb mass and
silhouette. Aligning opaque-pixel centroids can make the feet slide in order to
hold a swinging arm or coat centered. That produces stable bounding boxes and
an unstable ground contact, the opposite of what movement needs.

**What should happen instead:** Require a declared feet/contact anchor for
each cell, validate its variance against a fixed feet line, and align by that
anchor. Reject sheets whose body identity or pose cannot pass blind anchor
checks.

### Attack: generated shadow sheets add incoherence without a contract

**What I attack:** A secondary generated shadow sheet, or an assumed black and
alpha layer from the generator.

**Why it is wrong or costly:** Independently generated shadows can disagree
with the accepted sprite silhouette, contact point, and shared light vector.
That creates another correlated sheet requiring subjective pairing with every
asset. The proposal supplies no manifest relation or deterministic test between
sprite and shadow.

**What should happen instead:** Derive contact and cast-shadow masks
deterministically from the cleaned accepted alpha, with one fixed projection,
maximum length, tint, and anchor policy. Hand-authored exceptions should be
declared in the manifest, not selected at runtime.

### Attack: drag-pan semantics are underspecified

**What I attack:** Subtracting mouse motion from camera `global_position` and
immediately breaking FOLLOW.

**Why it is wrong or costly:** Raw `event.relative` is viewport pixels while
camera position is world units, so the delta must account for zoom. The plan
does not say what a press without meaningful motion does, whether release
returns to a prior state, how projected diamond bounds replace orthogonal
`pixel_size()` limits, or how existing FOCUSED tests change. Immediate state
break on press makes an accidental right click alter the camera mode.

**What should happen instead:** Record press position and state, cross a tested
pixel threshold before entering DRAG, apply `relative / zoom`, clamp against
the four projected corners plus sprite headroom, and specify release and Space
transitions. Agy should still own this slice because those details live in the
state machine Agy authored.

### Attack: the estimate is not credible

**What I attack:** One to two calendar days, with three to four extra days only
if the 64-frame sheet fails.

**Why it is wrong or costly:** Even without regeneration, the work includes a
new projection and inverse, controller/picking changes, depth ordering,
projected camera limits, drag state and tests, ground transitions, buildings,
flora, eight-facing animation, shadow processing, pipeline migration, updated
test contracts, and real-engine acceptance artifacts. The current active tests
are tied to square `TILE_SIZE`, `world_to_cell`, collider geometry, FOLLOW and
FOCUSED state, and `focus_view`. Calling this one to two days omits integration
and validation, not merely art uncertainty.

**What should happen instead:** Budget roughly 6 to 10 focused worker-days
across three residents, with an early five-asset camera composition spike.
Explicitly reserve regeneration and projected-town placement repair as
contingency.

### Concessions

Agy is right, and Claude's ownership claim is weaker here, that the author of
the current camera rig should own its drag-pan amendment. Agy is also right to
insist on blind slicing and regeneration rather than hand-picking successful
frames. Those policies should survive, but at category and per-facing
granularity rather than one mega-sheet.

## Synthesis recommendations

Use a render-only projection with unchanged sim data, a scene-level style board
as the common visual reference, category sheets where cell geometry is shared,
individual generation for large collision-sensitive props, and eight fixed
facings assembled from manifest-driven per-facing grids. Keep movement and
collision authoritative outside presentation. Give Agy camera state-machine
ownership, Claude projection and scene integration, and Codex generation plus
deterministic processing. Gate the full production run on one real-camera
composition containing ground transitions, one actor facing, one building, one
tree, contact shadows, and a road junction.
