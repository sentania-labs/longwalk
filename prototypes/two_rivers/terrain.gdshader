shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D dirt_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D soil_tex : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D control_tex : repeat_disable, filter_linear;
uniform sampler2D wear_tex : repeat_disable, filter_linear;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.0),f.x),f.y);
}
float river_x(float z) { return 85.0+14.0*sin(z*0.012)+6.0*sin(z*0.033); }
float tributary_z(float x) { return -110.0+12.0*sin(x*0.017); }
float bank_distance(vec2 p) {
 float main=abs(p.x-river_x(p.y))-7.0;
 float tributary=max(abs(p.y-tributary_z(p.x))-3.5,p.x-river_x(p.y));
 return min(main,tributary);
}
// Differently scaled and rotated material samples suppress obvious repeats.
vec3 surface(sampler2D tex, vec2 p) {
 vec3 a=texture(tex,p).rgb;
 vec3 b=texture(tex,mat2(vec2(0.8,0.6),vec2(-0.6,0.8))*p*0.731+vec2(4.3,1.7)).rgb;
 return mix(a,b,0.45);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_pos.xz;
 float bank=bank_distance(p);
 if(bank<0.0) { discard; }
 vec4 control=texture(control_tex,(p+512.0)/1024.0);
 float macro=noise(p*0.028);
 vec3 meadow=surface(grass_tex,p*0.31)*vec3(0.77,0.85,0.62);
 meadow=mix(meadow,vec3(0.22,0.26,0.105),0.24);
 meadow*=mix(0.90,1.06,macro);
 vec3 earth=surface(dirt_tex,p*0.4)*vec3(0.95,0.88,0.74);
 vec3 soil=surface(soil_tex,p*0.42)*vec3(0.75,0.76,0.60);
 float woodland=smoothstep(210.0,280.0,length(p)+(noise(p*0.018)-0.5)*65.0);
 vec3 color=mix(meadow,soil,woodland*0.52);
 float meadow_breaks=smoothstep(0.61,0.82,noise(p*0.19))*0.18;
 color=mix(color,earth,meadow_breaks*(1.0-woodland));
 float row=0.5+0.5*sin(p.x*7.4)*(1.0-smoothstep(1.0,3.0,fwidth(p.x*7.4)));
 float row_detail=mix(0.83,1.08,row);
 vec3 plowed=mix(soil,vec3(0.24,0.16,0.09),0.40)*row_detail;
 vec3 grain=mix(earth,vec3(0.51,0.39,0.12),0.60)*mix(0.89,1.04,row);
 vec3 crops=mix(soil,vec3(0.20,0.28,0.095),0.75)*row_detail;
 color=mix(color,plowed,control.g);
 color=mix(color,grain,control.b);
 color=mix(color,crops,control.a);
 vec2 wear=texture(wear_tex,(p+512.0)/1024.0).rg;
 color=mix(color,soil,wear.g);
 float road=clamp(control.r+(noise(p*1.8)-0.5)*0.34*4.0*control.r*(1.0-control.r),0.0,1.0);
 color=mix(color,earth,max(road*0.96,wear.r*0.88));
 // Small staggered cobbles belong to the village square only.
 float square=1.0-smoothstep(10.5,12.5,length(p)+(noise(p*0.8)-0.5)*0.7);
 vec2 cobble=p*vec2(2.0,2.7);
 cobble.x+=mod(floor(cobble.y),2.0)*0.5;
 vec2 cell=fract(cobble);
 float mortar=1.0-smoothstep(0.015,0.10,min(min(cell.x,1.0-cell.x),min(cell.y,1.0-cell.y)));
 vec3 stone=mix(vec3(0.37,0.35,0.29),vec3(0.49,0.46,0.37),hash(floor(cobble)));
 stone=mix(stone,vec3(0.25,0.23,0.17),mortar*0.65);
 color=mix(color,stone,square*0.88);
 float wetbank=1.0-smoothstep(0.0,2.2,bank);
 color=mix(color,soil*0.73,wetbank*0.84);
 ALBEDO=color;
 ROUGHNESS=0.98;
}
