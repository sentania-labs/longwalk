# claude-worker proposal, round 006: Two Rivers production path

Blind phase-1 proposal. I have not read the codex or agy proposals, branches,
worktrees, or inboxes. Evidence I did read: the spike
(`docs/art/iso-five-asset-spike.png`), the current running-build screenshots in
`/home/scott/claude/vault/tmp/longwalk-inputs` (the 2026-07-17 141215 capture and
the earlier `seriously-this-is-terrible.png`), the whole `tools/art/` pipeline,
`src/render/`, decision 008, and the round-005 result notes.

## The reframe that drives my recommendation

The four defects all descend from one root, and the assignment names it in
defect 3: "whole-scene-quality generation collapses when bridged into
game-usable tiles/sprites." Read the spike next to the running build and this is
literally what you see. The spike is a single coherent painterly render: one
light vector, one scale, one palette, half-timbered walls, moss on slate,
believable tree. The running build (141215) is that same intent after it has
been decomposed into independently-generated per-asset sprites and flat-color
ground diamonds: the buildings survive as passable stylized objects, but the
coherence is gone. Ground is flat Polygon2D color (`starter_town.gd:124`,
`GROUND_COLORS`), not the `grass_ground_tile.png` / `ground_path_tile.png` that
already exist unused. The character is small against the cottages (scale). The
walk is 4 proxy rows hand-mirrored in 2D (`player-walk-option-c-result.md`). And
`Instance base is null.` prints top-left.

So the contested question is really: **what production method produces
per-asset game sprites that keep the whole-scene coherence the spike proves is
achievable?** Framed that way, three sub-problems must be solved together, and
only one path solves them by construction rather than by fighting the generator:

- **Consistency across assets** (one light, one scale, one camera angle). The
  spike gets this free because it is one render. Per-asset text-to-image does
  not, and no amount of prompt discipline fully fixes it (round 005's board-led
  pipeline is the honest best 2D attempt and the 141215 build is its output).
- **Animation** (a real gait, 8 facings). 2D makes this a hand-authoring problem
  that `option-c` shows we do adequately-at-best.
- **Scale + grounded shadows.** In 2D these are authored conventions we must
  police; in a shared 3D space they are physical facts.

## 1. Approach: Path 3 (3D-authored, pre-rendered to painterly 2D sprites), with one honest amendment

I recommend **Path 3**, the Diablo/StarCraft/AoE2/DKC method, over both the
pure-sprite status quo (Path 1) and live 3D (Path 2). But I am recommending a
**defensible variant**, not the vanilla pitch, because the vanilla pitch has a
hole I want to close before we spend a round on it:

> **The spike's painterly quality is a property of the 2D image generator, not
> of any 3D render.** A raw Meshy mesh rendered through an orthographic camera
> gives you correct geometry, lighting, scale, silhouette, and 8 facings for
> free, but it will read as "clean 3D render," not as the painterly Two Rivers
> spike. 3D alone does not close the *fidelity* half of defect 3. It closes the
> *structural* half (consistency, animation, scale, shadows) completely.

So my variant is **3D-as-scaffold, 2D-as-skin**: use the 3D pipeline to nail
structure, then recover painterly fidelity with a generative repaint pass over
the render (image-to-image / structural conditioning), keyed to the spike as
style reference. If our generator can condition on an input image, this gets us
the spike vibe *and* the structural correctness, with cross-asset consistency
guaranteed by the shared 3D source. If it cannot (a real unknown, see Risks),
we fall back to hand/generated texturing of the meshes plus a lighter post
pass, which is still a large step up in consistency from 141215. The pilot is
designed to answer exactly that question cheaply.

Why not Path 1: the fidelity gap in pure 2D is not a tuning problem, it is
structural. Every per-asset generation is an independent sample; consistency is
fighting the tool, and animation/scale/shadows stay hard-authored 2D problems
we have already shown produce merely-acceptable results. Path 1 is the lowest
disruption and I expect it to keep producing 141215-class output.

