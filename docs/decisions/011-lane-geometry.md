# 011: Lane geometry (organic worn-earth lanes, spike-fidelity)

- **Status:** accepted
- **Date:** 2026-07-18
- **Assignment:** round-007 nested full-protocol sub-round on LANE GEOMETRY.
  Decision 010 settled the ground-TEXTURE method (continuous shader-quad + district
  painterly plates + baked domain warp + protected lane core + contact shadows) and
  fixed the checkerboard tell, but agy's multimodal QA pass 2
  (`docs/art/village/qa-agy-ground-002.md`, verdict NOT-CONFUSABLE) found a NEW
  dominant tell: the lanes are straight, uniform-width diagonal/orthogonal bands
  meeting at a crisp X, vs the spike's organically meandering variable-width
  worn-earth clearings; plus a hard dirt/grass transition (#2) and uniform dirt
  density (#3). Per decision 009 item 9 ("method failure at the gate changes the
  METHOD"), the LANE-GEOMETRY method is the open question. Scope:
  `.pka/round007/lane-geometry/assignment.md`.
- **Orchestrator run:** round 007, lane-geometry sub-round, resolved 2026-07-18 on
  `round/007-village` (branched from round head `da05e69`).
- **Lane:** full protocol (design-level 3-way fork on lane representation, and it
  edits the protected `src/sim/town_layout.gd`).
- **Workers dispatched:** claude-worker, codex-worker, agy-worker

## Context

The straight X is authored directly into the sim: `build_inn_green_district()`
fills `lane_y = 8` across the full width and `lane_x = 8` down the full height of a
16x14 district (`src/sim/town_layout.gd`), and the render derives a binary
PATH/GRASS mask from that grid at K texels/cell, warped in-shader with a capped
`GROUND_WARP_AMP = 0.18` cell. The dominant tell is topological, not edge-level: the
spike has ONE worn earthen clearing that pools in front of the buildings and fades
into grass (not a road, no full-width through-line), while the village has two
uniform bands running edge to edge and crossing at a crisp center. Render-side warp
can move a boundary but cannot change where dirt exists vs does not, cannot taper a
full-width band to nothing mid-district, and cannot turn crossing-roads topology
into a worn clearing, because the topology lives in the mask and the mask comes from
the sim grid. So tell #1 is unreachable from a pure render change; the shape must be
fixed where it is authored: the sim.

The three tells to close: #1 path macro-shape (dominant), #2 hard transition, #3
uniform dirt density. Decision 010's architecture must NOT regress; the plates are
reused; no new paid art.

## Proposals (phase 1, blind)

Every dispatched worker proposed independently, none having seen another's.

| Worker | Branch | Proposal commit SHA |
| --- | --- | --- |
| claude-worker | `claude/007-lane-geometry` | `260eb22ee45224eb37968f4d4d014c02de940721` |
| codex-worker | `codex/007-lane-geometry` | `23042c5cbfc4dbad09848e9eb09a12e07b7070b1` |
| agy-worker | `agy/007-lane-geometry` | `f7d1905003b0030370074b49d99d2552bf78f9e8` |

**All three independently chose Fork B**: represent lanes as sim-side semantic
centerline polylines with a per-vertex width profile (a texture-free value object
added to `town_layout.gd`), derive the nav PATH cells from those centerlines, and
render an organic signed-distance-field lane mask with feathered falloff and a
deterministic density field. All three explicitly rejected Fork A (a 16x14 binary
grid quantizes a meander into stair-steps that render-warp must then rescue,
reintroducing the micro-noise-on-a-straight-edge tell one grid step coarser) and
Fork C (render-side macro-warp preserves the crossing-roads topology and, at the
amplitude needed to disguise the cross, advertises traversability the sim lacks and
blows decision 010's warp cap). This is the strongest signal this protocol
produces: three genuinely blind reads converging on the same architecture.

The proposals differed WITHIN fork B, and that is what the critique round tested.

## Critique (phase 2, adversarial)

Critique artifacts: claude `f5f0b46eb6daf6b4eb23e96489e1d89933eccc46`, codex
`ac2982a23b178845c17f809969b36f586c2c98c3`, agy
`29966187331b20cca2ba3586cc116edc877be7dd`. The round was genuinely adversarial and
it CONVERGED; the substance, by question:

- **Nav PATH source-of-truth.** Consensus: PATH must be DERIVED from the
  centerlines as a cached representation, never a second authored source (else
  render reads `lanes` while `terrain_cost_at()` reads `ground` and they drift with
  no mechanical reconciliation). codex sharpened it: derivation by conservative
  **cell-square intersection**, not "cell center inside half-width" (too weak for a
  narrow/diagonal core, leaves disconnected raster gaps). codex also caught that a
  PATH-connectivity test is insufficient: `NavGrid` leaves grass walkable (cost
  2.25 vs PATH 1.0 via `terrain_cost_at()`), so A* can chord-cut a grass shortcut
  across a bend; the tests must assert actual `find_path()` route preference / cost
  bounds, not just connected PATH cells.
- **The active-path junction test hard-fails on day one.**
  `test/active_path/test_village_render.gd` requires a cell that is PATH on a FULL
  ROW AND FULL COLUMN crossing (verified at lines 68-86). Any meander breaks it.
  Replacing it (entrances, building approaches, junction connectivity, route
  preference, no-PATH-under-blocking-footprints) is a REQUIRED part of the slice,
  not a follow-up.
- **SDF bake performance / method.** agy's headline stutter risk and its GPU
  Jump-Flooding (JFA) fallback are dissolved by the repo's OWN precedent: noise
  fields are baked OFFLINE into committed PNGs (`tools/art/bake_ground_warp.gd` ->
  `assets/village/ground_warp.png`, fixed seed 7007+4109, byte-fingerprint
  contract). The SDF is a pure function of authored geometry; bake it the same way,
  offline, to a committed asset; runtime cost is a texture read and there is nothing
  to stutter. Even as a runtime bake, 16 texels/cell over 16x14 is ~57k texels
  against ~8-15 segments (well under a second). **agy conceded JFA is
  over-engineering for one district.**
- **Where macro-warp composes.** Consensus (codex's precise statement, claude
  concedes it matches and beats agy's, agy concedes it to codex): compose the warp
  displacement IN the CPU bake, as a pure function of fixed seed + integer texel +
  authored geometry, with the **protected core channel warp-EXEMPT** and only the
  cosmetic shoulder warped. agy's original shader-side UV meander is withdrawn by
  agy (it moves the rendered lane off the unwarped nav grid = the sim/render
  semantic-desync / advertises-traversability defect, and is deterministic-but-
  dishonest; both peers named it a design defect, NOT a constitution violation).
- **Mask channel layout.** Consensus: separate single-purpose channels over codex's
  RGB pack. **codex conceded** its RGB pack is only less fragile as an in-memory
  runtime data texture; through Godot's normal texture import an RGB8 carrying
  numeric core/coverage/density risks sRGB transfer + VRAM compression corrupting
  all three contracts at once (including the R core decision 010 protects). Keep an
  unwarped-core + base-coverage channel in an in-memory data texture; a separate
  low-frequency density image only if independent tuning justifies the extra
  sampler; pin lossless/non-sRGB import; fingerprint the pre-upload `Image` bytes,
  which is what the shader actually samples' provenance.
- **Junction blending.** agy's polynomial smooth-minimum (smin) is a real graft
  (both peers union via `max`/nearest = a sharp interior corner where worn earth
  should pool), BOUNDED: apply smin ONLY to the cosmetic outer shoulder, never to
  the protected core (smin expands the union beyond each lane's authored width);
  cap the blend radius below the minimum authored lane separation (else it bridges
  intentionally-separate lanes); prefer an authored width swell / clearing at the
  junction as the simpler first tool.
- **Meander authoring.** Consensus (agy concedes to claude): the meander topology is
  HAND-AUTHORED as literal waypoint constants in the polyline, with NO seed (the map
  is authored and frozen per the 2026-07-15 pivot); seeded baked noise supplies WEAR
  only (shoulder perturbation ~0.15-0.35 cell, width variation, density), never the
  centerline. A noise-driven meander re-runs the exact rejected tell.
- **Factual correction:** agy's proposal argued against fork A on "a 128x128 grid";
  the district is 16x14. Noted so its scaled-up cost/stutter framing is not carried
  into the synthesis.

## Decision (phase 3, synthesis)

**Fork B, as converged.** There was no contested synthesis question: the critique
round resolved every within-B difference by concession, not by a split. The
critic seat (tiebreaker-only, decision 004) is therefore NOT invoked. The approach:

1. **Sim contract (`src/sim/town_layout.gd`, PROTECTED).** Add a texture-free,
   viewport-free value object `LanePath { points: PackedVector2Array (fractional
   cell coords); half_widths: PackedFloat32Array }` and `lanes: Array[LanePath]` on
   `TownLayout`. `build_inn_green_district()` stops filling a straight X and instead
   authors 2-3 meandering lanes as literal hand-authored waypoint + width constants
   (no RNG, no seed), curving past building fronts and swelling into a clearing at
   the meeting area, narrowing between. `ground`'s PATH cells become a DERIVED,
   cached rasterization of the lanes (conservative cell-square intersection); `lanes`
   is the single source of truth for lane geometry. The file stays headless-runnable
   and carries only semantic geometry (no texture path, camera, or UI reference).
2. **Offline deterministic bake (`tools/art/`, new bake tool + committed PNG(s)).**
   Bake the lane mask OFFLINE (same pattern as `bake_ground_warp.gd`), fixed seed +
   named layer offsets, to a committed asset with a byte-fingerprint contract doc.
   The bake computes, per texel, the min distance to the authored polyline segments,
   interpolates the local half-width, composes the deterministic shoulder warp
   (core channel EXEMPT), applies bounded smin ONLY on the shoulder at the junction,
   and produces an unwarped-core + coverage representation plus a low-frequency
   density field. Start at 16 texels/cell; measure before increasing. Fingerprint
   the pre-upload `Image`.
3. **Render/shader (`src/render/town/village_render.gd`, `ground.gdshader`).**
   Replace `_build_lane_mask()`'s binary raster with consumption of the baked mask.
   The shader keeps the decision-010 structure (continuous cell-space quad, grass +
   dirt district plates, explicit-gradient plate sampling, contact shadows) and
   changes only the coverage source and falloff: a two-stop feathered transition
   (solid dirt -> mottled dirt -> grass) for tell #2, and density-channel modulation
   of dirt opacity OUTSIDE the protected core for tell #3. The protected core is read
   from the UNWARPED channel and forced solid, matching the sim's PATH footprint.
4. **Tests.** Replace the full-row/full-column junction assertion with: district
   entrances reachable, building approaches connected, junction connectivity, actual
   A* `find_path()` route preference / cost bounds (not just connected PATH), no PATH
   under blocking footprints, layout repeatability, and the mask byte-fingerprint +
   width-varies + core-never-reduced-by-density assertions.

Grafts folded in: agy's bounded smin (from the losing details of every proposal's
`max` union); codex's precise warp-in-CPU-bake determinism statement; codex's
cell-square PATH derivation and A* route-preference test insight. Reused as-is: the
two painterly plates, the shader quad, contact shadows, the offline-bake pattern.

## Division of labor

Capability split, matching what all three proposals independently recommended
(claude=render/mask integration, codex=deterministic bake + contract, agy=QA). The
interface between the two build slices is the committed baked mask PNG + the `lanes`
accessor; the cross sign-off (each doer reviews the other's slice) is the control
against the contract/mask drift both peers warned about.

| Piece | Assigned to | Why this harness |
| --- | --- | --- |
| Sim `LanePath` contract + hand-authored waypoints v1 + derived-PATH (cell-square) + offline SDF/density/smin bake tool + committed mask PNG + fingerprint contract + sim/determinism/nav-route tests | codex-worker | Self-claimed and unanimously recommended for the deterministic bake + data contract; codex authored `bake_ground_warp.gd`, and this piece rewards exact contracts, boundary reasoning, and byte fingerprints, separable from subjective capture tuning. |
| Render consumption in `village_render.gd` + `ground.gdshader` feathered dual-threshold + density modulation + protected-core-from-unwarped-channel + active-path render-test replacement + capture regeneration + capture-driven waypoint tuning | claude-worker | Authored the entire decision-010 render (shader quad, R8 mask bake, warp uniform, core protection, contact shadows, export gate, UV spike) and holds that context; the shape must be tuned against captures, which is the render loop. Waypoint tuning edits only the authored-constant block in `town_layout.gd`, cross-signed by codex. |
| Multimodal QA pass 3: re-judge shaped lanes at 0.5x/1x/2x against the spike (macro-shape closed? transition soft? density patchy?) | agy-worker | The QA seat; agy's pass-2 diagnosed these exact tells and judges genuinely multimodally. |

## Dissent

No contested synthesis question survived the critique round; every within-B
difference was conceded by its own author. Recorded verbatim, the residual/losing
positions in their authors' own words:

**agy, withdrawing its shader-side UV meander and macro-warp (conceding to both
peers):**

> "I concede that calculating a full GPU Jump Flooding Algorithm for a single 16x14
> district is over-engineering; a CPU distance check is perfectly adequate for this
> scoped size, as both peers noted. I also concede to Claude that the meander should
> be hand-authored rather than noise-driven (respecting the pivot), and I concede to
> Codex that any macro-warp must be composed in the CPU mask, not the shader, to
> guarantee the visual core stays inside the sim's `PATH` footprint."

**codex, conceding its RGB channel pack to the separate-channel layout:**

> "I concede that separation is easier to inspect and tune than my proposed RGB
> packing. My packing is only less fragile if it is an in-memory runtime
> `ImageTexture`; if passed through normal texture import, putting numeric core,
> coverage, and density data in RGB risks sRGB conversion and compression corrupting
> all three contracts at once."

**Constitution-violation claims raised in critique, and their disposition (neither
is a losing objection, so neither escalates to Scott):** agy claimed claude's
original in-shader `warp_tex` perturbation violates the sim/render separation rule
by moving rendered dirt off the unwarped nav grid. The synthesis ACCEPTS the
underlying concern and resolves it exactly as agy asked: the warp is composed in the
CPU bake with a warp-exempt core channel, so the rendered core stays inside the sim
PATH footprint. claude framed agy's shader-side UV meander as risking decision
010's core-honesty rule; agy withdrew that approach. Both concerns are honored by
the synthesis rather than overruled, so there is no losing constitution-violation
objection to escalate. (This mirrors decision 010 resolving agy's determinism
concern via the mandated baked warp.)

## Protected paths touched

src/sim/

## Sign-offs

Every worker named in `Workers dispatched` signs. This record authorizes the
`src/sim/town_layout.gd` edit (the `LanePath` contract, hand-authored waypoints, and
derived-PATH rasterization).

    Signed-off-by: claude-worker <claude@sentania.net> PENDING
    Signed-off-by: codex-worker <codex@sentania.net> PENDING
    Signed-off-by: agy-worker <agy@sentania.net> PENDING
