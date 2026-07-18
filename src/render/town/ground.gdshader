shader_type canvas_item;

// Continuous village ground plane (decision 010). This shader paints the WHOLE
// district as one field instead of N flat per-cell diamonds (the checkerboard
// tell agy QA flagged). It runs on a single quad whose UV array is set to the
// CELL coordinates of its corners (see village_render.gd::_build_ground), so the
// UV varying handed to fragment() is fractional CELL space by affine
// interpolation, with NO per-frame screen->iso inversion.
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

// Tiling painterly swatches, sampled in cell space. repeat_enable makes the
// swatch tile regardless of the texture's import mode; the mipmap filter keeps
// them from shimmering when the free-cam zooms out.
uniform sampler2D grass_tex : repeat_enable, filter_linear_mipmap;
uniform sampler2D dirt_tex : repeat_enable, filter_linear_mipmap;

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

// Swatch repeat rate: how many texture tiles per ground cell. Picked so the
// swatch stays crisp at 2x (codex's texel-density budget).
uniform float tiles_per_cell = 1.0;

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

	// --- paint lookups with explicit gradients (decision 010 step 6) ---
	// textureGrad keeps hardware mip selection correct: we hand it the true
	// screen-space derivative of the (unwarped) paint UV, so the warped mask
	// sampling below can never corrupt the paint's LOD choice.
	vec2 paint_uv = cell * tiles_per_cell;
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
