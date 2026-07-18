# Codex proposal: Two Rivers village production

## 1. APPROACH

### Scope and acceptance target

I resolve "full-on village" as a finite, authored Two Rivers proof with 14
building masses across a 40 by 32 cell play area: the Winespring Inn and green,
a forge, a stable, a small mill beside one river channel, eight varied homes,
two barns, kitchen gardens, orchards, fenced paddocks, two dirt-lane loops, a
footbridge, wells, wood piles, carts, laundry, flower beds, rocks, bushes, and a
dense tree boundary. It shows two visible watercourses converging near the
village, enough to earn the name without attempting the complete geography of
the novels. No interiors, inhabitants, interaction, seasons, simulation,
persistence, or land beyond the composed village envelope ships in this round.

The acceptance target is not merely "isometric and medieval." At the default
camera position, and at two other authored camera positions, the running export
must read like another crop of `docs/art/iso-five-asset-spike.png`: comparable
roof and timber detail, vegetation density, painterly ground variation, warm
fixed lighting, contact shadows, prop density, and no obvious repeated-tile
grid. The free camera may reveal the finite edge only at the maximum fit zoom.

### Art production: generated painterly districts, with a calibrated 3D fallback

I would not construct the village from dozens of independently generated
transparent sprites. The spike succeeds because buildings, lanes, vegetation,
shadows, and negative space were composed together. Independent sprites will
drift in perspective, palette, light, edge treatment, and scale, then look like
stickers even if each asset is attractive alone.

I propose a hybrid whose primary source is direct 2D image generation through
`tools/art/`, guided by the spike itself:

1. Freeze an art brief from the spike: 2:1 dimetric ground basis, camera and
   light direction, mossy blue-grey slate, warm timber and plaster, stone
   foundations, muted olive grass, dense edge vegetation, and an explicit ban
   on people, labels, UI, and cutaway interiors.
2. Author a low-detail top-down composition map and a matching isometric blockout
   that fixes every building footprint, road, river, bridge, clearing, and
   district overlap. This is the spatial control image, not shipped art.
3. Generate six overlapping 2048 px painterly district plates against the same
   whole-village blockout and accepted style crop: inn green, forge lane,
   riverside mill, west homes, east farms, and wooded perimeter. Each generation
   has a deterministic manifest containing prompt hash, source image hashes,
   generator/model identifier, dimensions, district bounds, and revision id.
4. Assemble the accepted plates offline into one master ground-and-background
   mosaic. Fixed masks and overlap seams are authored once, checked at 100
   percent, and recorded in the manifest. Generation is not runtime procedural
   content, and rejected variants never become runtime selection logic.
5. Generate or extract only the objects that must cross a moving occlusion line
   as separate transparent layers: 14 building/large-tree foreground crowns,
   bridge rails, and approximately 20 foreground clusters. These are generated
   with their local district crop as context, then alpha-cleaned and anchored to
   the same blockout. Small props, fences, flowers, shadows, and most trees stay
   baked into the plates, where they retain painterly integration.

This is a layered illustration, not a tile set. The renderer uses a small number
of large imported textures, so pan does not create seams or repeated texture
rhythms. Building foreground layers preserve the established stable contact-Y
plus placement-id depth contract, even though there is no actor this round.

Meshy is a fallback for geometry and camera consistency, not the primary final
pixel source. The 006 Blender renders are clean but risk looking like miniature
3D renders rather than the spike's painted composition. Initial Meshy spend is
zero credits. If the first two district trials cannot hold building perspective,
I would seek approval to spend credits on at most six meshes: one cottage kit,
inn, forge, mill, barn, and bridge. Blender would arrange and render those as
ControlNet-style composition guides, while direct 2D generation still supplies
the accepted final paint. The proposal does not assume the price or credit cost
per generation is stable.

### Composition, data, and rendering

`src/sim/town_layout.gd` remains authored, viewport-free data. I would replace
the starter layout with a named `build_two_rivers_village()` dataset containing
map bounds, semantic ground regions, building ids, cells, footprints, sprite
keys, and authored camera bookmarks. It does not contain texture paths, screen
coordinates, or render nodes. Roads and rivers may be represented semantically
for later use, but no runtime generation or NPC navigation is added.

