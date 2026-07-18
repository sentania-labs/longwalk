# Ground / lane treatment proposal (round 007 sub-round) -- claude-worker

Blind phase-1 proposal. GROUND + LANES to spike fidelity for the inn-green
district. Author: claude-worker (render-integration seat, decision 009 DoL).

## TL;DR

Stop drawing the ground as N per-cell diamonds. Draw it as ONE continuous
shader-painted quad covering the whole district: a tiling painterly grass swatch
and a tiling dirt swatch, sampled in ground (cell) space, blended by a soft,
noise-warped LANE MASK that is derived render-side from the sim's existing
GRASS/PATH grid. Add a dedicated soft contact-shadow layer between ground and
objects. The sim does not change at all. No plate is baked; nothing floral is
frozen; the paint stays crisp at 2x zoom because it is textures sampled by a
shader, not a fixed-resolution image.

## 1. Approach

### The core move: continuous shader quad, not per-cell diamonds

Today `_build_ground()` adds `width*height` flat `Polygon2D` diamonds. That IS
the checkerboard and the straight diamond-band lane. I replace the entire ground
layer with a SINGLE node: a `Polygon2D` (or `MeshInstance2D`) whose polygon is
the four projected outer grid corners
(`Iso.cell_to_screen(0,0 / w,0 / w,h / 0,h)`), carrying a `ShaderMaterial`
running `res://src/render/town/ground.gdshader`.

I set the polygon's `uv` array to the CELL coordinates of those same four corners
(`(0,0),(w,0),(w,h),(0,h)`). Godot interpolates UV affinely across the quad, so
in the fragment shader `UV` is exactly fractional cell space `(cx, cy)` for every
pixel, at any zoom, with zero per-cell nodes. This is the whole trick that
divorces the paint from the diamond grid.

Files:
- `src/render/town/village_render.gd` -- rewrite `_build_ground()` (one node,
  builds the mask texture, wires uniforms). Add `_build_shadows()`. Remove
  `GROUND_COLORS`.
- `src/render/town/ground.gdshader` -- NEW. The paint.
- `src/render/town/contact_shadow.gdshader` -- NEW (or a shared radial PNG; see
  shadows). The grounding.
- `assets/village/ground_grass.png`, `assets/village/ground_lane.png` -- REPLACED
  by codex with RECTANGULAR tileable painterly swatches (see DoL). The current
  files are alpha DIAMONDS (and the lane one has a baked PC shadow sliced into
  it), useless for continuous sampling.
- `assets/village/manifest.json` -- the two ground records change `native_px` to
  the new rectangular size; `kind: ground` unchanged.
- `src/sim/town_layout.gd` -- UNTOUCHED. (Stated as a feature, not an omission.)

### The shader (what makes grass continuous and lanes wander)

Uniforms: `grass_tex`, `dirt_tex` (tiling swatches, `repeat_enabled`),
`lane_mask` (R8, built at runtime from the sim grid, `filter_linear`),
`grid_size = vec2(w,h)`, `grass_uv_scale`, `dirt_uv_scale`.

Fragment, all in cell space so pan/zoom never change the paint:
1. Sample `grass = texture(grass_tex, UV * grass_uv_scale)`. Because UV is
   ground-plane cell space, the grass lies flat on the iso plane (correct
   projection), tiles with constant texel density, and has NO diamond seam and NO
   checkerboard: it is one field.
2. Break the tiling repeat with a low-frequency value-noise tint (two octaves,
   large wavelength) multiplied into grass luminance, so the swatch does not read
   as a stamped pattern.
3. Lane coverage: `m = texture(lane_mask, UV / grid_size).r`. This alone is a
   blurry straight band. Make it organic: DOMAIN-WARP the sample point by
   value-noise before the lookup (`UV + warp_amp * noise2(UV*warp_freq)`), then
   threshold with a NOISY threshold. The warp bends the grass/dirt boundary so it
   wanders and frays instead of running as a straight edge; the noisy threshold
   dithers the edge so the transition dissolves rather than snapping. Trail
   centerline still tracks the PATH cells; only the edge wanders, by less than the
   soft-edge width.
4. `dirt = texture(dirt_tex, UV * dirt_uv_scale)` with its own tint noise.
5. `COLOR = mix(grass_tinted, dirt_tinted, smoothstep(edge0, edge1, warped_m))`.

