shader_type canvas_item;

// Per-kit tonal coherence grade (decision 016 D4). Each world-object sprite is
// nudged toward its measured scene-key target (manifest.seam_policy.tonal_targets
// / flora_kits) so the separately-generated objects sit in ONE light key with
// the ground, instead of each carrying its own generator's tone. This is a
// bounded per-kit MULTIPLY with material guards, NOT a per-pixel luminance remap
// (agy's D4, rejected) and NOT a replacement for the village CanvasModulate
// (kept as the fixed final grade, pinned by test_smoke_grade.gd).
//
// tonal_mul is computed per sprite in village_render.gd as a clamped, strength-
// damped move from the sprite's own measured midtone toward the target midtone,
// so the shift only closes the disparity rather than fully recoloring. The
// guards below protect the ranges the decision named:
//   - highlight_guard: pixels brighter than this luminance fade back to their
//     original color, so roof/spec highlights are not muddied.
//   - saturation_guard: pixels more saturated than this fade back, so a flower's
//     vivid petals keep their chroma while the surrounding foliage is graded.
//
// TEXTURE-DOUBLING FIX (decision 016 D4, second iteration). In a canvas_item
// fragment the built-in COLOR is ALREADY texture(TEXTURE, UV) * modulate. The
// first cut multiplied the graded texture by that COLOR again (`* mod_col`),
// which re-applied the texture a second time (output = tex^2 * mul), crushing
// every object toward black: a mid-value roof texel (~0.25) came out ~0.10, so
// the grade could never reach its target midtone and the buildings read dark and
// contrasty (agy QA D4). We now read texture(TEXTURE, UV) DIRECTLY (never the
// texture-carrying COLOR), grade that, and apply the per-item modulate exactly
// ONCE via the item_modulate uniform, so the grade lands on its designed key and
// the texture is never squared. The village CanvasModulate is still applied
// after, once, by the canvas compositor.
//
// item_modulate carries the per-sprite modulate (the canvas_item fragment
// built-in MODULATE does not exist in Godot 4.3-stable, so we pass it explicitly
// from village_render.gd). It defaults to white, so an ungraded caller is a
// no-op; a caller that wants to tint or fade a sprite sets it alongside where it
// builds the material.
uniform vec4 item_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform vec3 tonal_mul = vec3(1.0, 1.0, 1.0);
uniform float highlight_guard : hint_range(0.0, 1.0) = 1.0;
uniform float guard_softness : hint_range(0.01, 0.5) = 0.12;
uniform float saturation_guard : hint_range(0.0, 1.5) = 1.5;

// Shadow-lift / de-contrast (decision 016 D4, second iteration). Even with the
// grade landing on target, the buildings' near-black slate roofs and heavy timber
// framing sit well below the ground key (agy QA: "highly contrasty and dark"). A
// uniform multiply cannot lift those darks without blowing the bright plaster on
// the same sprite, so we ALSO lift only the SHADOW band toward a warm scene-key
// tint, compressing the internal contrast. Driven per-kit from village_render.gd
// (structures lift; flora/flowers pass 0 so their floor stays owned by the tonal
// clamp and foliage shadows are not greyed).
uniform float shadow_lift : hint_range(0.0, 0.4) = 0.0;
uniform vec3 shadow_lift_tint : source_color = vec3(1.0, 0.86, 0.62);
uniform float shadow_lift_lo : hint_range(0.0, 1.0) = 0.05;
uniform float shadow_lift_hi : hint_range(0.0, 1.0) = 0.42;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec3 c = tex.rgb;

	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	// Protect highlights: above the guard, fade the grade back to identity.
	float hl = smoothstep(highlight_guard - guard_softness, highlight_guard, lum);

	// Protect saturated pixels (flower petals): fade the grade back above the
	// saturation guard. Guard >= 1.0 disables this (nothing reaches it).
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = mx > 0.0001 ? (mx - mn) / mx : 0.0;
	float sg = smoothstep(saturation_guard - 0.1, saturation_guard, sat);

	float protect = clamp(max(hl, sg), 0.0, 1.0);
	vec3 graded = c * tonal_mul;
	c = mix(graded, c, protect);

	// Shadow-lift (de-contrast): the darker the pixel, the more it lifts toward the
	// warm scene key, ramping to zero by shadow_lift_hi so mid/high plaster is
	// untouched. This raises dark roofs/timbers into the shared key.
	float shade = 1.0 - smoothstep(shadow_lift_lo, shadow_lift_hi, lum);
	c += shadow_lift * shade * shadow_lift_tint;

	// Apply the per-item modulate exactly once (NOT the texture-carrying COLOR).
	COLOR = vec4(min(c, vec3(1.0)), tex.a) * item_modulate;
}