`src/render/town/starter_town.gd` becomes a thin village scene assembler, or is
renamed to `two_rivers_village.gd` with the scene reference updated. It loads:

- one master background plate split into GPU-safe imported chunks if the target
  renderer's maximum texture size requires it;
- rear vegetation/building layers that never cross a camera-visible occlusion
  boundary;
- separately anchored foreground layers sorted by the existing footprint-aware
  contact rule;
- a subtle presentation grade only if that grade is included in acceptance
  capture and cannot crush the source painting.

The rendered plate is registered to the isometric projection using at least
four control landmarks. `src/render/iso/projection.gd` remains ground truth and
is not changed merely to fit art. Collision bodies and navigation do not need
to be instantiated in this no-character build. The data retains footprints so
they can return later without reverse-engineering the painting.

### No-PC free camera

I would make camera mode explicit rather than rely on a null player as an
accidental mode. `camera_rig_2d.gd` gets a `setup_free(layout, initial_position,
initial_zoom)` entry point that computes projected bounds, sets `State.FREE`,
clamps the authored village-center bookmark, and never enables
`center_on_player`. Existing `setup(player, layout)` and FOLLOW behavior remain
for future character play and existing tests.

The village scene gets an exported or constant `spawn_player := false` launch
mode. In that mode it does not load character state, instantiate
`scenes/player.tscn`, create the click marker, accept click-to-move, show the
name label, or build player collision. It calls `setup_free` directly. RMB drag
pan and cursor-preserving wheel zoom remain the only verbs. A test asserts the
running scene contains no `CharacterBody2D` and the camera starts in FREE.

### Export-safe assets

Runtime village art lives under `res://assets/village/two_rivers/`, outside the
`.gdignore` authoring tree. Source prompts, intermediate plates, Blender files,
raw generations, manifests, and assembly tooling remain under `tools/art/` and
are not runtime dependencies. Shipped PNGs are imported by Godot and referenced
as normal resources from `.tres`, `.tscn`, or `preload()` paths. Runtime code
does not call raw `Image.load`, `Image.load_from_file`, `FileAccess`, or a
globalized filesystem path for village art.

`export_presets.cfg` uses `all_resources` and needs no fragile include glob once
the imported resources are reachable. I would still add an export audit that:

1. performs a stock Windows export and a separate PCK export;
2. copies the PCK or EXE to an isolated temporary directory with no source tree;
3. starts it headlessly for a resource smoke check and verifies every declared
   runtime asset loads through `ResourceLoader` with nonzero dimensions;
4. starts the packaged build for acceptance capture and hashes the capture;
5. fails if the capture matches the placeholder/default-art fixture or if an
   expected asset manifest entry is absent from the pack.

The acceptance screenshot used for visual judgment must come from that isolated
packaged build, not an editor run. This makes silent fallback to defaults a red
test rather than a review surprise.

### Round-006 reuse and expected paths

Carry forward:

- the 006 scale contract and decision-010 math, especially
  `32*sqrt(6)` upright px/m and its validator;
- `blender_calibration.py` and `blender_pose_rig.py` for the blockout and any
  Meshy fallback guide renders;
- Meshy provenance and manifest patterns, generalized to generated district
  plates;
- the `nullfix` needed by the headless Blender path;
- the anonymized `acceptance-harness`, retargeted to compare three packaged
  village captures against the spike without identifying the candidate;
- `.mcp.json` unchanged.

Do not carry forward the assumption that the final village is a set of 3D
pre-rendered asset sprites. Calibration survives as a measurement and guide
pipeline. It does not dictate final pixels.

Expected protected paths are `src/sim/town_layout.gd` for authored village data
and `export_presets.cfg` for the isolated PCK/export audit if a second preset is
needed. `project.godot` is touched only if the village scene becomes the direct
launch scene or an input action must be disabled globally. Those changes need a
round-007 decision record beginning at 009, signed as required. Render scripts,
scenes, `assets/village/`, art tools, tests, and acceptance docs are unprotected.

### First buildable milestone