All noise is value noise = a pure hash of `floor(cell)` plus fixed offsets (the
`macro_map.gd` layered-offset pattern, ported to GLSL). No `randi`/`randf`, no
time, no screen-derived input, no order dependence. It is a pure function of cell
position, so it satisfies the determinism rule by construction and is byte-stable
across runs. It touches nothing the sim reads; nav cost and the determinism tests
are unaffected.

### How the ground data crosses the sim/render boundary

Exactly one derived value crosses, and it crosses the SAME direction as today
(render reads sim, never writes back):

- Sim owns SEMANTICS: `town_layout.ground[y][x] in {GRASS, PATH}` + `TERRAIN_COST`.
  Unchanged. Still viewport-free and texture-ignorant.
- Render DERIVES the mask: `_build_ground()` allocates an `Image` of
  `FORMAT_R8`, writes `PATH -> 255, GRASS -> 0` per cell, wraps it in an
  `ImageTexture`, hands it to the shader. Optionally rasterize at K texels/cell
  (K=4) for a less blocky base before the warp; still a pure read of the grid.

This is the identical category as the current code reading `_layout.ground[y][x]`
to choose a color. No screen coordinate, texture path, wander offset, or blend
mask ever enters `src/sim/`. The lane's organic wander lives entirely in the
shader; the sim keeps its clean coarse PATH grid. I am deliberately NOT pushing
sub-tile centerlines or wander offsets into the sim: the wander is cosmetic, is
smaller than the soft edge, and must not perturb nav (nav stays on authored PATH
cells). Resolved ambiguity, named.

### How objects get their contact shadow (agy defect #3)

New `ShadowLayer` Node2D inserted between `GroundLayer` and `World`.
`_build_shadows()` iterates the non-crown placements and, for each, draws a soft
dark ELLIPSE at the object's `contact_screen`, width ~0.6x the footprint's
projected width, height ~half that (iso-foreshortened), via a small radial-falloff
shader (or one shared `soft_shadow.png` tinted low-alpha and scaled). Drawn above
the ground, below every object, so the object sits IN the grass instead of
floating. Size/opacity keyed off `footprint` and manifest `native_px`, so a tree
casts a bigger pool than a flower. Deterministic, no new sim data, no per-sprite
asset work. This directly answers "objects float, no soft contact shadows."

(I argue render-side shadows over codex baking a shadow into each sprite: a
separate layer sorts under neighbours correctly, keeps one light direction
consistent across all objects, and lets a future day/night pass rotate shadows
without re-cutting art. Baked-in shadows freeze the direction and double-darken
where sprites overlap.)

### Why this, not the obvious alternatives

- NOT a single authored/generated painterly PLATE. A plate blurs when the free-cam
  zooms to 2x (fixed native px vs ~9200 screen px, the exact anti-plate critique
  that sank codex's G in decision 009), must be re-authored per district (bad at
  12-16 structures), and bakes the lane geometry into pixels so it silently
  desyncs if the sim ever moves a PATH cell. My shader keeps textures at native
  res (crisp at any zoom) and DERIVES the lane from the sim every load, so they
  can never disagree.
- NOT autotiled blend/transition diamonds (Wang/blob tiles). That keeps the
  diamond grid as the organizing structure, needs a combinatorial set of
  transition variants, and the lane can still only wander in whole-cell steps. The
  continuous quad has no grid structure to leak, and the lane edge is continuous.
- Method, not tuning: this changes HOW ground pixels are produced (one continuous
  shaded field vs. flat per-cell fills), which is what decision 009 item 9 demands
  when the gate fails on method.

### Export-gate honesty

`grass_tex`/`dirt_tex` are source PNGs under `res://assets/village/`, loaded via
`ResourceLoader` exactly as objects are now; the isolated-`.pck` gate's
"resolves with nonzero dims, not placeholder" assertion covers them unchanged.
`.gdshader` is a normal packed resource. The runtime mask `ImageTexture` is
DERIVED from sim data in memory (like building `Polygon2D` diamonds today), not
an `Image.load` of game art, so the static ban and the packaged gate both stay
green. No `export_presets.cfg` glob edit (`all_resources` already ships them);
`project.godot` untouched unless a layer node needs registering.

## 2. Risks

