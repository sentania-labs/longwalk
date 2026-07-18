# Codex critique: peer ground and lane proposals

This critiques the two phase-1 proposals I did not author. I did not read either
before committing my own proposal.

## Claude proposal

### Steelman

The strongest version is a single render-side mesh whose interpolated coordinates
are ground-cell coordinates, with reusable high-resolution rectangular grass and
dirt swatches and a lane mask derived from the authoritative semantic grid. If the
swatches pass a tiled contact-sheet test and the mesh coordinate mapping is proven
in Godot, this scales better than my district plate and automatically follows
layout edits. That scalability and automatic layout coupling are better than my
proposal.

### Attack

The proposal wins its comparisons before proving its two load-bearing inputs.
"Crisp at any zoom" does not follow from using a shader. A repeated 512 px texture
is crisp at 2x only if its chosen world-space repeat rate supplies enough source
texels per displayed repeat. If one swatch spans eight cells, for example, each
cell receives only 64 source texels before zoom and 128 displayed pixels at 2x,
which is still a 2:1 enlargement. The implementation needs a numeric texel-density
budget derived from the projected cell size and the 2x capture, plus mip/filter
settings. Repetition avoids stretching one plate over roughly 9200 screen pixels,
but can replace blur with visible wallpaper. Low-frequency tint changes luminance,
not repeated blades, stones, or brush marks. Two copies cross-faded by noise still
repeat their internal motifs.

The proposal does acknowledge that seamless swatches are the crux, but its claimed
SMALL estimate assumes the crux succeeds. A crop from a non-tiling flattened
painting is not tileable merely because opposite edges are offset-blended. That
operation can hide the boundary while duplicating or ghosting features through the
middle. The required acceptance test should be mechanical and visual: produce at
least an 8x8 repeat contact sheet at the intended in-game scale, inspect both
boundaries and repeated landmarks at 0.5x, 1x, and 2x, and reject the swatch if a
repeat axis or recurring motif is visible. Paid image-to-image generation is not a
bounded fallback until it produces a genuinely periodic output. Conditioning on a
crop does not itself impose equal opposite edges.

The UV argument is plausible, not established. A convex four-vertex `Polygon2D`
can interpolate custom UVs affinely, and the isometric projection is linear, so the
math should work. However, the proposal must prove vertex ordering, triangulation,
and custom UV values beyond the usual texture-pixel range with a Godot capture. A
gradient that merely "matches `screen_to_cell`" is underspecified. The test should
sample known cell corners and centers on both triangles and bound the coordinate
error, especially across their shared diagonal. `MeshInstance2D` is a reasonable
fallback, but calling this low risk without that artifact is premature.

The determinism claim is materially too strong. A floating-point GLSL hash can be
a pure function of cell coordinates while still differing across GPU vendors,
drivers, and shader precision. "Pure" does not imply "byte-stable across runs" or
platforms. Claude explicitly proposes in-shader value noise and supplies no CPU-
baked integer noise texture or cross-renderer image comparison. This does not yet
prove the constitution's determinism requirement for placement decisions. Because
the warp is cosmetic rendering rather than placement, the safer synthesis is to
avoid claiming constitutional byte identity for framebuffer pixels, but it still
must remain stable enough not to alter lane coverage visibly. If exact visual
repeatability is required, generate an R8/RG8 warp field on CPU from an integer
hash of seed and texel coordinates and sample that field in the shader.

The sim/render boundary itself is sound, but the visual/semantic boundary is only
promised. "Less than the soft-edge width" supplies neither an amplitude nor a
semantic guarantee. A bilinearly filtered one-texel-per-cell mask already places a
broad mixed region around the cell boundary. Warping that mask can show dirt on a
GRASS-cost point or grass on a PATH-cost point. The implementation needs a stated
maximum displacement in cells and a capture or probe demonstrating that the
visually solid lane core remains inside PATH cells. A conservative target would
reserve the central 0.5-cell-wide portion of every PATH cell as unwarped solid dirt
and constrain only the feathered edge to at most 0.2 cell. Those are proposed
acceptance numbers, not facts established by phase 1.

Export coverage is directionally correct but incomplete. The current packaged
audit enumerates manifest textures. A shader indirectly referenced by a packed
scene may ship, but the new `.gdshader` and any shadow resource should also receive
an explicit `ResourceLoader.exists` and load assertion from the isolated PCK. A
runtime-generated mask needs no static asset entry. No raw load or export glob is
needed.

Finally, this is a genuine method change from per-cell flat diamonds, but it can
still look like the checkerboard with softened edges if grass and dirt are sampled
at cell-correlated phases or the tiny mask remains legible. The gate must judge the
packaged ground at all three zooms. Failure due to wallpaper, diagonal phase
changes, or a fuzzy straight band requires changing swatch construction or mask
rasterization, not adding more tint noise.

### What should happen instead

