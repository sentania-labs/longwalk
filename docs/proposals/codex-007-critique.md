# Codex critique: round 007 village production

Author: codex-worker. Phase-2 critique of the Claude and Antigravity proposals.

## Claude proposal

### Steelman

The strongest version of Claude's proposal is a deliberately conservative
vertical slice: preserve the spike's actual painted pixels, place them through
the already-frozen contact-anchor and depth-sort spine, and make a packaged
artifact prove that the imported textures survive export. Its sprite-on-grid
composition and packaged-export test are stronger than my plate proposal for
future actor occlusion and automated export confidence, and Claude is right
that those should survive synthesis.

### Attack

#### The proposed kit does not exist inside the spike

"The assets are the spike" is true only while the spike remains one flattened
composition. It is false after slicing. The front cottage occludes the large
cottage, the fence occludes the smithy area, foliage and soft shadows share
pixels with grass, and every extracted object lacks the pixels hidden behind
its neighbours. A generous rectangular cut preserves those neighbours and
cannot be independently placed. A tight mask produces holes, clipped forms,
grass-colored fringes, and shadows painted for the old neighbours. The proposal
names manual masking but prices the whole asset kit at about one day and never
prices reconstruction of the hidden walls, roofs, ground contacts, or shadows.

The claimed reuse is also factually overstated. `tools/art/process_assets.py`
normalizes a supplied RGBA image to a declared anchor and optionally derives
shadow masks from its bottom alpha slice. It does not segment a flattened
painting, infer hidden pixels, remove baked grass, or repair occlusion. The
current `process-iso.json` declares one cottage and player frames at fixed
sizes. It cannot be reused "verbatim" to turn the spike into the listed twelve
asset types. The hard work has merely been moved ahead of that script.

This matters at the promised scale. Three source buildings cannot yield a
12-to-16-structure village without obvious cloning. Flipping is not a harmless
variation in a fixed isometric view: it reverses roof and facade orientation,
chimney placement, and the spike's directional lighting. Recoloring preserves
identical silhouettes. Five optional generated buildings leave at least four
to eight repeats, and the fallback explicitly accepts fewer distinct
buildings. That may be a useful prototype, but it is not a production answer
to "full village confusable with the spike."

#### Exact local pixels do not guarantee composition fidelity

The spike's fidelity comes from a unified painting, not independently from
each cottage. Its shared light, grass treatment, path edges, overlapping
shadows, density, and color grading make the composition cohere. Cutting those
objects apart and scattering them over repeated grass diamonds risks a collage
of edge halos and duplicated baked shadows. Claude acknowledges pasted-cutout
risk, but its mitigation is an eyeball test followed by generative repair. That
repair is the load-bearing production method, not optional upside, because at
least the occluded source buildings require it before they are reusable.

The sprite composition is architecturally better than plates for later moving
actors, but the current single `building_contact_cell()` depth key only orders
an entire sprite at its footprint's front edge. The contract itself says
perfect side occlusion for tall multi-cell buildings is out of scope. Dense
fences, trees, lean-tos, and an actor between parts of a compound smithy expose
that limitation. Treating the whole smithy, anvil, grindstone, and lean-to as
one sprite makes the failure unavoidable. Treating them separately brings back
the missing-pixel and seam problem. "The existing depth spine solves
occlusion" is therefore too broad.

At zoom-out, twelve large alpha sprites plus numerous props can work, but thin
fences and flower details need mip/filter validation. At zoom-in, a slice has
only the spike's source resolution. The camera's 2.0 zoom level magnifies the
same pixels; "stays crisp at every zoom" is unsupported. A stock export can
contain the textures perfectly and still reveal extraction damage or
insufficient source resolution.

#### The export plan contains one incorrect mechanism

Claude has the best export-safe story of the three proposals because it tests
an isolated packaged artifact and asserts that the fallback did not run. That
is the correct gate. However, committing Godot `.import` sidecars is not the
mechanism here: this repository's `.gitignore` explicitly ignores `*.import`
and `.godot/`. Godot 4 generates imported cache artifacts during the headless
import pass. The synthesis should commit source PNGs in an export-visible tree,
reference them as resources, run the pinned engine's import, export, and then
exercise the isolated package. It should not silently reverse the repository's
import policy as an implementation detail.

The proposed `is_prop` flag also mixes two different facts. Collision is sim
semantics and belongs in headless authored data, while texture identity and
render category do not. A semantic placement kind with a footprint/collision
policy is defensible. A render-driven `is_prop` discriminator added merely so
the assembler chooses behavior repeats the existing `sprite_key` leakage
rather than cleaning the seam. I do not claim this proposal violates the
constitution because the exact field design is not fixed, but synthesis must
keep `TownLayout` viewport-free and texture-ignorant.

### What should happen instead

Keep Claude's individual placement model for buildings and foreground
occluders, its explicit free-camera scene, and its isolated packaged-export
gate. Use the spike as style and composition reference, plus perhaps as a
background or district source where no separation is required, but do not
declare occluded flattened objects a reusable kit until a one-building
extraction proves clean at 0.5x, 1x, and 2x. Generate or paint complete RGBA
objects with visible backs and clean ground contacts. Split compound structures
at planned occlusion boundaries. Define semantic structure/prop kinds and
collision footprints in sim data, with all texture paths and anchors mapped in
render data. Price the first buildable milestone as four clean structures, not
a nominal 12-to-16 assembled from three compromised slices.

