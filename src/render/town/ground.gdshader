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

// Dirt DETAIL control texture (decision 012), sampled ONCE at paint_uv exactly
// like the plates. RG8, pinned lossless / non-sRGB, baked offline by
// tools/art/bake_dirt_detail.gd from the grass plate's luminance high-pass:
//   - R = full high-frequency SHOULDER detail (pebbles, tufts, worn flecks),
//     zero-mean, centered 0.5. Modulates dirt tone on the cosmetic shoulder and
//     dithers the shoulder coverage isoline (edge-break).
//   - G = broad low-frequency CORE drift, zero-mean, centered 0.5. The ONLY
//     detail the protected core receives (the ratified core-honesty ruling): a
//     bounded value drift, never the high-frequency R band.
// This carries the source structure the flat dirt plate lacks (tell #1); it is
// applied ZERO-MEAN so it never changes coverage/opacity, only tone.
uniform sampler2D dirt_detail : repeat_disable, filter_linear_mipmap;

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
// Widened for decision 012 tell #2: shoulder_hi loosened (0.72 -> 0.60) so the
// solid-dirt plateau starts sooner and the ramp is longer, and the lo..mid outer
// band widened (0.06/0.34 -> 0.03/0.30) so the mottled fade to grass reaches
// further. Combined with the R-field edge-break perturbation this turns the old
// clean isoline into a broad, patchy, non-monotone transition.
uniform float shoulder_lo : hint_range(0.0, 1.0) = 0.03;
uniform float shoulder_mid : hint_range(0.0, 1.0) = 0.30;
uniform float shoulder_hi : hint_range(0.0, 1.0) = 0.60;

// Wear modulation (decision 011, tell #3). density_contrast is how far low wear
// thins the OUTER (mottled) shoulder dirt; tone_contrast is how far low wear
// darkens the shoulder dirt tone. Both are bounded and apply OUTSIDE the core
// only, so the protected core stays solid true-tone dirt.
uniform float density_contrast : hint_range(0.0, 1.0) = 0.5;
// tone_contrast reduced 0.16 -> 0.10 (decision 013): the wear-driven broad
// darkening is a low-frequency mechanism that does NOT inherit the plate
// regrade, and at 0.16 it re-added the broad "wet mud" tone step the multiband
// flatten removed from the plate. Reduced only as far as the captures required.
uniform float tone_contrast : hint_range(0.0, 0.6) = 0.10;

// Dirt-detail modulation (decision 012 #1, zero-mean value modulation
// dirt.rgb *= mix(1-c, 1+c, detail)). detail_shoulder_amp is the full-amplitude
// swing applied by the R channel on the cosmetic SHOULDER (strong structure);
// detail_core_amp is the BOUNDED LOW swing applied by the G channel on the
// protected CORE (broad drift only, never R). Both are zero-mean, so the mean
// dirt tone and the coverage/opacity (dirt_amount, core_solid) are untouched.
// detail_shoulder_amp reduced 0.40 -> 0.18 (decision 013 measured sweep): the
// multiband-flattened plate now supplies dry speckle directly (its own native
// gradient 10.20 already sits at the grass shimmer level 10.28), and the finer
// (radius-3) R high-pass carries more high-frequency energy per unit variance,
// so at 0.40 the rendered shoulder fine-gradient (11.98) breached the grass
// shimmer ceiling. At 0.18 the rendered gradient lands ~10.30, at the native
// grass level (the native decode reads higher than the shipped minified 0.5x
// render, so this is the conservative same-basis test), while the plate keeps
// the shoulder dry-structured. detail_core_amp trimmed 0.11 -> 0.09 (the core G
// broad drift is a low-frequency term; the flattened plate already lifts the
// protected-core std to ~19.9, so less G drift is needed and it keeps any
// residual broad step off the core).
uniform float detail_shoulder_amp : hint_range(0.0, 0.5) = 0.18;
uniform float detail_core_amp : hint_range(0.0, 0.2) = 0.09;