Why not Path 2 (live 3D): it discards the iso render spine we just built and
signed off (decision 008), reopens nothing about projection but re-plumbs the
entire draw path, and gambles the painterly vibe permanently (every frame is a
raw render, no place to put a paint pass). Path 3 keeps the spine: the game
still draws 2D sprites through `src/render/iso/projection.gd`; only the *asset
source* changes. Most of codex's ingest/process/atlas pipeline survives because
the output is still sprite sheets against the same anchor contract
(`projection.gd:212 building_contact_cell`, the frozen manifest anchor).

### Pipeline stages (how one asset travels)

1. **Author in 3D (Meshy).** Text-to-3D or image-to-3D (seed from a spike crop)
   for the cottage; a rigged humanoid for the player. Output mesh + PBR
   textures.
2. **Clean + stage (Blender, headless/scripted).** Minimal retopo/decimate,
   fix normals, place on a metric ground plane. One shared Blender scene =
   one shared light rig + one world scale. This is where consistency is born.
3. **Rig + animate (player only).** Rig the humanoid, apply a walk cycle
   (standard gait or light mocap). The gait is 3D-correct, not 2D-guessed.
4. **Render from the locked iso camera.** An **orthographic** camera locked to
   the exact angle `projection.gd` assumes: 2:1 dimetric, azimuth 45 degrees,
   elevation `atan(0.5) ~= 26.57 degrees`. Render the cottage once; render the
   player 8 facings x 6 frames by rotating the rig 45 degrees per facing (facing
   ids already frozen, `projection.gd:143-170`). The ortho camera means no
   perspective divergence between a back-row and front-row asset: scale is
   pixel-identical, which is defect 2 solved by construction.
5. **Repaint pass (the variant).** Run each render through the image generator
   conditioned on the render (structure) + the spike (style), to recover
   painterly surface. Falls back to no-op if conditioning is unavailable.
