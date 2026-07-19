# Annotated Spike Spec: the operational definition of "built on the ground"

**Status: DRAFT for Scott's approval (Checkpoint A).** Nothing is implemented
against this yet. Scott's approval or correction of this document gates all
implementation of the composition-rules milestone. This is the synthesized
output of a full-protocol round (three blind measured decompositions of the
spike, then adversarial critique), refereed by the orchestrator.

Target measured: `docs/art/iso-five-asset-spike.png` (1280x720 RGBA; painted
scene occupies ~x[0..1153] y[36..612], the rest is #4d4d4d padding). This is the
art bar (Scott: "the art style for the game is subject-2/town.png"; this spike is
that target). We measured IT, not our build.

## Why this document exists

Scott's verdict: *"the buildings still look stitched on and floating... the
spike's buildings look BUILT ON the ground. The sunflowers look fine but they
should be in a field, not in the road."* The diagnosis he and dalinar recorded:
the tell is NOT vegetation at the seams, it is that **our ground does not respond
to the buildings.** In the spike the terrain changes around every structure
(soil darkens at the walls, grass wears thin, planting wraps the base) so the
building looks like it caused those changes. Our pipeline finishes the ground
independently and drops the building on top, decorating the joint. This spec
converts "built on the ground" from an eye-judgment into measured numbers an
implementer can target and a QA seat can verify, expressed so they generalize to
a district nobody hand-authored (Scott's 1k x 1k / 10k x 10k question).

## Provenance (auditable, local doer branches)

- Blind proposals: claude `418572c1`, codex `2ea3f981`, agy `cfc22d46`.
- Adversarial critiques: claude `7a737ff4`, codex `82358ce1`, agy `f1f29f9f`.

Where the three reads converged independently, the finding is stated as settled.
Where they diverged, the contested ruling and the losing dissent (verbatim) are
recorded in "Contested points" below.

---

## The thesis (one paragraph, then numbers)

"Built on the ground" is not a decorative joint. It is a **stack of three ground
responses** that all key off the same foundation line, plus a **zone grammar**
that decides what may grow where. The three reads agreed on the stack:

1. a thin **contact-occlusion seam** hugging the stone (dark toe),
2. an **altered-ground apron** outside it (dark/worn soil, foundation planting),
3. a **wear/recovery transition** back to open ground.

Our build has none of the three, because it grades the ground before the
building exists. The rest of Part A measures each band; Part B is the grammar;
Part C is how each number scales.

---

## Part A. Measured terrain-response decomposition (converged)

### Reference ground (the baseline our build wrongly assumes is uniform)

Open sunlit grass is **not one value**. Independently remeasured by all three
reads (Rec.601 and Rec.709 agree to ~1L here):

| Sample | region | L | note |
|---|---|---|---|
| Meadow, top-center | x[570..630] y[60..100] | ~102 | brightest open grass |
| Open grass, right | x[1050..1110] y[160..200] | ~98 | |
| Open grass, lower-left | x[20..90] y[480..540] | ~94 | |
| Grass, mid-yard | x[150..240] y[400..470] | ~72 | worn/shaded, near buildings |
| Lane core, junction | x[330..430] y[440..500] | ~136 | warm tan dirt |
| Deep occlusion recess (smithy bay) | ~x[1000] y[470] | ~38 | shadow floor |

**Open grass spans ~72-102 L (a ~30L spread) before any building response.** This
single fact is load-bearing for Part C: a ground response expressed as a *fixed
luminance subtraction* lands differently on every patch and cannot be right. The
darkening must be expressed **relative to the local ground it sits on.**

### The three-band stack, measured (large rear cottage, camera-left/SW base)

Perpendicular transect out from the stone base (averaged over x[360..430]):

| distance from base | L | reading |
|---|---|---|
| 0-5 px (at stone) | ~53 -> 63 | **contact seam / dark toe** |
| 6 px | ~112 | into apron |
| 14 px | ~121 | apron (still ~15L below open) |
| 24 px | ~123 | apron tail |
| ~40 px | ~169 | reaches open lane |

- **Contact seam:** a **~3-6px** dark toe, luminance dropping to **~0.35-0.4x of
  the adjacent open ground** (L~53 vs lane ~169; L~35-52 vs grass ~94). This is a
  shadow (near-neutral RGB), not merely darker dirt.
- **Altered-ground apron:** the next **~10-30px**, still measurably below open
  ground, carrying dark/worn soil and (on planted sides) foundation vegetation.
- **Wear/recovery transition:** recovery to open ground completes over roughly
  **~40px total** from the base. The recovery is **concave and coverage-based**
  (dark clumps thin to isolated blades, painterly islands, not a smooth Gaussian
  ramp), **not linear**.

The full composite response at this base is **~40px**, and it must not be
compressed into a single ~15px band (a phase-1 error all three later agreed on).

### Orientation / adjacency dependence (converged, strong)

The response is **not a symmetric ring.** Its width and depth depend on which way
the base faces and what it is next to:

- **Sunlit / lane-facing / door side:** compressed and clean. Narrow toe, light
  wear, quickly yields to the lane. Little or no tall planting. (Small foreground
  cottage: contact seam 2-4px, band 9-24px, near-zero foundation flora on the
  lane-facing faces.)
- **Shaded / garden / rear side:** wide, dark, and planted. The dark response
  stays below ~55L for **>50px** out; dense foundation flowers, shrubs, rock, and
  vine occupy 65-90% of the first ~25px; vegetation climbs 18-60px up the wall.
  (Smithy rear-right and large-cottage rear: widest responses in the scene.)

Measured width difference between the two sides of a single building is **>3x**.
A single symmetric foundation decal reproduces the exact "stitched-on ring" look
this spec exists to kill. The rule must be **adjacency-driven** (what the base
faces: lane, door, garden, other structure), which is measurable, rather than
assuming a lighting model the flat image cannot prove.

### Doors, service edges, and props (converged)

- **Doors interrupt the apron with a clean notch:** timber steps + stone pads
  bridge into a worn, compacted landing (light soil, not dark garden soil)
  ~18-28px deep; foundation planting stops at the entrance. Nothing grows across
  the threshold.
- **Service edges (smithy work bay):** stay predominantly bare 28-45px out;
  props (anvil, grindstone, logs) may occupy them, rooted flora does not. Each
  prop foot has its own small contact toe (~2-5px) and worn halo.

### Tree / wild corner and lanes (converged)

- **Wild corner (tree):** the same stack around a living anchor. Dark root core
  (~40L), a dense multi-species understory apron (bushes, berries, tall grass,
  mossy rocks) ~45-80px deep, thinning lobed edges into grass. This is the
  maximum-vegetation case and the visual definition of "wild": mixed species,
  mixed height, rock litter, no bare ground at the trunk.
- **Lanes:** ~95-145px wide at the junction, narrowing to ~65-90px on approaches
  (intentionally non-uniform). Warm compacted tan (~136L center). Edges wander
  ~10-24px and feather into grass over ~18-35px by coverage. **The travel core
  carries no rooted flora; feathered edges may carry sparse grass tufts and
  embedded stones/pads.** Flowers, shrubs, and crops never appear on the lane.
  (This is the rule our build breaks by putting sunflowers in the road.)

---

## Part B. Zone grammar (converged taxonomy + precedence)

The spike obeys a zone grammar. Assignment is **precedence-based, not radial
distance** (a pure "within Npx of a wall" ring puts planting across doorways and
leaves clean grass against long walls). Precedence, highest first:

1. **Footprint / contact response** — the wall-local three-band stack, applied
   everywhere a structure meets ground, adjacency-selected.
2. **Lane + access exclusion** — the lane travel core and door/service approaches
   exclude rooted flora before any scatter is evaluated.
3. **Service / foundation-apron treatment** — wall-local modifier: garden side
   planted, door side clean notch, lane side compressed seam.
4. **Occupied yard** — the broad low-density tended ground between lane,
   buildings, and wild edge: low grass, sparse tiny flora away from routes,
   fences, signs, people.
5. **Authored field / wild content** — the outer flora vocabulary.

The zones, with what belongs and what does not:

| Zone | Visual signature | Belongs | Does NOT belong |
|---|---|---|---|
| **Lane** | warm tan ~136L core, ~65-145px wide, feathered edge | travel, door approaches, wear, sparse edge grass, loose stones, cast shadows | flowers, shrubs, crops, any rooted scatter in the core |
| **Yard** | low quiet grass ~72-95L, open circulation | low grass, isolated rocks, sparse tiny flowers away from routes, fences, signs | dense crops, continuous shrub belts, planting across doors |
| **Foundation response** (wall-local modifier, not a top-level zone) | the 3-band stack; adjacency-selected; up to ~90% flora on garden/rear sides, ~0 at doors | dark soil, contact shadow, moss, foundation flowers, embedded rock; service subtype adds paving/props | a uniform symmetric ring; flora across entrances; clean grass touching a wall |
| **Field / cultivated bed** | see the note below — under-evidenced in the spike | crops/sunflowers in coherent tended clumps | placement in lanes or scattered through travel space |
| **Wild** | dark core ~40L, mixed species, rock overlap, canopy shade | trees, shrubs, mixed flowers, rocks, leaf litter, irregular dense scatter | clean travel promise, uniform rows, broad bare soil |

**"Foundation response" is a wall-local treatment, not a fifth place on the map.**
It wraps every footprint and rides on top of whatever zone the building sits in.
Splitting it out from "yard" is what lets the rule say *plant the garden side,
clean-notch the door, compress the lane face* on the same building. All three
reads reached this once the apron was measured per-face.

---

## Part C. Scale-awareness contract (converged, with one contested tag ruled)

The reads converged on a **hybrid** scale contract. This is what lets the spec
survive a district nobody hand-authored, and answers Scott's 1k/10k question at
the spec level (the full bake-unit/memory scale contract is decision-018 work,
deferred):

- **Contact seam and painterly grain: SCREEN-SPACE with an absolute minimum.**
  The dark toe (~3-6px here) and texture-island grain (~2-8px) are legibility
  devices. They are pinned in screen pixels with a **1-2px floor after
  projection**, so they do not vanish when a foundation course goes sub-pixel at
  a 10k zoom. (This is the fix for the "ratio-to-course-height collapses to zero"
  failure that all three flagged.)
- **Apron / wear transition / yard extent: GROUND-SPACE, RELATIVE to a LOCAL
  functional feature** — the base-course (plinth) height, door width, lane width,
  or agent/tile width, **whichever is local to that segment. NOT the whole
  building footprint, and NOT the building's vertical/visible height.** A
  wall-local response must not deepen just because the wall is attached to a
  longer or taller building. (A 10-story tower does not get a 70px swamp.)
- **Darkening: a RATIO to LOCAL ground luminance, with a floor and contrast
  clamp** — the contact toe is ~0.35-0.4x of the adjacent open ground, expressed
  multiplicatively so it reads correctly whether the local grass is 72L or 102L,
  clamped so it never crushes already-shaded ground to black and always keeps a
  minimum visible separation. (Unanimous after critique.)
- **Flora density / scatter counts: RELATIVE to zone area.** Coverage fractions
  (e.g. "sparse edge grass," "dense garden apron") are directions, to be enforced
  by a coverage-mask method, not ratified as exact pass/fail percentages against
  a flat painterly image.
- **Lane width: an authored ground-space quantity** tied to agent/tile width
  (~2.3-3.5 character widths at the junction), declared as an external contract,
  NOT presented as measured from the image (there is no character in the spike to
  measure it against; the ~95-145px is the observed screen result at this scale).

---

## Contested points (recorded per protocol)

**Scale tags: absolute vs relative (ruled 3-1 against a blanket-absolute model).**
agy's phase-1 spec tagged the contact band, luminance delta, lane gradient, and
yard radius all ABSOLUTE. Both other reads independently refuted this by
measurement: open grass baseline varies ~30L across the scene (so a fixed luma
delta lands inconsistently and can crush ground to black), and the SW-vs-SE
response width differs >3x on one building (so a single fixed radius cannot
express the measured orientation asymmetry). agy itself conceded the luma half in
critique ("Claude is correct here... an absolute delta... would push dark ground
values into pure black... a ratio properly attenuates"). The ruling is the hybrid
contract in Part C: seam screen-space-with-minimum, apron/yard relative to a
local feature, darkening as a clamped ratio.

agy's losing objection, recorded verbatim (its remaining defense of ABSOLUTE
apron/yard extents):

> "Codex argues that the apron and wear transitions should be RELATIVE to wall
> height (e.g. 4-7 percent of wall height). This is physically absurd and
> generalizes terribly. A 10-story tower would not generate a 70px grass apron.
> Soil moisture and root spread do not scale with building height; they are
> world-space phenomena that scale with grid size/footprint (which translates to
> fixed ABSOLUTE px at a given zoom level). Claude's ABSOLUTE fixed px approach is
> correct for ground phenomena."

The valid kernel of that objection (that vertical/visible *building height* is a
bad denominator) is **adopted** in Part C: the apron keys to a *local ground-plane
feature*, never to building height. What is rejected is the leap to blanket
absolute pixels, because "10k x 10k" is a world extent, not a render scale, and
fixed source-image pixels have no stable meaning across zoom, export resolution,
or footprint. This did not reach a 2-2 split, so the critic seat was not invoked.

**Field zone under-evidenced (converged, and it needs Scott).** See below.

---

## Open questions FOR SCOTT (Checkpoint A)

1. **The spike does not actually contain a field.** All three reads independently
   found no broad crop field in the target: only one small, partly-occluded
   yellow-flower bed at the smithy edge (~45-85px). Your instruction is that
   "sunflowers should be in a field, not in the road." We can honor that, but the
   **field zone's geometry (bed size, row/clump spacing, edge softness) is not
   measurable from this spike** and would be **authored**, not derived. Options:
   (a) you point us at another reference frame from `subject-2/town.png` (or
   elsewhere) that shows a field, or (b) you approve us authoring a
   cultivated-bed/field zone to taste, or (c) sunflowers become foundation/garden
   planting (which the spike *does* evidence) rather than a field crop. Which?
2. **Does this operational definition match your eye?** Part A is what we will
   engineer the terrain-response bake to hit and what QA will verify. If anything
   here reads as the wrong target (e.g. you want a stronger or subtler darkening
   than ~0.35-0.4x, or a different lane cleanliness rule), correct it now, while
   it is a document, before it is a bake.
3. **Adjacency vs lighting.** We chose to drive the per-face response off
   *adjacency* (lane/door/garden/other-structure) because the flat image proves
   adjacency but cannot prove a light direction. If you know the world has a fixed
   sun direction we should honor, say so and we will add a lighting term.

## What this spec deliberately does NOT decide (deferred to decision 018)

The zone-data model (baked per-cell tag in the authored map vs derived at
render-time from distance fields; this touches sim/render separation), the
terrain-response bake design, the full scale contract (bake units, memory, file
size, bake time per 1k/10k chunk), and the generalization-test district. Those
are the architecture-decision round that runs only after you approve this spec,
and Checkpoint B (one grounded-building demo tile) sits between that decision and
full-district generation.