The first buildable milestone is an isolated packaged Windows export showing a
single 16 by 14 cell inn-green district at final pixel density: the inn, two
cottages, one lane junction, one large tree, fences, flowers, rocks, and at
least five small prop groups. It has no PC or NPC, starts centered in FREE,
supports RMB drag and wheel zoom, includes at least one separately sorted
foreground crown, and passes the asset-in-pack smoke test. A screenshot from
that packaged executable is judged beside the spike before production expands
to the other five districts. Failure at this milestone changes the art method,
not merely the quantity of generated assets.

## 2. RISKS

The largest risk is that direct 2D generation cannot preserve one coherent map
across six calls. Overlap seams, changing roof pitch, warped architecture, fake
doors, incoherent rivers, and light drift can all survive a casual glance. The
blockout and local-context workflow constrain this, but do not eliminate it.
If two inn-green attempts still look less controlled than the spike, this
approach needs the Blender/Meshy guide fallback or a single larger master
generation followed by inpainting, both of which increase time sharply.

The hybrid can also expose a seam between baked and separate elements. A
foreground crown extracted or regenerated independently may have a different
edge softness, shadow, or color grade. The rule must be that separate layers
come from the accepted district context whenever possible, not a generic asset
sheet. Occlusion should be proven at camera positions, not inferred from alpha.

Large plates may exceed texture limits or memory budgets on modest Windows
hardware. Chunking has to overlap safely and preserve filtering at boundaries.
The first milestone should measure imported VRAM, maximum texture dimensions,
load time, and pan-frame stability before the village canvas grows.

Export safety can still regress if a dynamic string load makes assets invisible
to the dependency scanner, or if the test accidentally runs beside the source
tree. A declared runtime asset manifest plus isolated-pack execution is more
work, but without both the executable can silently show fallback art. The audit
must inspect and run the artifact it just built.

The scale contract was written around individual 512 px cottages. District
plates need an equivalent landmark registration test so a beautiful painting
does not subtly violate `projection.gd`. Reusing the upright scale without
testing ground control points is insufficient.

The one-hour investigation is: build one constrained inn-green plate from a
simple isometric blockout, register four landmarks against `projection.gd`,
import it through `assets/village/`, export an isolated PCK, and capture it from
the engine at 1.0 zoom. This tests fidelity, projection, texture scale, and
packaging in the smallest honest slice.

The one question for Scott is: may the village be an authored interpretation
that evokes Two Rivers, or must it match named canonical geography beyond the
Winespring Inn, forge, mill, farms, two rivers, and village green? My estimate
assumes the former and treats the source text as inspiration, not a licensed
map specification.

## 3. DIVISION-OF-LABOR CLAIM

I am best suited to own the art-production proof and its acceptance boundary:
the blockout-to-district generation protocol, generated-art manifests, scale
registration, export-safe runtime asset manifest, isolated packaged capture,
and anonymized visual comparison. My prior context is the board-led generated
art pipeline and round-006 scale contract, and my harness is strongest where
pixel production meets deterministic validation.

I should not claim the whole village. A resident with the freshest ownership of
`camera_rig_2d.gd` is better suited to the explicit no-player FREE state and
input tests. Another resident can own the expanded `town_layout.gd` authored
dataset and render-layer placement once the art anchor contract is frozen. That
split prevents the person judging generated art from quietly changing camera
or layout geometry to flatter it.

## 4. ROUGH ESTIMATE

Order of magnitude: 8 to 12 focused worker-days for a credible first village,
plus Scott's visual review latency. Roughly two days cover the inn-green packaged
proof and go/no-go, three to five days cover generation and curation of the
remaining districts, and three to five days cover foreground separation,
layout/render integration, export audit, performance cleanup, tests, and final
captures.

The estimate grows to 3 to 5 worker-weeks if district coherence fails and six
calibrated Meshy/Blender structures must be modeled, posed, rendered, and
painted over; if "full Two Rivers" means canon-complete geography rather than
the scoped village proof; if Scott requires multiple seasonal or lighting
variants; or if 2K district plates cannot hold the spike's detail at gameplay
zoom and the runtime needs a streaming or texture-atlas architecture.
