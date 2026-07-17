# Codex proposal: 004 look like a game

This proposal was written blind. I inspected the round branch, decisions 003
through 005, the read-only reference folder, the two required Codex art skills,
and public source and license pages. I did not inspect another resident's
proposal, branch, worktree, or inbox.

## 1. Approach

### Make one coherent playable scene, not seven isolated patches

I would keep the authored 18 by 14 town and its square navigation cells, but
replace the visible base layer and add separate runtime props. This is
`generate2dmap`'s `scene_mode`: layered raster, y-sorted props, precise blocker
shapes, and project-native Godot scenes. Ground stays a foundation layer;
buildings, trees, bushes, flowers, shadows, and the traveller remain separate.
That preserves click routing, collision, and curation while fixing the sparse,
flat presentation that the references expose. A wholesale isometric TileMap
conversion is the obvious alternative, but it would couple art replacement to
coordinate, collider, click, and authored-layout changes. That is too much risk
for this round.

The visual target is the shared grammar visible across the reference folder:
compact clusters, saturated but bounded materials, strong silhouettes, broken
terrain edges, dark directional cast shadows, and enough small vegetation to
make empty ground look intentional. It is not literal pixel imitation. The
current soft low-poly rendering can become a readable Bullfrog-era scene if the
projection, density, edge treatment, and lighting agree.

### Contested asset-pack choice

Adopt these two packs as one base family, both by rubberduck and both CC0:

1. [Grassland tileset](https://opengameart.org/content/grassland-tileset-1),
   specifically the 128x64, clear-sun-shadow material variants. It provides
   grass, earth, rocks, and walls with the crisp rendered surface variation the
   current repeated square grass tile lacks.
2. [Isometric medieval buildings #2](https://opengameart.org/content/isometric-medieval-buildings-2),
   specifically the clear-sun-shadow, non-winter variants. It uses the same
   author, projection, resolutions, and lighting family as the ground pack and
   includes shadow-free versions useful for our own silhouette-shadow pass.

Sample source previews:

![rubberduck grassland pack preview](https://opengameart.org/sites/default/files/styles/medium/public/grassland_tileset_prev.png)

![rubberduck medieval building pack preview](https://opengameart.org/sites/default/files/styles/medium/public/building_pack_03_prev.png)

I would first make a one-camera composition proof using one ground treatment,
one imported building, one existing building, one tree, and the traveller. Only
if their projection and value scale agree at gameplay zoom do we adopt the
packs. Import the selected original PNGs under `assets/vendor/rubberduck/`, keep
their license texts, and record author, source URL, license URL, selected files,
and any modifications in a new root `CREDITS.md`. CC0 does not require credit,
but the assignment does.

The grass sheets are not used as a baked runtime map and do not define the nav
grid. Crop or resample selected surface regions into the existing 128px square
ground contract, with deterministic render-side variants keyed by cell
coordinate. Buildings remain separate sprites with authored footprint
colliders. This is a controlled visual adaptation, not a TileMap rewrite.

Do not adopt the tempting companion
[isometric trees](https://opengameart.org/content/isometric-trees-0) pack. Its
page-level license is CC-BY-SA 3.0 even though most component sources are CC0.
Scott authorized CC0 and CC-BY, not share-alike. Also reject the
[Artyom Zagorskiy isometric medieval pack](https://artyom-zagorskiy.itch.io/isometric-medieval-pack)
despite its clean CC0 license: its flat vector geometry is farther from the
textured Warcraft 2 and UO reference read and would recreate the current
color-grade-without-style-change problem.

### Art and flora pipeline

Use `generate2dmap` to establish the composition proof and prop contract, then
use `generate2dsprite` for the missing final assets. The map base contains only
grass and road. Separate transparent props are:

- two one-by-one trees with different canopy silhouettes, because trees are
  tall, identity-bearing occluders and do not belong in a square prop pack;
- a 2x2 compact pack containing two bushes and two flower patches, generated
  on solid `#FF00FF`, processed and rejected on edge contact;
- the traveller walk replacement, generated as per-facing multi-row body grids
  and assembled deterministically into the existing four-direction atlas.

Every accepted generated asset keeps its manual prompt beside it. Flora is
authored in a render-side placement manifest or project-native resource with
`id`, cell, sub-cell offset, asset kind, blocker footprint, y-sort anchor,
shadow kind, `occlusionClass`, actor-safe area, and occupant policy. Trees use
`rear_shift_and_fade` where their canopy overlaps a walkable route. Bushes and
flowers are low, nonblocking dressing and leave the cell center clear. Render
maps semantic flora kinds to textures. No texture path or camera concern enters
`src/sim/`.

The minimum scene contains at least six trees in two clusters, six bushes, and
three flower-patch instances, including one unmistakable patch at ordinary
camera scale. Placement is hand-authored, not randomized. Trees that block
movement get explicit authored blocked cells in `TownLayout`; decorative low
flora does not.

### Walk quality, grounding, and evidence

Decision 005's per-facing generation, reference handoff, preprocessing, and
runtime-atlas separation stands. The colored-boots artifact remains a reject
gate, but no longer serves as gait evidence. I would generate six-frame source
cycles per facing in 2x3 grids, then choose or reduce frames only after motion
review. Six frames provide room for two contacts, two passing poses, and two
recoil poses without forcing the current contact-to-contact skip. If the
existing four-frame runtime contract is retained, the synthesis record must
name that downsample as a Decision 005-compatible implementation detail. If it
changes atlas topology, the decision record explicitly supersedes only frame
count and cell dimensions, not the generation-first or per-facing rules.

The acceptance artifact is a side-by-side GIF at identical displayed body
height and playback speed: longwalk on the left, a reference-game character
cycle derived from the supplied reference material on the right. A small
caption panel records stride in pixels relative to standing height, the two
contact frame numbers, head or pelvis vertical range, frame duration, source
game, and extraction provenance. It lives under
`docs/decisions/004-assets/` and is embedded in the decision record. If the
reference folder does not contain an extractable animated source, the team
must obtain a legally citable capture before claiming this requirement passed;
a static screenshot cannot be fabricated into a reference walk cycle.

Human acceptance reviews the GIF at shipping size for three named properties:

- the planted foot stops or slides no more than two displayed pixels during
  its contact interval;
- stride reaches roughly 25 to 35 percent of standing body height rather than
  shuffling under the torso;
- the pelvis has one restrained down-up beat per step, without whole-sprite
  hopping or a discontinuity at the loop seam.

The numeric overlay informs the judgment and never auto-passes art. A
headless image test still checks frame count, alpha, common feet origin, body
scale coefficient of variation, and atlas assembly. An automated Godot capture
runs the traveller along a straight road at shipping scale to expose foot slide
caused by movement speed versus frame timing.

Grounding has two parts. First, processed frames use a shared feet anchor and
the `Sprite2D` offset is recalculated so the lowest planted-foot pixel meets the
world origin in every contact frame. Second, replace the rounded player ellipse
with a short, soft, directional contact-shadow sprite attached below the body,
offset down-right by the same light vector as building and flora shadows. Its
scale may narrow slightly on passing frames, but its ground anchor does not bob.

### Silhouette shadows and scene depth

Remove `_create_shadow_polygon()` for buildings. Generate or preprocess one
shadow mask per building asset from its alpha silhouette: shear and vertically
compress the opaque mask along one fixed light vector, blur only the outer edge,
clip it to the ground plane, tint it uniformly, and place it beneath the
building. This is the classic pre-rendered-sprite technique that the CorsixTH
codebase is useful for studying, without copying proprietary Theme Hospital
assets. Store the shadow as a separate PNG so its silhouette and direction are
visually inspectable and so runtime code only positions it. A screenshot test
or metadata test asserts each building key has a matching shadow asset and a
shared direction vector. Flora uses the same direction and opacity family.

Keep the building and tall-prop origin at the footprint bottom edge so Godot
y-sort compares ground contact, not image center. Low ground dressing and all
cast shadows render below actors. Tall flora and buildings y-sort with the
traveller. This keeps the existing sim/render boundary intact.

### Road-weighted navigation

Extend `src/sim/nav_grid.gd` with a pure `movement_cost(layout, from, to)`.
Distance remains 1 or sqrt(2), multiplied by the destination terrain weight:
`PATH = 1.0`, `GRASS = 2.25`. The heuristic stays admissible by using the
minimum terrain multiplier, and every equal-cost tie still resolves by row-major
cell index. No sequential RNG or iteration-order accumulator is introduced.

This is preference, not a ban. A destination on grass remains reachable, and
the route may cross a short grass gap when the 2.25 penalty is still cheaper
than a long road detour. Acceptance tests include: same endpoints return the
same bytes across repeated calls; a road detour wins over a geometrically
shorter grass route within a bounded example; grass is used when the target
requires it; diagonal corner rules still hold; and a targeted cost-threshold
case documents exactly when leaving the road becomes cheaper. This touches the
protected `src/sim/nav_grid.gd` and its tests, so decision 004 needs the required
two-resident decision sign-off before integration.

### Independent right-click camera focus

Add `focus_view` mapped to right mouse in `project.godot`. The camera cannot
stay parented to the traveller because a child camera cannot focus independently
without compensating transforms. Move camera ownership into
`scenes/starter_town.tscn` and `src/render/town/starter_town.gd`; the player
controller continues to own zoom input but calls a small render-side camera
controller or signal API. Right-click captures `_world.get_global_mouse_position()`,
clamps it against camera limits at the current zoom, and eases the camera target
there. It does not clear, replace, or mutate the traveller's path. Left-click
continues to issue movement only. I resolve the requirement's ambiguity by
making focus persistent until another right-click; right-clicking the traveller
recenters on the traveller without restoring automatic follow. This makes the
feature independent rather than a momentary offset that snaps back next frame.

Tests inject simultaneous path and focus inputs, assert destination is
unchanged, assert the camera target is the resolved world location, check edge
clamping at every zoom level, and verify left and right mouse events do not
cross-trigger. `project.godot` is a protected-path touch forecast by the
assignment. Camera code remains entirely under `src/render/`.

### Evidence and explicit scope

The round PR carries before and after screenshots from the same save state,
camera target, zoom, viewport, and character location, plus a second after shot
showing flora occlusion and cast shadows. A small capture manifest records those
parameters so the comparison is repeatable. The decision record embeds the walk
comparison GIF and links every asset source and license. The retro must state
separately whether `generate2dmap` helped composition and layering, whether
`generate2dsprite` helped gait and flora, and what was regenerated or manually
corrected.

I include all seven findings. I exclude NPCs, interiors, day-night lighting,
new map regions, cursor-anchored zoom, a general camera-drag system, runtime
procedural placement, ecology behavior, persistence, and an engine change.
Expected protected paths are `src/sim/nav_grid.gd`, probably
`src/sim/town_layout.gd` if blocker flora is authored there, and
`project.godot`. The round also touches render scripts and scenes, art tooling,
tests, `CREDITS.md`, vendor assets, generated assets, and the decision record.

## 2. Risks

The largest risk is that rubberduck's 128x64 isometric material family cannot
be adapted to the current square ground without obvious projection seams. The
one-camera composition proof must happen before broad import. If it fails, keep
no pack merely because it is licensed; use the pack only as an art-direction
reference and generate a project-native ground and building family. That would
cost several image calls and remove the schedule advantage.

The second risk is scope coupling. New building dimensions can invalidate
footprints, shadows, doors, and y-sort anchors. I would initially preserve the
existing collision footprints and allow only sprites that plausibly fit them.
Changing authored footprints and flora blockers in the same branch as nav costs
raises protected-file merge risk.

The walk-cycle reference may not be legally or technically extractable from the
static files currently visible in the reference folder. This is a real
acceptance blocker, not permission to substitute a static pose. The first-hour
question is: which exact reference-game animation source is approved for the
side-by-side GIF, and may frames be extracted into the decision artifact?

Six generated frames can still have identity drift, foot skating, or excessive
bounce despite passing processor QC. The stride and contact bar may require
multiple generation calls per facing. Reducing six frames to four could
reintroduce skipping. Expanding runtime frame count could touch more tests and
supersede part of Decision 005.

Silhouette projection from a facade alpha mask is an approximation, especially
when roof overhangs imply height. A pure shear can look stretched rather than
cast. The asset proof must compare a pre-rendered shadow shipped with the CC0
pack against the deterministic mask transform. If the shipped clear-sun shadow
is coherent and separately extractable, prefer it and record its provenance.

Road weighting is sensitive to its multiplier. Too low produces invisible
preference; too high creates absurd detours. Tests can define the cost semantics
but playtesting must set 2.25. The camera focus interpretation may also surprise
players who expect automatic follow to resume, so the control should be judged
in the playtest rather than treated as settled interaction design.

Finally, dense flora can hide click targets, the traveller, or roads. Actor-safe
areas and fade policy add implementation work, and low-end integrated GPUs may
pay for many alpha sprites. The town is small enough to keep this bounded, but
the after screenshot cannot substitute for actual motion through tree clusters.

## 3. Division-of-labor claim

I am best suited to own the visual contract and generated-asset slice: the
one-camera pack proof, `generate2dmap` layered-scene plan, `generate2dsprite`
traveller and flora generation, deterministic postprocessing, GIF comparison,
shadow-mask assets, prompt provenance, and in-game visual QC. My harness has the
two mandated skills and built-in image generation, and this round explicitly
needs their first material trial. Keeping map composition, sprite generation,
and the acceptance capture together prevents a generated asset from passing in
isolation but failing at shipping scale.

I should not also own road A* or the camera refactor. Road costs are a compact,
headless protected-path slice suited to a resident focused on deterministic
tests. Camera reparenting plus InputMap is a separate render interaction slice
suited to a resident who can preserve the current zoom contract. A third
resident can own licensed-pack ingestion, `CREDITS.md`, and flora placement if
the visual proof fixes the exact asset list first. The orchestrator should keep
only one owner for `town_layout.gd`.

## 4. Rough estimate

This is roughly three parallel worker slices over two to four focused days,
then one integration and playtest day:

- visual and generated-art slice: 12 to 20 hours, including two to six image
  generation attempts per traveller facing, flora, processing, shadows, and
  evidence;
- pack ingestion and scene dressing: 6 to 10 hours after the composition proof;
- road navigation: 3 to 5 hours including deterministic fixtures;
- camera focus: 4 to 7 hours including camera ownership and zoom-limit tests;
- integrated capture, credits audit, full suite, and fixes: 4 to 8 hours.

The honest total is about 30 to 50 worker-hours, parallelizable to three or four
elapsed days. It grows past that if the pack proof fails, the approved reference
walk must be sourced outside the folder, more than three traveller generations
per facing fail gait review, or changing building art forces footprint and
layout reauthoring. If time compresses, reduce flora variety and building count,
not any of the seven acceptance outcomes: one building family, two trees, two
bushes, one flower asset, and one excellent traveller cycle still satisfy the
round better than a broad but incoherent asset swap.