// Transition edge-break (decision 012 #2). The R field, sampled at a FIXED
// ROTATED/OFFSET UV so it decorrelates from the tone sample above (codex's
// embossing critique: one shared sample would emboss bright flecks exactly onto
// the edge bulges), perturbs the shoulder coverage BEFORE the two-stop
// smoothstep. This dithers the clean isoline into a patchy grass-invades-dirt
// edge; the widened two-stop feather then broadens that band. edge_break_amp is
// zero-mean, so it does not change net coverage on its own (the widened feather
// and the narrower authored lanes set net coverage).
uniform float edge_break_amp : hint_range(0.0, 0.6) = 0.20;
uniform vec2 edge_break_offset = vec2(0.041, 0.067);

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

	// Dirt DETAIL, sampled ONCE at paint_uv with the same explicit gradients as
	// the plates (decision 012). detail.r = high-frequency shoulder structure,
	// detail.g = broad core drift, both zero-mean centered at 0.5.
	vec2 detail = textureGrad(dirt_detail, paint_uv, ddx, ddy).rg;
	// A SECOND, decorrelated R sample for the edge-break (decision 012 #2). A
	// fixed 90-degree rotation about the plate center lands on entirely different
	// texels than the tone sample yet stays inside 0..1 (no repeat_disable clamp
	// smear), plus a small fixed offset. Mip selection is unchanged: a 90-degree
	// rotation preserves derivative length, so the plate's own gradients pick the
	// same level. This breaks the tone<->edge correlation codex flagged.
	vec2 eb_uv = clamp(vec2(paint_uv.y, 1.0 - paint_uv.x) + edge_break_offset, vec2(0.0), vec2(1.0));
	float edge_detail = textureGrad(dirt_detail, eb_uv, ddx, ddy).r;

	// --- baked lane coverage (no in-shader warp; the warp is in the mask) ---
	vec2 mask_uv = cell / grid_size;
	vec2 lane = texture(lane_mask, mask_uv).rg;
	float core = lane.r;      // unwarped protected core (honest nav footprint)
	float shoulder = lane.g;  // cosmetic coverage, warp + smin baked in
	float density = texture(lane_density, mask_uv).r;

	// Protected core: forced solid dirt, decision-010 honesty now sourced from
	// the baked unwarped channel. Never reduced by the shoulder or the density.
	float core_solid = smoothstep(core_lo, core_hi, core);

	// Edge-break (tell #2): perturb the shoulder coverage by the decorrelated R
	// field (zero-mean about 0.5) BEFORE the two-stop smoothstep, so the isoline
	// wanders into a patchy, non-monotone dirt/grass boundary instead of a clean
	// cut. Coverage never drops below the protected core (asserted below), so this
	// cosmetic dither cannot eat into the honest nav footprint.
	float shoulder_broken = shoulder + (edge_detail - 0.5) * edge_break_amp;

	// Two-stop feathered shoulder (tell #2). dirt_full saturates near the lane;
	// dirt_edge is the widened outer soft fade whose reach the wear field modulates.
	float dirt_full = smoothstep(shoulder_mid, shoulder_hi, shoulder_broken);
	float dirt_edge = smoothstep(shoulder_lo, shoulder_mid, shoulder_broken);

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

	// Zero-mean DIRT-DETAIL value modulation (decision 012 #1). The SHOULDER
	// takes the R channel at full amplitude (strong high-frequency structure);
	// the protected CORE takes ONLY the G channel at a bounded low amplitude
	// (broad drift, never R). core_solid selects between them, so the core never
	// receives the high-frequency band. Being zero-mean (detail centered 0.5),
	// this shifts tone only and leaves dirt_amount / core_solid untouched.
	float shoulder_mod = mix(1.0 - detail_shoulder_amp, 1.0 + detail_shoulder_amp, detail.r);
	float core_mod = mix(1.0 - detail_core_amp, 1.0 + detail_core_amp, detail.g);
	float detail_mod = mix(shoulder_mod, core_mod, core_solid);
	dirt_rgb *= detail_mod;

	vec4 dirt_toned = vec4(dirt_rgb, dirt.a);

	COLOR = mix(grass, dirt_toned, dirt_amount);
}
