shader_type canvas_item;

uniform vec3 base_color : source_color = vec3(0.24, 0.22, 0.09);
uniform float radius_px : hint_range(0.5, 4.0) = 2.4;
uniform float strength : hint_range(0.0, 0.5) = 0.24;

float local_noise(vec2 pixel) {
	vec2 cell = floor(pixel * 0.37);
	return fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 step_uv = TEXTURE_PIXEL_SIZE * radius_px;
	float core = texture(TEXTURE, UV).a;
	float spread = max(max(texture(TEXTURE, UV + vec2(step_uv.x, 0.0)).a,
		texture(TEXTURE, UV - vec2(step_uv.x, 0.0)).a),
		max(texture(TEXTURE, UV + vec2(0.0, step_uv.y)).a,
		texture(TEXTURE, UV - vec2(0.0, step_uv.y)).a));
	float outer = max(spread - core * 0.45, 0.0);
	float broken = mix(0.55, 1.0, local_noise(UV / TEXTURE_PIXEL_SIZE));
	COLOR = vec4(base_color, outer * broken * strength);
}