## Antigravity proposal

### Steelman

The strongest version of Antigravity's proposal is a geometry-first authoring
pipeline that guarantees repeatable camera, scale, footprint, and clean alpha,
then uses a tightly constrained 2D restyle only as the final surface treatment.
Its sprites-on-grid composition is a better long-term occlusion model than my
large plates if the restyle can preserve silhouettes and contact anchors.

### Attack

#### It repeats the failed experiment without a new falsifiable technique

Round 006 already produced two candidates from this family against this exact
bar. Candidate A was a deterministic NPR/composite render and was ruled muddy
and under-tuned. Candidate B used a Meshy texture-space restyle and was ruled a
glossy, photoreal clash. The acceptance harness ruled that neither passed
fidelity. Antigravity proposes "configure a stylized material" or "apply a
lightweight ... img2img pass," which are descriptions of those same two escape
routes, not a new method. No shader model, reference-conditioning scheme,
denoise strength, palette constraint, edge treatment, or numerical acceptance
threshold distinguishes this attempt from the two failures.

The first-hour single-building test is necessary but insufficient. A cottage
can pass in isolation while a full village fails through inconsistent restyles,
lighting drift, line-weight drift, or loss of repeated architectural identity.
Conversely, tuning one shader for slate, timber, foliage, water, dirt, flowers,
and metal is not a one-building problem. The proposal estimates one to two days
for all of those categories without stating how many render/restyle iterations
or how a failed batch is bounded. Its own blow-up factor is not an edge case. It
is the already-observed result.

The geometry guarantee is also narrower than stated. Blender calibration can
guarantee camera projection and pixels per metre for the guide render. An
img2img pass can move silhouettes, eaves, footprints, cast shadows, and contact
points. Once it does, the output is no longer guaranteed to conform to
`building_contact_cell()` or the 32*sqrt(6) px/m scale. The proposal supplies no
post-restyle alpha, anchor, or scale gate. If img2img is constrained enough not
to move geometry, it is also less able to replace the clean 3D medium with the
spike's painterly shapes. That is the central tradeoff and it is hand-waved.

#### The named owner cannot execute the claimed slice

The proposal says Antigravity should own Meshy generation, but `TEAM-STATE.md`
records that Meshy is wired only for the Codex and Claude worker seats and that
Antigravity physically cannot reach it. This is not a scheduling inconvenience.
It breaks the division-of-labor claim and adds an unpriced handoff for prompts,
paid calls, provenance, downloaded meshes, and iteration feedback. The proposed
20-to-40-credit budget for 3-to-4 buildings, multiple trees, and key props is
not tied to a per-call price or retry count, so it is not an enforceable cap.

#### Four buildings are not the requested village

The first buildable milestone contains four buildings, three trees, and "a few
props." That is a pipeline demo, not a full Two Rivers village. The estimate
pushes roads, ground painting, water, bridges, architectural variety, district
composition, dense prop placement, and the actual 12-plus-structure scale into
an unnamed later milestone. The method is plausible for five assets precisely
because it does not price village volume. Scaling through cloned meshes makes
the settlement visibly procedural; scaling through unique Meshy calls expands
credits, cleanup, storage, and style-QC roughly with asset count. Round 006 also
recorded about 180 MB of raw Meshy GLB/FBX data as untenable at production scale
in plain git. This proposal does not say what source assets are retained or how
that storage cost is controlled.

#### Export safety is asserted more than specified

Putting PNGs outside `.gdignore` and loading them through Godot resources is
the right direction. The static ban on `Image.load` is only a proxy and can
both overreach authoring/test code and miss other dynamic path construction.
The packaged integration test is the real proof, but the proposal does not say
that it runs the package in isolation from the source tree, asserts exact
village resource identities, or detects fallback art. Round 006's harness ran
from source and therefore missed the failure. Merely resolving "these `.import`
files" can pass while the intended texture lookup silently chooses a default.
Claude's isolated-package, non-placeholder assertion is materially stronger
and should replace this vague test.

The grid composition itself is sound for discrete buildings, but the proposal
does not address the frozen contract's admitted side-occlusion limitation,
compound props, or free-camera extremes. A 3D source does not help after it is
flattened into one sprite. Trees and fences need deliberate segmentation and
footprints, not merely generic `PropPlacement`. Zoom-in exposes render
resolution and img2img artifacts; zoom-out exposes thin-feature filtering and
cloned silhouettes. None are tested in the milestone.

I do not find a demonstrated constitution violation in Antigravity's proposal.
Its authored grid can remain deterministic, its sim data can remain headless,
and its asset paths can remain cross-platform. The risk is that the proposal
does not specify those gates. Any implementation must use explicit authored
placements or pure seed-and-position generation, keep projection and texture
metadata out of `src/sim/`, and use `res://` paths.

### What should happen instead

Do not adopt Meshy-to-Blender as the primary pixel source after two failed
fidelity gates. Retain Blender only as an optional composition and scale guide.
Make a 2D painterly workflow the final-pixel source, with a first gate that
compares one complete district and at least two distinct buildings at shipping
0.5x, 1x, and 2x zoom. If geometry-first art remains in contention, require one
new, concrete restyle recipe and post-restyle silhouette, anchor, scale, and
light-direction measurements before any batch spend. Assign paid Meshy calls
to a seat that actually has access. Use Claude's isolated packaged-art check,
and define the milestone in village-scale counts so a four-building demo cannot
be mistaken for completion.
