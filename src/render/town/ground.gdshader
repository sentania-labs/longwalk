shader_type canvas_item;

// Continuous village ground plane (decision 010, PLATE fallback; lane coverage
// rebuilt for decision 011). This shader paints the WHOLE district as one field
// instead of N flat per-cell diamonds (the checkerboard tell agy QA flagged). It
// runs on a single quad whose UV array is set to the CELL coordinates of its
// corners (see village_render.gd::_build_ground), so the UV varying handed to
// fragment() is fractional CELL space by affine interpolation, with NO per-frame
// screen->iso inversion.
//
// PLATE SAMPLING (decision 010 PLATE fallback, pre-authorized 4-0). The
// tileable-swatch approach failed the 8x8 zoom gate: a paid painterly field
// carries faint quasi-regular structure that reads as a repeat only under
// high-frequency TILING. So the grass/dirt textures are painterly PLATES
// sampled ACROSS THE WHOLE DISTRICT exactly once (paint_uv = cell / grid_size),
// not tiled per cell. Sampled once, that structure is just texture detail, not
// a periodic tell.
//
// LANE COVERAGE (decision 011). The lane geometry is authored as sim-side
// meandering polylines (src/sim/town_layout.gd) and BAKED OFFLINE into two
// committed data textures by tools/art/bake_lane_mask.gd:
//   - lane_mask.R: the UNWARPED protected core (the honest nav-PATH footprint).
//   - lane_mask.G: the cosmetic shoulder coverage, with the organic domain warp
//     and the bounded junction smooth-minimum ALREADY baked in.
//   - lane_density.R: a low-frequency wear field.
// The shader therefore does NOT re-warp the lane edge (decision 011: the warp is
// baked into the shoulder channel; re-warping here would double-warp and desync
// the rendered dirt from the sim footprint again). It only reshapes the baked
// coverage into a soft two-stop transition and mottles the shoulder dirt by the
// wear field. The protected core is read from the unwarped channel and forced
// solid; density is never allowed to reduce it.
//
// DETERMINISM (constitution, decision 010 step 4, decision 011): this shader
// hashes no noise live. All stochastic shaping (warp, wear) is a pure function
// of the fixed bake seed and integer texel, precomputed into the committed
// masks. There is no TIME, no screen-space input, and no order dependence here.

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

// Baked lane mask (decision 011). RG8, pinned lossless / non-sRGB: R is the
// UNWARPED protected core, G is the cosmetic shoulder coverage (warp + junction
// smooth-minimum baked in). Clamped so the district edge does not wrap a lane in
// from the far side.
uniform sampler2D lane_mask : repeat_disable, filter_linear;

// Baked low-frequency wear density (decision 011). R8, pinned lossless /
// non-sRGB. Modulates dirt opacity and tone OUTSIDE the protected core so the
// dirt reads as patchy worn earth, never a flat uniform fill (tell #3).
uniform sampler2D lane_density : repeat_disable, filter_linear;

// District size in cells (UV runs 0..grid_size). Used to turn cell space into
// the mask's 0..1 sample space.
uniform vec2 grid_size = vec2(16.0, 14.0);

// Plate repeat across the district. 1.0 = the plate covers the whole district
// exactly once (a single sample, NO tiling, so no repeat structure, the whole
// point of the plate fallback). Prefer the fewest repeats: 1.0.
uniform float plate_repeat = 1.0;

// Protected-core threshold. The baked core channel is effectively binary at
// texel centers; a narrow smoothstep around 0.5 gives a clean one-texel edge on
// the honest solid-dirt core.
uniform float core_lo : hint_range(0.0, 1.0) = 0.35;
uniform float core_hi : hint_range(0.0, 1.0) = 0.65;

// Two-stop feathered shoulder transition (decision 011, tell #2). The baked
// shoulder coverage G runs 1 (lane center) -> 0 (grass). shoulder_hi..1 is
// solid dirt; shoulder_mid..shoulder_hi ramps; shoulder_lo..shoulder_mid is the
// outer mottled fade to grass. Two stops (mid, hi) give the soft patchy edge
// instead of decision 010's single hard threshold.
uniform float shoulder_lo : hint_range(0.0, 1.0) = 0.06;
uniform float shoulder_mid : hint_range(0.0, 1.0) = 0.34;
uniform float shoulder_hi : hint_range(0.0, 1.0) = 0.72;

// Wear modulation (decision 011, tell #3). density_contrast is how far low wear
// thins the OUTER (mottled) shoulder dirt; tone_contrast is how far low wear
// darkens the shoulder dirt tone. Both are bounded and apply OUTSIDE the core
// only, so the protected core stays solid true-tone dirt.
uniform float density_contrast : hint_range(0.0, 1.0) = 0.5;
uniform float tone_contrast : hint_range(0.0, 0.6) = 0.16;

void fragment() {
	// UV is fractional CELL space (the quad's UV array is its cell corners).
	vec2 cell = UV;

	// --- plate paint lookups with explicit gradients (decision 010 step 6) ---
	// The grass/dirt PLATES span the whole district once: cell / grid_size maps
	// the district's cell rectangle onto the plate's 0..1 UV, so the plate is
	// sampled a single time, not tiled. textureGrad keeps hardware mip selection
	// correct: we hand it the true screen-space derivative of the paint UV.
	vec2 paint_uv = (cell / grid_size) * plate_repeat;
	vec2 ddx = dFdx(paint_uv);
	vec2 ddy = dFdy(paint_uv);
	vec4 grass = textureGrad(grass_tex, paint_uv, ddx, ddy);
	vec4 dirt = textureGrad(dirt_tex, paint_uv, ddx, ddy);

	// --- baked lane coverage (no in-shader warp; the warp is in the mask) ---
	vec2 mask_uv = cell / grid_size;
	vec2 lane = texture(lane_mask, mask_uv).rg;
	float core = lane.r;      // unwarped protected core (honest nav footprint)
	float shoulder = lane.g;  // cosmetic coverage, warp + smin baked in
	float density = texture(lane_density, mask_uv).r;

	// Protected core: forced solid dirt, decision-010 honesty now sourced from
	// the baked unwarped channel. Never reduced by the shoulder or the density.
	float core_solid = smoothstep(core_lo, core_hi, core);

	// Two-stop feathered shoulder (tell #2). dirt_full saturates near the lane;
	// dirt_edge is the outer soft fade whose reach the wear field modulates.
	float dirt_full = smoothstep(shoulder_mid, shoulder_hi, shoulder);
	float dirt_edge = smoothstep(shoulder_lo, shoulder_mid, shoulder);

	// Wear thins the mottled outer band (tell #3): low density pulls the fade in,
	// high density fills it out, so the dirt/grass edge is patchy, not a line.
	float wear = mix(1.0 - density_contrast, 1.0, density);
	float shoulder_cov = max(dirt_full, dirt_edge * wear);

	// Coverage never drops below the protected core.
	float dirt_amount = max(core_solid, shoulder_cov);

	// Patchy dirt tone (tell #3): mottle the shoulder dirt by wear so the earth
	// reads non-uniform. The core keeps true dirt tone (mix weight 1 - core).
	vec3 shoulder_rgb = dirt.rgb * mix(1.0 - tone_contrast, 1.0, density);
	vec3 dirt_rgb = mix(dirt.rgb, shoulder_rgb, 1.0 - core_solid);
	vec4 dirt_toned = vec4(dirt_rgb, dirt.a);

	COLOR = mix(grass, dirt_toned, dirt_amount);
}
