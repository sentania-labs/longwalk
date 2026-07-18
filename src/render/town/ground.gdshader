shader_type canvas_item;

// Continuous village ground plane (decision 010, PLATE fallback). This shader
// paints the WHOLE district as one field instead of N flat per-cell diamonds
// (the checkerboard tell agy QA flagged). It runs on a single quad whose UV
// array is set to the CELL coordinates of its corners (see
// village_render.gd::_build_ground), so the UV varying handed to fragment() is
// fractional CELL space by affine interpolation, with NO per-frame screen->iso
// inversion.
//
// PLATE SAMPLING (decision 010 PLATE fallback, pre-authorized 4-0). The
// tileable-swatch approach failed the 8x8 zoom gate: a paid painterly field
// carries faint quasi-regular structure that reads as a repeat only under
// high-frequency TILING. So the grass/dirt textures are painterly PLATES
// sampled ACROSS THE WHOLE DISTRICT exactly once (paint_uv = cell / grid_size),
// not tiled per cell. Sampled once, that structure is just texture detail, not
// a periodic tell. Only the SAMPLING FREQUENCY changed from the swatch design;
// the quad, the cell-space UV, the lane mask, the domain warp, the protected
// lane core, and the separate contact-shadow layer are all unchanged.
//
// DETERMINISM (constitution, decision 010 step 4): this shader does NOT hash any
// noise live. In-shader GLSL float-hash value noise diverges across GPU
// vendors/drivers/precision, which would move a lane edge underneath a tree on
// one machine and beside it on another. The wander comes entirely from
// `warp_tex`, a CPU-baked fixed-seed FastNoiseLite field sampled as a uniform.
// There is no TIME, no screen-space input, and no order dependence here.
//
// PROTECTED SEMANTIC LANE CORE (decision 010 step 5): the central `core_frac` of
// every PATH cell is UNWARPED solid dirt; only the feathered edge warps, capped
// at `warp_amp` (<= 0.2 cell). The visually solid lane never advertises
// traversability the sim lacks.

// Painterly PLATES, sampled ONCE across the district (see header). At the
// default plate_repeat = 1.0 the UV stays in 0..1 and never wraps, so
// repeat_disable is correct and there is no tile-boundary seam at all. The
// mipmap filter is declared so the plate uses a mip chain wherever one exists;
// like every other texture in this repo the plates import with Godot's default
// settings (no committed .import, mips off), so today this falls back to
// base-level linear. That is already clean at 0.5x for these low-frequency
// painterly fields, and the filter is future-proof if mips are ever enabled.
uniform sampler2D grass_tex : repeat_disable, filter_linear_mipmap;
uniform sampler2D dirt_tex : repeat_disable, filter_linear_mipmap;

// CPU-baked warp field (R,G = a signed 2D displacement encoded around 0.5). Flat
// mid-grey encodes zero displacement (straight edges) for the provisional
// placeholder; integration swaps in codex's fixed-seed FastNoiseLite bake.
uniform sampler2D warp_tex : repeat_enable, filter_linear;

// Runtime R8 lane mask derived from the sim PATH/GRASS grid (built in GDScript,
// rasterized at K>1 texels/cell). PATH -> 1, GRASS -> 0. Clamped so the district
// edge does not wrap a lane in from the far side.
uniform sampler2D lane_mask : repeat_disable, filter_linear;

// District size in cells (UV runs 0..grid_size). Used to turn cell space into
// the mask's 0..1 sample space.
uniform vec2 grid_size = vec2(16.0, 14.0);

// Plate repeat across the district. 1.0 = the plate covers the whole district
// exactly once (a single sample, NO tiling, so no repeat structure, the whole
// point of the plate fallback). A value <= ~2.0 may be set if 1x reads too soft
// at 2x zoom, but anything above 1.0 re-tiles the plate and can reintroduce a
// faint seam (the paint UV is NOT warped), so prefer the fewest repeats: 1.0.
uniform float plate_repeat = 1.0;

// Warp displacement amplitude in CELL units. Decision 010 caps this at 0.2 so a
// 1-cell lane's central 0.5 cell (radius 0.25) is never reached by the warp.
uniform float warp_amp : hint_range(0.0, 0.2) = 0.18;

// Fraction of a PATH cell reserved as unwarped solid dirt.
uniform float core_frac : hint_range(0.0, 1.0) = 0.5;

// How many cells per full cycle of the warp field (low frequency = broad wander).
uniform float warp_freq = 0.35;

// Feather half-width of the grass<->dirt transition, in cell units.
uniform float edge_soft : hint_range(0.01, 1.0) = 0.28;

void fragment() {
	// UV is fractional CELL space (the quad's UV array is its cell corners).
	vec2 cell = UV;

	// --- plate paint lookups with explicit gradients (decision 010 step 6) ---
	// The grass/dirt PLATES span the whole district once: cell / grid_size maps
	// the district's cell rectangle onto the plate's 0..1 UV, so the plate is
	// sampled a single time, not tiled. textureGrad keeps hardware mip selection
	// correct: we hand it the true screen-space derivative of the (unwarped)
	// paint UV, so the warped mask sampling below can never corrupt the paint's
	// LOD choice.
	vec2 paint_uv = (cell / grid_size) * plate_repeat;
	vec2 ddx = dFdx(paint_uv);
	vec2 ddy = dFdy(paint_uv);
	vec4 grass = textureGrad(grass_tex, paint_uv, ddx, ddy);
	vec4 dirt = textureGrad(dirt_tex, paint_uv, ddx, ddy);

	// --- CPU-baked domain warp (no in-shader hash; determinism) ---
	vec2 warp_n = texture(warp_tex, cell * warp_freq).rg * 2.0 - 1.0;
	vec2 warp_offset = warp_n * warp_amp;

	// --- lane coverage ---
	// Unwarped coverage protects the solid core; warped coverage frays the edge.
	float cov_core = texture(lane_mask, cell / grid_size).r;
	float cov_edge = texture(lane_mask, (cell + warp_offset) / grid_size).r;

	// The deep interior of a PATH cell (unwarped coverage saturated) is forced
	// solid dirt and never allowed to warp; core_frac widens that protected band.
	float core = smoothstep(1.0 - core_frac, 1.0, cov_core);
	float coverage = max(cov_edge, core);

	float lane = smoothstep(0.5 - edge_soft, 0.5 + edge_soft, coverage);

	COLOR = mix(grass, dirt, lane);
}
