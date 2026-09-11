shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D soil_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
    return mix(mix(hash(i),hash(i+vec2(1,0)),f.x), mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
// Overlapping independent samples hide texture borders and obvious repeat blocks.
vec3 surface(sampler2D tex, vec2 p) {
    vec2 cell = floor(p); vec2 f = fract(p); vec2 w = smoothstep(0.0,1.0,f);
    vec3 a = texture(tex,p + vec2(hash(cell),hash(cell+17.0))*7.0).rgb;
    vec3 b = texture(tex,p + vec2(hash(cell+vec2(1,0)),hash(cell+vec2(1,0)+17.0))*7.0).rgb;
    vec3 c = texture(tex,p + vec2(hash(cell+vec2(0,1)),hash(cell+vec2(0,1)+17.0))*7.0).rgb;
    vec3 d = texture(tex,p + vec2(hash(cell+1.0),hash(cell+18.0))*7.0).rgb;
    return mix(mix(a,b,w.x),mix(c,d,w.x),w.y);
}
float segment(vec2 p, vec2 a, vec2 b) {
    vec2 v=b-a; return length(p-a-v*clamp(dot(p-a,v)/dot(v,v),0.0,1.0));
}
float box_distance(vec2 p, vec2 center, vec2 half_size) {
    vec2 q=abs(p-center)-half_size;
    return length(max(q,vec2(0)))+min(max(q.x,q.y),0.0);
}
void vertex() { world_pos = VERTEX; }
void fragment() {
    vec2 p=world_pos.xz;
    float ragged=(noise(p*3.8)-0.5)*0.30+(noise(p*1.1)-0.5)*0.55;
    float lane=abs(p.y-(1.9+sin(p.x*0.19)*0.55))-0.95;
    float door1=segment(p,vec2(-8,-1.5),vec2(-8,2))-0.65;
    float door2=segment(p,vec2(1.8,-1.4),vec2(2.2,2.2))-0.70;
    float door3=segment(p,vec2(10,4.4),vec2(10,2.4))-0.70;
    float paths=min(lane,min(door1,min(door2,door3)));
    float worn=1.0-smoothstep(-0.1,0.65,paths+ragged);
    float roots=min(length(p-vec2(-14,0))-1.6,min(length(p-vec2(-2,7.5))-1.5,length(p-vec2(12,-7.5))-1.6));
    float foundations=min(box_distance(p,vec2(-8,-4.5),vec2(3.2,3.0)),min(box_distance(p,vec2(3,-4.5),vec2(4.65,3.3)),box_distance(p,vec2(10,7.5),vec2(3.2,3.0))));
    float soil=1.0-smoothstep(-0.15,0.95,min(roots,foundations)+ragged);
    vec3 meadow=surface(grass_tex,p*0.38)*vec3(0.84,0.94,0.76);
    meadow = mix(meadow,vec3(0.16,0.20,0.08),0.3);
    meadow *= mix(0.90,1.08,noise(p*0.21));
    vec3 earth=surface(dirt_tex,p*0.4)*vec3(0.94,0.88,0.76);
    vec3 humus=surface(soil_tex,p*0.55)*vec3(0.84,0.90,0.74);
    ALBEDO=mix(mix(meadow,humus,soil*0.82),earth,worn*0.93);
    ROUGHNESS=1.0;
}