- **Seamless swatch is the crux.** Slicing a truly tileable grass/dirt swatch from
  a non-tiling painting (the spike) is the hard bit; a visible repeat would just
  trade the checkerboard for a wallpaper. Mitigations: large swatch + offset-blend
  the crop + low-freq tint noise, and if one swatch still repeats, cross-fade TWO
  grass swatches by noise. Fallback if slicing cannot yield a clean tile: one paid
  Meshy `image_to_image` per swatch (grass, dirt) conditioned on a spike grass/
  trail crop (nano-banana ~3 credits each, cost-confirmed, balance-checked, no
  PENDING task, never pass `save_to`). Small spend, gated.
- **The one hour I would spend first:** crop a grass swatch from the spike, tile
  it 4x4 in an image viewer, and eyeball the seam and the repeat. That single test
  decides one-swatch-plus-tint vs. two-swatch-blend vs. paid regen, and it is the
  highest-variance unknown in the whole method.
- **Mask base resolution.** 1 texel/cell (16x14) under bilinear is blocky; the
  domain warp hides some of it but I should rasterize at K texels/cell. Cheap;
  flagged as a tuning knob, not a redesign.
- **Determinism discipline in GLSL.** Easy to reach for a screen-space or
  `TIME`-based noise and break both determinism and stability (the trail would
  swim as the camera pans). Mitigation is a hard rule I will hold: all noise is a
  pure hash of floored CELL coords, sampled in cell space only. I will state this
  in the shader header the way `macro_map.gd` does.
- **Sim/render leakage temptation.** Under pressure to make lanes wander more, the
  temptation is to add centerlines/wander offsets to `town_layout.gd`. That would
  violate item 4. I am committing to keep 100% of wander in the shader; if a
  reviewer thinks the wander needs sim-side data, that is a design escalation, not
  a quiet edit.
- **Shader UV trick correctness.** The `uv = cell corners` affine interpolation
  must actually deliver cell space across the diamond (it is a linear map, so it
  should); I verify with a debug shader that paints `UV.x` as a gradient and
  checks it matches `screen_to_cell`. Low risk, explicitly checked.
- **Memory / scaling (this method's WIN, stated honestly as the compare):** two
  ~512px swatches + two shaders, reused for every district; the mask scales with
  the grid (tiny). Versus a plate's 2048px-per-district. So scaling to the full
  12-16-structure village is trivial here and expensive for a plate. The residual
  risk is only that a much larger district makes tiling repetition more noticeable
  over a bigger visible area, which the two-swatch blend covers.
- **Contact-shadow uniformity.** A single ellipse per object is an approximation;
  irregular silhouettes (the tree crown) may want a shaped shadow. Acceptable for
  this gate; note as a later refinement, not a blocker.

## 3. Division-of-labor claim

I am best suited to own the RENDER METHOD: the `ground.gdshader`, the
`_build_ground()` rewrite + the R8 mask derivation from the sim grid, the
`_build_shadows()` layer, the ground-quad + UV=cell setup, and holding the
sim/render boundary and export gate green. That is precisely my decision-009 seat
(render integration, projection/depth/camera contracts, Godot scene + export +
test plumbing), and this proposal is 80% render plumbing and 20% asset.

The ASSET piece is better owned by codex: producing the two rectangular tileable
painterly swatches (grass, dirt) sliced from the spike (its slice/`process_assets`
seat), plus the manifest `native_px` update and any paid `image_to_image`
fallback if the swatch will not tile. codex owns the pixels; I own how they are
composited and lit on the ground plane. Keeping the fidelity-of-the-swatch seat
separate from the composite-method seat is the same separation decision 009 drew.

agy owns the QA: multimodal compare of the new ground against the spike at
0.5x/1x/2x from the isolated packaged capture, same as its standing seat. Its
verdict on whether the wander + tint read as "organically worn" is the gate.

## 4. Rough estimate

Order of magnitude: SMALL. One focused render dispatch for the shader +
`_build_ground()` rewrite + shadow layer + boundary/tests (roughly a day of agent
work), plus a short codex asset dispatch for the two swatches, plus an agy QA
pass. The gate at 0.5x/1x/2x is unchanged plumbing.

What blows it up: (a) no sliceable seamless grass/dirt from the spike, forcing the
paid regen path and a second judge-then-spend gate (adds a cost-confirm round, not
a redesign); (b) the domain-warp + noisy-threshold needing several tuning
iterations with agy to actually read as "worn trail" rather than "fuzzy band"
(iteration cost, bounded); (c) discovering the affine-UV trick fights Godot's
`Polygon2D` UV handling and needing a `MeshInstance2D`/`QuadMesh` instead (a node
swap, half a day). None of these change the method; they change the effort inside
it.