6. **Ingest + process (codex's existing pipeline, mostly unchanged).**
   `ingest_generated_sheet.py` validates the sheet against a manifest;
   `process_assets.py` normalizes to the declared contact anchor and derives the
   deterministic offline shadow masks (decision 008 Q-C). The 3D render can also
   *emit* a true contact/cast shadow, but I would keep the deterministic
   offline-derived mask as the shipped shadow so shadows stay a pure function of
   the accepted silhouette (honors 008 Q-C; the 3D shadow is a cross-check).
7. **Draw in-engine.** Unchanged: `starter_town.gd` places the sprite at its
   projected contact anchor and z-sorts on projected contact Y. No render-spine
   change required for buildings/player.

### Data flow, concretely

`Meshy mesh -> Blender staged scene (shared light+scale) -> ortho iso render (PNG
sheet + provenance) -> [repaint] -> tools/art/ingest_generated_sheet.py ->
tools/art/process_assets.py -> tools/art/out/iso/processed/*.png -> loaded by
starter_town.gd / player_controller_2d.gd through the existing anchor contract`.

New tooling is one Blender render script (`tools/art/render_iso_from_3d.py`,
Blender Python) plus a source-asset directory (`tools/art/3d/` for meshes/rigs,
which are inputs like prompts are, committed). Everything downstream of the
render is the pipeline we already have.

### The four defects under this path

1. **Walk cycle.** Rig + 3D walk animation rendered to an 8-facing x 6-frame
   atlas. The gait is correct in 3D and merely projected, so contact timing,
   stride opposition, and weight transfer are real, not hand-mirrored.
   Acceptance = a walk GIF captured from the RUNNING build
   (`tools/art/capture_player_walk.gd`, already the acceptance harness) reading
   as a real gait beside the reference. This is Path 3's single biggest win and
   the cleanest kill of any defect.
2. **Scale.** Everything is authored in one metric 3D space (document the unit:
   person ~1.8 m, cottage door ~2.0 m, eave ~2.4 m) and rendered through one
   ortho camera, so the on-screen pixel ratio is a physical consequence, not a
   convention. I will additionally document the ratio as
   `docs/art/scale-contract.md` and enforce it with a manifest
   `pixels_per_meter` field plus a capture assertion, so a mis-scaled asset
   fails the gate instead of shipping.
3. **Fidelity gap.** Attacked from both sides: the *structural* half (the actual
   cause of 141215's collapse: drifting light/scale/palette across independent
   samples) is eliminated because every asset is a render of the same staged
   scene; the *painterly* half is recovered by the repaint pass (or texturing
   fallback). Seamless textured ground is the render-side sibling of this defect
   and is mine regardless of path (below).
4. **Instance base is null.** Independent, fast-lane, render-side, mine. Likely a
   `load()` returning null for an asset path that does not exist
   (`player_controller_2d.gd:116` loads `player_walk_%s.png` by variant;
   `starter_town.gd:162` loads by `BUILDING_TEXTURE_PATHS[sprite_key]` and will
   hard-fault on any unlisted key). Plan: reproduce headless, bisect the null
   base to the exact `load`/`instantiate`, add a guarded fallback + a loud
   asset-missing assertion in a test so it cannot silently regress. This does
   not need to wait for the pilot and should ship early.

### The pilot (small, concrete, pre-authorized)

**Scope: exactly one building + the player.** One cottage (the spike's anchor
asset) and the player through the *entire* Path 3 pipeline: Meshy -> Blender
staged scene -> rig + walk (player) -> ortho iso render -> repaint attempt ->
existing ingest/process -> dropped into the real `starter_town.gd` at the frozen
anchor. Nothing else re-authored; the other buildings stay as-is so the pilot is
strictly additive and cheap to revert.

**Acceptance = a three-way side-by-side, rendered IN-ENGINE, judged by Scott:**

| Column | Source |
| --- | --- |
| A. Target | `docs/art/iso-five-asset-spike.png` (the bar) |
| B. Path 3 | the pilot cottage + player, in the running build |
| C. Status quo | the current 141215 2D build |

Plus the walk GIF from column B's running build. Judged on: painterly vibe vs A
(the make-or-break question), scale correctness (person-to-cottage ratio), gait
realism, lighting consistency across the two assets, and 8-facing coherence. The
pilot's explicit purpose is to answer "does 3D-scaffold + 2D-skin hit the spike
vibe, or does it read as generic 3D?" *before* we commit the town. If column B
does not beat column C on vibe, Path 3 is not worth the town-scale cost and we
say so in the retro.

**Meshy is escalation-class.** It is a new external dependency (account, API
key, cost, ToS/license on generated meshes). Adopting it for the town needs a
new decision record **009** signed by both agents and escalated to Scott. The
*pilot* is pre-authorized per directive 1515; the *town commit* is not, and the
pilot result is exactly the evidence decision 009 should turn on.

## 2. Risks (including the ones that make my own choice look worse)

- **Vibe drift, the big one (against my own pick).** If the generator cannot do
  image-conditioned repaint, raw ortho renders may read as "generic indie 3D",
  the exact failure 1515 warns about. Mitigation: the pilot tests this directly
  and cheaply; the texturing fallback still improves consistency even if
  painterly-recovery fails. I would rather learn this on one cottage than a town.
- **Meshy quality + cleanup cost.** AI meshes are notoriously messy (bad topo,
  baked lighting in textures, non-manifold geometry, no clean rig). Cleanup +
  rigging one humanoid can eat the whole pilot budget. Unknown until we run it.
- **Repaint breaks 8-facing consistency.** If we repaint each facing frame
  independently, the generator may hallucinate per-frame detail and reintroduce
  the flicker/consistency problem we were escaping. Mitigation: repaint may need
  to be a single tiled sheet pass, or low-strength, or applied to texture not
  render. Another thing the pilot must probe.
- **Determinism.** The constitution's determinism rule targets *placement/
  generation-order*, not art authoring, so a 3D render pipeline does not violate
  it. But `process_assets.py`'s shadow derivation must stay the deterministic
  offline mask (008 Q-C); I would not let the 3D render's own shadow become the
  shipped shadow. Low risk, flagged so it is not forgotten.
- **Pure-sprite might actually be "good enough" cheaper.** Honest counter to
  myself: if Scott's bar is "clearly better than 141215" rather than "pixel-match
  the spike," Path 1 with better ground + a real 8-facing 2D walk might clear it
  without a new dependency. The pilot's column C exists precisely to keep that
  comparison honest.
- **My one hour + one question.** Question to Scott: *"Is the bar 'reads as the
  spike's painterly world' or 'clearly beats the current build'? "* The hour: run
  one Meshy cottage generation and one image-to-image repaint test against a
  spike crop, to settle whether structural conditioning is available in our
  toolchain, which is the load-bearing unknown for the whole variant.

## 3. Division-of-labor claim

- **I (claude) should own the render-spine + in-engine integration side.** I
  built the iso projection spine and `starter_town.gd` render rework in round 005
  (sign-offs `claude-005-render-spine`, `claude-005-facing-fix`,
  `claude-005-capture-fix`). The pilot's "rendered in-engine, three-way
  side-by-side" harness is squarely mine: wiring the pilot assets into
  `starter_town.gd`, the comparison capture, and the acceptance montage. **Also
  mine, and path-independent:** defect 4 (`Instance base is null`, render-side
  bug) and **seamless textured ground** (defect 3's render half: replace the flat
  `GROUND_COLORS` diamonds with UV-textured diamonds or a TileMap using the
  already-existing ground tiles, so the field stops being flat color). These two
  should ship early regardless of which art path wins, and I can start them
  immediately.
- **The `render_iso_from_3d.py` Blender render tool** (staged scene, locked ortho
  camera, 8-facing rig rotation, sheet emission) is a headless Python/scripting
  task that fits my harness well; I am comfortable owning it. It is the seam
  between the 3D authoring and the existing pipeline.
- **Codex should own the generation-forge side.** Codex carries the sprite-forge
  mandate and owns `ingest_generated_sheet.py` / `process_assets.py` /
  `build_player_walk.py` and the manifests. In Path 3 that mandate extends
  naturally to: Meshy prompting/import, mesh texturing, and the repaint pass
  (image-to-image is generation work, codex's `image_gen`/generation skills).
  Keeping generation with codex means the ingest manifest and the generator stay
  co-located, as in round 005.
- **Honest note:** the *3D authoring + rigging* stage (Meshy mesh cleanup,
  Blender humanoid rig) is genuinely new capability for all three of us and is
  the riskiest slice. It is not obviously any resident's strength. I would not
  claim it blind; I would scope it inside the pilot and let whoever proves they
  can drive a headless Blender rig take it, with me covering the render-emit
  script and codex covering texture/repaint.
- **Agy** owns the camera (round 004/005). The camera consumes
  `projected_bounds()` unchanged this round; no new camera work is implied by the
  art path, so this round is light for that slice unless the town layout grows.

## 4. Rough estimate

Order of magnitude, honest units.

- **Defect 4 (null base) + seamless textured ground:** small, ~1 slice, shippable
  this round independent of the pilot outcome. Half a round of one doer.
- **Path 3 pilot (one cottage + player, three-way side-by-side in-engine):**
  ~1 full round of coordinated doer work, dominated by the unknowns (Meshy
  cleanup + rig, and whether repaint conditioning exists). Could overrun into a
  second round if mesh cleanup/rigging is as bad as AI-mesh reputation suggests;
  I would timebox the rig attempt and fall back to a static-pose player render
  for the first side-by-side rather than let rigging block the vibe verdict.
- **Full-town commit if the pilot passes:** multiple rounds (re-author every
  building + flora + finalize the 8-facing walk + ground), gated behind decision
  record 009 and Scott's go. Explicitly out of scope for a single round; the ARC
  is multi-round by the assignment's own framing.

Net: I am recommending we spend one cheap pilot round to convert the biggest
open question (does 3D-scaffold + 2D-skin hit the Two Rivers vibe) from opinion
into an in-engine side-by-side, while I close the two path-independent defects
now so the round ships value even if the pilot verdict is "not yet."
