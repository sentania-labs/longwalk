shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_tex : source_color, repeat_enable;
uniform sampler2D dirt_tex : source_color, repeat_enable;
uniform float door_x = 1.5;
uniform vec2 tree_center = vec2(-4.7, 1.6);
uniform vec2 cottage_center = vec2(1.5, -3.0);
varying vec3 world_pos;
void vertex() { world_pos = VERTEX; }
void fragment() {
    vec2 p = world_pos.xz;
    float bend = sin(p.x * 0.35) * 0.55 + 3.5;
    float edge = sin(p.x * 2.7 + p.y * 1.3) * 0.15 + sin(p.y * 5.1 + p.x) * 0.10;
    float street = abs(p.y - bend) - 0.72;
    float doorstep = max(abs(p.x - door_x + sin(p.y * 0.7) * 0.15) - 0.8, max(p.y - 3.5, -p.y - 2.0));
    float yard = length((p - vec2(door_x, 1.1)) * vec2(0.7, 1.0)) - 1.0;
    float roots = length((p - tree_center) * vec2(1.0, 0.85)) - 0.5;
    float paths = min(street, min(doorstep, min(yard, roots)));
    float dirt = 1.0 - smoothstep(-0.18, 0.5, paths + edge);
    vec3 grass = texture(grass_tex, p * 0.26).rgb;
    vec3 soil = texture(dirt_tex, p * 0.3).rgb;
    float grain = dot(grass, vec3(0.299, 0.587, 0.114));
    float patches = 0.92 + 0.08 * sin(p.x * 0.51 + sin(p.y * 0.43)) * cos(p.y * 0.6);
    vec3 meadow = mix(vec3(0.14, 0.19, 0.07), vec3(0.35, 0.39, 0.18), grain) * patches;
    ALBEDO = mix(meadow, soil * vec3(0.73, 0.65, 0.51), dirt);
    ROUGHNESS = 1.0;
}
