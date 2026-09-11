shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_tex : source_color, repeat_enable;
uniform sampler2D dirt_tex : source_color, repeat_enable;
varying vec3 world_pos;
void vertex() { world_pos = VERTEX; }
void fragment() {
    vec2 p = world_pos.xz;
    float bend = sin(p.x * 0.35) * 0.45;
    float edge = sin(p.x * 2.7 + p.y * 1.3) * 0.12 + sin(p.y * 5.1) * 0.06;
    float street = abs(p.y - bend) - 1.05;
    float branch_a = max(abs(p.x + 5.0) - 0.85, max(p.y + 0.2, -p.y - 5.0));
    float branch_b = max(abs(p.x - 5.0) - 0.85, max(-p.y + 0.1, p.y - 4.0));
    float paths = min(street, min(branch_a, branch_b));
    float dirt = 1.0 - smoothstep(-0.12, 0.35, paths + edge);
    vec3 grass = texture(grass_tex, p * 0.26).rgb;
    vec3 soil = texture(dirt_tex, p * 0.3).rgb;
    float grain = dot(grass, vec3(0.299, 0.587, 0.114));
    vec3 meadow = mix(vec3(0.12, 0.20, 0.065), vec3(0.37, 0.44, 0.20), grain);
    ALBEDO = mix(meadow, soil * vec3(0.68, 0.60, 0.46), dirt);
    ROUGHNESS = 1.0;
}
