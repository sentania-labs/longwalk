shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_pos;
float river_x(float z) { return 85.0+14.0*sin(z*0.012)+6.0*sin(z*0.033); }
float tributary_z(float x) { return -110.0+12.0*sin(x*0.017); }
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_pos.xz;
 float main=abs(p.x-river_x(p.y))-7.0;
 float branch=max(abs(p.y-tributary_z(p.x))-3.5,p.x-river_x(p.y));
 float bank=min(main,branch);
 if(bank>0.1) { discard; }
 float shallows=1.0-smoothstep(0.0,3.8,-bank);
 vec2 flow=main<branch ? vec2(p.x-river_x(p.y),p.y) : vec2(p.y-tributary_z(p.x),p.x);
 float ripples=noise(flow*vec2(1.7,0.22)+vec2(0.0,-TIME*0.30));
 ripples=0.65*ripples+0.35*noise(flow*vec2(3.1,0.39)+vec2(7.2,-TIME*0.21));
 vec3 deep=vec3(0.075,0.21,0.24);
 vec3 shallow=vec3(0.22,0.33,0.28);
 ALBEDO=mix(deep,shallow,shallows*0.8)+vec3(0.024,0.035,0.031)*(ripples-0.45);
 ROUGHNESS=0.34;
 SPECULAR=0.45;
}
