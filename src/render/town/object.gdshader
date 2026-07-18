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

uniform vec3 tonal_mul = vec3(1.0, 1.0, 1.0);
uniform float highlight_guard : hint_range(0.0, 1.0) = 1.0;
uniform float guard_softness : hint_range(0.01, 0.5) = 0.12;
uniform float saturation_guard : hint_range(0.0, 1.5) = 1.5;

void fragment() {
	vec4 mod_col = COLOR; // the incoming modulate/vertex color
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

	COLOR = vec4(c, tex.a) * mod_col;
}