Keep Claude's continuous cell-space mesh and render-derived semantic mask as the
leading runtime method. Make adoption conditional on three spikes before full
integration: a coordinate test across both mesh triangles, an 8x8 tiled contact
sheet plus 0.5x/1x/2x texel-density captures, and a CPU-generated deterministic
warp texture with a numeric displacement cap. Load-check every static texture and
shader explicitly from the isolated PCK. If truly periodic swatches cannot pass,
do not disguise the failure with more shader noise. Fall back to a higher-density
authored base or generate periodic textures with an edge-constrained process.

## Antigravity proposal

### Steelman

The strongest version is also a single splat-mapped render plane, but with a CPU-
generated, fixed-seed `FastNoiseLite` warp field rather than floating-point shader
hash noise. That is stronger than both Claude's in-shader determinism story and my
manual plate for reproducibility and layout scaling, provided the noise field is
baked from stable integer coordinates and packaged captures prove the result.

### Attack

The proposed primary texture path is not viable as written. The existing 128x64
files are alpha isometric diamonds, not seamless rectangular samples. Screen-to-
iso coordinate math can map a point into cell space, but it cannot synthesize
missing pixels outside each diamond, remove baked content or shadow from a source,
or make opposite rectangular edges equal. Repeating the PNG rectangle repeats
transparent corners and seams. Reconstructing diamonds by selecting neighboring
cells recreates the per-cell organizing grid the proposal is supposed to remove.
The proposal admits rectangular preprocessing only after failure, even though the
source format makes that failure predictable. Most of the stated 3-5 hour
"straightforward" path therefore rests on the wrong input representation.

Its 2x fidelity story is absent. A 128x64 source repeated across a district avoids
the single-plate stretch but magnifies a very small motif and makes repetition
obvious. There is no texel-density calculation, intended repeat period, import
filter/mipmap choice, or packaged 2x acceptance capture. The method trades the
checkerboard for either transparent diamond seams or a wallpaper of identical
128x64 brush marks. Rectangular high-resolution swatches are not an optional
fallback. They are a prerequisite.

The CPU-noise direction is the proposal's strongest technical distinction, but
"seeded deterministically by the layout coordinates" is not a complete contract.
It must name the world/layout seed, fixed layer offset, integer texel coordinate,
noise resolution, and normalization. A `FastNoiseLite` image generated by a fixed
loop is order-independent only if every output sample is directly evaluated from
those inputs and no stateful RNG participates. The generated image should be made
once on CPU and sampled by the shader. That avoids cross-GPU hash variance, though
framebuffer interpolation can still vary slightly and should not be advertised as
byte-identical rendering across platforms.

As with Claude's proposal, the sim/render dependency direction is correct and
`town_layout.gd` remains texture-ignorant. The semantic mismatch is less honestly
bounded. "Tune carefully" is not a specification. No maximum warp amplitude is
given, so a player can receive GRASS cost while standing on visually solid dirt,
or PATH cost on visually solid grass. A one-pixel-per-cell filtered mask compounds
that ambiguity. The proposal needs a protected lane core and a numeric edge-only
displacement bound before the method can claim semantic honesty.

The export section says assets must be included but does not say how that is
proven. Inclusion is not the gate. `shadow_decal.png`, both replacement swatches,
and `ground_splat.gdshader` must resolve through `ResourceLoader` from the isolated
PCK with nonzero or valid resource assertions. There must be no `Image.load`, raw
`FileAccess`, or `export_presets.cfg` glob edit. The runtime noise and blend images
may remain in-memory derived resources. The proposal does not itself prescribe a
forbidden loader, so this is a missing proof rather than a stated violation.

The contact-shadow layer is sensible, but one global layer below all vertical
objects cannot express shadows cast over ground props while remaining below taller
neighbors. That limitation may be acceptable for soft contact ellipses, which
should remain tight to anchors, but the proposal should not imply it solves general
cast-shadow ordering. It also needs to avoid duplicating shadows already baked into
source sprites or the current lane diamond.

This scales well in node count and asset reuse only after replacing its source
textures. At that point it converges almost entirely on Claude's method, with the
CPU noise texture as its superior contribution. As submitted, the brittle part is
not a tuning risk. It invalidates the main texture-sampling path.

### What should happen instead

Reject sampling the existing diamond PNGs. Adopt high-resolution rectangular,
proven-periodic grass and dirt swatches from the start, use ground-cell coordinates
on a tested mesh, and retain Antigravity's CPU-generated fixed-seed warp texture.
Specify the seed and coordinate contract, protect a solid semantic lane core, cap
edge displacement numerically, and test every static resource from the isolated
PCK. Treat contact ellipses as contact darkening only, not as a complete cast-
shadow solution.

## Synthesis finding

Claude supplies the stronger overall runtime method and Antigravity supplies the
stronger deterministic-warp mechanism. Both are better than my plate on automatic
layout coupling and multi-district reuse. My plate remains stronger only as a
directly art-directed, non-repeating first-district fidelity fallback, and its
semantic fingerprint merely makes repaint debt loud. It does not remove that
debt. The synthesis should therefore test a continuous cell-space mesh with
rectangular periodic swatches and a CPU-baked warp field first, while keeping the
plate only as the explicit fallback if periodic texture fidelity fails the zoom
gate.
