# 010: Ground and lane treatment (village ground plane, spike-fidelity)

- **Status:** accepted
- **Date:** 2026-07-18
- **Assignment:** round-007 nested full-protocol sub-round on the GROUND/LANE
  render method. The first inn-green district reached spike fidelity on its
  objects but agy's multimodal QA (`docs/art/village/qa-agy-inn-green-001.md`)
  ruled the scene NOT-CONFUSABLE, with the DOMINANT tell being the ground: a
  hard checkerboard of flat-color `Polygon2D` diamond tiles plus solid tan
  diagonal path bands, vs the spike's continuous organic painterly grass and
  soft worn dirt trails. Per decision 009 item 9 ("method failure at the gate
  changes the METHOD, not the count"), this is a method fork, run as full
  protocol. Scope: `.pka/round007/ground-treatment/assignment.md`.
- **Orchestrator run:** round 007, ground sub-round, resolved 2026-07-18 on
  `round/007-village`.
- **Lane:** full protocol (design-level, genuine 3-way method fork; the root
  defect lives in `village_render.gd::_build_ground()` and the fix reads
  `src/sim/town_layout.gd`'s `ground` grid, a protected path).
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

Root defect: `village_render.gd::_build_ground()` draws one flat-color
`Polygon2D` diamond per cell (GROUND_COLORS grass/tan plus 3% jitter). That is
the checkerboard. The two existing ground assets `ground_grass.png` /
`ground_lane.png` are 128x64 alpha DIAMOND slices from the spike (manifest
`provenance: slice`). The task: replace per-cell flat diamonds with a
continuous, painterly, crisp-at-every-zoom ground that renders soft worn dirt
lanes derived from the sim's PATH cells, without breaking the sim/render
boundary or the free-cam zoom range (0.5x/1x/2x).

Two related defects from the same QA are sequenced AFTER this method lands and
are NOT decided here: agy defect #2 (halo cutouts on sliced props, a re-cut
fast-lane to codex) and agy defect #3 (missing contact shadows), which this
record folds into the chosen method as a dedicated contact-shadow layer.

This record covers the whole ground/lane approach and the one contested
question that went to a four-ballot: the primary ground-production method
(runtime shader-quad vs frozen authored plate).

## Proposals (phase 1, blind)

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/007-ground-proposal` | `9c841b57a69202277f38c0066467a89085ed7351` |
| codex-worker | `codex/007-ground-proposal` | `fec8b92fe51fdc00dfca25e0a9889d0310be2d88` |
| agy-worker | `agy/007-ground-proposal` | `4e51ff67033cbaf09272c5f7f34a67cb5b7dbb5c` |

- **claude (shader-painted cell-space quad):** ONE continuous shader-painted
  quad, UV set to CELL corners so the fragment shader samples paint in ground
  space (constant texel density, no per-frame screen->iso inversion); tiling
  rectangular grass/dirt swatches; a render-derived R8 lane mask built at load
  from the sim `ground` grid; a domain-warped noisy threshold so the lane edge
  wanders; a separate contact-shadow layer. Sim untouched. Names rectangular
  tileable swatches as the crux dependency on the slice/asset seat.
- **codex (frozen authored plate):** ONE frozen authored ~2048x1152 painterly
  PLATE per district. An offline lane-guide generator projects PATH cells with
  hash-based wander; generated-then-hand-composited paint; a semantic
  fingerprint that fails the build if the frozen paint drifts from the sim grid.
  One `Sprite2D` at runtime; render-side shadows; `town_layout.gd` untouched.
- **agy (splat-mapped shader plane):** a single splat-mapped ground plane,
  CanvasItem shader, per-cell blend-mask `ImageTexture` from the sim grid,
  domain-warp wander, tile uniforms, a `shadow_decal` layer. Flags in-shader
  screen->iso UV inversion over the diamond PNGs as its own brittle part; its
  strongest distinct contribution is a CPU-baked fixed-seed `FastNoiseLite`
  warp field instead of an in-shader float hash.

The phase-1 spread: claude and agy CONVERGED INDEPENDENTLY on the same method
family (a continuous shader plane, a render-derived warped blend mask from the
sim grid, and a separate contact-shadow layer). codex DISSENTED with the frozen
authored plate, which carries the same 2x-zoom-blur, per-district-reauthor, and
memory-scaling weaknesses that sank codex's own Option G in decision 009.

## Critique (phase 2, adversarial)

| Worker | Branch | Critique commit SHA |
| --- | --- | --- |
| claude-worker | `claude/007-ground-critique` | `39dbe3e33fedd1e51edbaabee37cd347a307a950` |
| codex-worker | `codex/007-ground-critique` | `58a45ddb275cac990164f939c5b5e167a524dc11` |
| agy-worker | `agy/007-ground-critique` | `bd9182c0365591a42a55f77903cfd7e4a3019bc1` |

A genuinely adversarial round. The load-bearing findings, and where the
critique round moved each worker:

- **Against the plate (claude, agy):** measured 2x-blur. The plate is authored
  at ~2048x1152 to fill a 1920x960 district (claude's measured screen bbox for
  the 16x14 inn-green district through the frozen `Iso.cell_to_screen`). At 2x
  the district projects to 3840x1920, so the plate resolves ~0.53 native texels
  per screen pixel: every source texel magnified ~1.9x, soft. This is the exact
  failure that sank codex's Option G, and codex's own risk section never once
  names 2x zoom. Fixing it by authoring at ~3840x1920 quadruples the pixels, so
  codex's already-flagged "~9 MiB does not scale" becomes ~28-30 MiB per
  district x 12-16 districts. The semantic fingerprint makes layout drift LOUD
  (a red build + a hand-repaint of a ~9-28 MiB plate) rather than cheap; a
  derived-every-load mask makes the same drift a non-event.
- **codex CONCEDED the method in its own critique.** codex's synthesis finding:
  "Claude supplies the stronger overall runtime method and Antigravity supplies
  the stronger deterministic-warp mechanism. Both are better than my plate on
  automatic layout coupling and multi-district reuse. My plate remains stronger
  only as a directly art-directed, non-repeating first-district fidelity
  fallback... The synthesis should therefore test a continuous cell-space mesh
  with rectangular periodic swatches and a CPU-baked warp field first, while
  keeping the plate only as the explicit fallback if periodic texture fidelity
  fails the zoom gate."
- **agy CONCEDED to claude's implementation over its own.** agy: claude's method
  "is structurally superior to my own proposal because it abandons the brittle
  screen-to-iso math over alpha diamonds in favor of clean affine UV mapping and
  rectangular swatches."
- **Within the shader camp, three corrections all three workers raised
  independently:**
  1. **Determinism (constitution):** in-shader GLSL float-hash value noise
     diverges across GPU vendors/drivers/precision (agy: "a lane edge might
     render underneath a tree trunk on one machine and slightly beside it on
     another"). The warp MUST be baked into a CPU-generated fixed-seed
     `FastNoiseLite` texture and sampled as a uniform, not hashed live. Raised
     by agy and codex; accepted by claude. This is agy's proposal's strongest
     contribution, grafted into claude's method.
  2. **Swatch source:** sampling the existing 128x64 alpha DIAMOND PNGs as
     repeating tiles is NON-VIABLE (transparent triangular corners tile in as a
     lattice of alpha gaps -- the checkerboard returns). Rectangular,
     proven-periodic swatches are a HARD PREREQUISITE, not the "if it artifacts"
     conditional agy filed it under. A crop from a non-tiling painting is not
     tileable just because opposite edges are offset-blended; it needs a
     mechanical acceptance test (>=8x8 repeat contact sheet inspected at
     0.5x/1x/2x, rejected if a repeat axis or recurring motif is visible).
  3. **UV = cell-corners, not screen->iso:** setting the quad's UV array to the
     projected diamond's CELL corners gives affine interpolation to fractional
     cell space directly, removing the per-frame screen->iso inversion agy
     itself flagged as its top risk. Adopt claude's coordinate choice.
- **codex's additional load-bearing requirements (all adopted):** a numeric
  texel-density budget derived from projected cell size and the 2x capture
  (repetition can replace blur with visible wallpaper; low-frequency tint
  changes luminance, not motifs); a protected semantic lane core (reserve the
  central ~0.5-cell of every PATH cell as unwarped solid dirt, cap the feathered
  edge displacement at <=0.2 cell) so the warp never advertises traversability
  the sim lacks; explicit `ResourceLoader.exists` + load assertions for the new
  `.gdshader` and `shadow_decal.png` from the isolated PCK; `textureGrad()` /
  `textureLod()` for the paint lookups so the warped-UV gradient does not break
  hardware mip selection (agy's specific fix); a mask rasterized at K>1
  texels/cell before the warp so the 16x14 source does not read as a fuzzy wide
  band; contact shadows treated as contact-darkening ellipses tight to anchors,
  NOT a general cast-shadow ordering solution.

## Decision

**Adopt the continuous cell-space shader-quad ground plane as the primary
method, synthesized from claude's and agy's proposals with codex's acceptance
requirements grafted in. The frozen authored plate is retained only as an
explicit named fallback, invoked solely if proven-periodic swatches cannot pass
the zoom gate.**

Concretely, the ground is:

1. **One continuous quad** (`Polygon2D` or `MeshInstance2D`) spanning the
   district's projected diamond, with its **UV array set to CELL corners** so
   the fragment shader receives fractional cell space by affine interpolation
   (no per-frame screen->iso inversion). A coordinate spike proves vertex
   ordering/triangulation and bounds coordinate error across the shared diagonal
   before this is called low-risk.
2. **Rectangular, proven-periodic grass and dirt swatches** (a HARD
   prerequisite), sized to a stated texel-density budget that stays crisp at 2x,
   accepted only after an >=8x8 tiled contact sheet is inspected at 0.5x/1x/2x
   and shows no visible repeat axis or recurring motif.
3. **A lane mask derived every load** from the sim `ground` grid (read-only;
   `town_layout.gd` stays texture-ignorant and viewport-free), rasterized at
   K>1 texels/cell, then domain-warped.
4. **A CPU-baked fixed-seed `FastNoiseLite` warp texture** (NOT in-shader float
   hash) sampled as a uniform, with a named seed + fixed layer offset + integer
   texel-coordinate contract, so the wander is byte-stable across GPUs. The warp
   is cosmetic (it does not make a placement decision), but it must not visibly
   move lane coverage across platforms.
5. **A protected semantic lane core:** the central ~0.5-cell of every PATH cell
   is unwarped solid dirt; only the feathered edge warps, capped at <=0.2 cell,
   so the art never advertises traversability the sim does not have.
6. **`textureGrad()`/`textureLod()`** for the paint lookups to keep mip
   selection correct under the warped UV gradient.
7. **A dedicated contact-shadow layer** above the ground and below the
   depth-sorted objects: soft darkening ellipses tight to anchors (agy defect
   #3), explicitly NOT a general cast-shadow solution, and not duplicating
   shadows already baked into source sprites.
8. **Grafts from codex's plate proposal, kept even though the plate loses:** the
   deterministic offline lane-guide idea may BAKE the CPU warp/mask texture the
   shader consumes (art-directed wander without freezing a raster); codex's
   **semantic fingerprint is adopted as a test guard** (a test that fails if the
   rendered lane coverage drifts from the sim PATH cells), since it is valuable
   regardless of method.
9. **Export proof:** the new `.gdshader` and `shadow_decal.png` get explicit
   `ResourceLoader.exists` + load assertions from the isolated packaged PCK,
   folded into the existing honest export gate. Runtime-derived mask/warp images
   need no static asset entry. No `Image.load`, no raw `FileAccess`, no
   `export_presets.cfg` glob edit.
10. **Fallback (explicit, bounded):** if step 2's swatches cannot pass the
    contact-sheet zoom gate and paid periodic generation cannot produce a
    genuinely periodic output, fall back to codex's higher-density authored
    base for the first district only, and re-open the method. Do NOT disguise a
    swatch failure with more shader noise.

**Acceptance gate (decision 009 item 9 carries):** the packaged ground is judged
at 0.5x/1x/2x against the spike. Failure due to wallpaper repetition, diagonal
phase changes, or a fuzzy straight band changes the swatch construction or mask
rasterization, not the count.

## Division of labor (by capability)

- **codex-worker (asset production seat):** produce the rectangular
  proven-periodic grass and dirt swatches (the hard prerequisite) with the
  >=8x8 contact-sheet acceptance test; author the CPU-baked fixed-seed
  `FastNoiseLite` warp/mask generator and the `shadow_decal` asset. Zero-credit
  tileable synthesis (edge-constrained tiling from a spike crop) is attempted
  first; any paid Meshy generation is surfaced to the orchestrator for
  supervised spend (balance 2952), never spent from the doer seat.
- **claude-worker (render integration seat):** wire the continuous cell-space
  shader-quad in `village_render.gd::_build_ground()` (UV=cell-corners, the
  `.gdshader` with `textureGrad`, the render-derived K>texels/cell mask from the
  sim `ground` grid, the domain warp consuming codex's CPU warp texture, the
  protected lane core, the contact-shadow layer); extend the honest export gate
  with the shader + shadow_decal load assertions; the coordinate spike.
- **agy-worker (multimodal QA seat):** re-run the multimodal QA of the new
  ground at 0.5x/1x/2x against the spike; specifically adjudicate the ground
  tell that drove this sub-round, and the determinism/mip concerns it raised.

## Protected paths touched

- `src/sim/town_layout.gd` -- READ ONLY by the render-derived mask; this record
  authorizes the render coupling that reads its `ground` grid. The synthesis
  keeps `town_layout.gd` texture-ignorant and viewport-free (no new fields); if
  implementation finds it must add a field, that is re-scoped under this record.
- `export_presets.cfg` -- authorized for export-safe inclusion of the new
  `.gdshader` / `shadow_decal.png` if a presets change proves necessary (the
  preset already uses `all_resources`; no glob edit is expected).

## Ballot (four-ballot on the contested synthesis question)

Contested question: **primary ground-production method** -- runtime shader-quad
(claude + agy) vs frozen authored plate (codex).

- **orchestrator:** shader-quad primary, plate as explicit fallback. The
  critique round did not merely split; it CONVERGED. Both peers measured the
  plate's 2x-blur as the same defect decision 009 already rejected, and codex --
  the sole dissenter -- conceded the method to fallback-only in its own critique
  document. Two workers converging independently while the third concedes is the
  strongest signal this protocol produces. I graft codex's real contributions
  (semantic fingerprint as a test guard, offline guide as a texture-bake source,
  the texel-density budget, the protected lane core) rather than discard them.
- **claude-worker:** _(pending ballot + signature)_
- **codex-worker:** _(pending ballot + signature; codex is a party -- its
  interest is the authored plate it proposed, which this synthesis demotes to
  fallback. Its own critique already conceded this.)_
- **agy-worker:** _(pending ballot + signature)_

Tally recorded at signing. A 3-1 or 4-0 result decides without the critic; a
2-2 split invokes the critic seat (`roles/critic.md`) as tiebreaker. The critic
was NOT invoked at synthesis time (per decision 004, the seat is
tiebreaker-only).

## Dissent

codex proposed the frozen authored plate and this synthesis demotes it to a
fallback. codex's own phase-2 critique conceded the ranking; its verbatim
residual position (the strongest case for the plate, recorded so a later reader
has the losing argument in its own words):

> "My plate remains stronger only as a directly art-directed, non-repeating
> first-district fidelity fallback, and its semantic fingerprint merely makes
> repaint debt loud. It does not remove that debt. The synthesis should
> therefore test a continuous cell-space mesh with rectangular periodic swatches
> and a CPU-baked warp field first, while keeping the plate only as the explicit
> fallback if periodic texture fidelity fails the zoom gate."

No worker raised a constitution-violation claim. agy raised a determinism
(constitution) concern about in-shader float-hash noise; the synthesis resolves
it by mandating the CPU-baked fixed-seed warp texture, and agy confirms that
resolution at signing.

## Sign-off lines

Signed-off-by: claude-worker <claude@sentania.net> PENDING
Signed-off-by: codex-worker <codex@sentania.net> PENDING
Signed-off-by: agy-worker <agy@sentania.net> PENDING
