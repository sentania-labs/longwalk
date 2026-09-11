class_name RiverLandscape
extends RefCounted

# Frozen authored map description. Coordinate sampling is order independent.
const HALF_SIZE := 512.0
const BRIDGES := [15.0, -175.0, 245.0]
const FARMS := [Rect2(-155,-70,64,45), Rect2(-155,-14,60,48), Rect2(-92,90,65,42), Rect2(-15,100,56,45), Rect2(140,45,60,60), Rect2(210,50,50,50), Rect2(140,-200,65,55), Rect2(-245,180,65,55)]
const ROADS := [Vector4(-480,-75,-350,-22), Vector4(-350,-22,-210,15), Vector4(-210,15,-60,15), Vector4(-60,15,0,8), Vector4(0,8,40,15), Vector4(40,15,85,15), Vector4(85,15,140,15), Vector4(140,15,240,45), Vector4(240,45,330,25), Vector4(330,25,480,90), Vector4(0,8,-20,-60), Vector4(-20,-60,0,-110), Vector4(0,-110,0,-175), Vector4(0,-175,-30,-280), Vector4(-30,-280,35,-420), Vector4(0,8,-7,75), Vector4(-7,75,0,140), Vector4(0,140,0,245), Vector4(0,245,30,340), Vector4(30,340,-10,460), Vector4(-130,15,-130,-85), Vector4(-3,120,-95,120), Vector4(175,26,175,120), Vector4(0,-175,210,-175), Vector4(0,245,170,245), Vector4(-130,15,-170,85), Vector4(-170,85,-195,148), Vector4(-195,148,-210,205)]

static func river_x(z: float) -> float:
 return 85.0 + 14.0*sin(z*0.012) + 6.0*sin(z*0.033)

static func tributary_z(x: float) -> float:
 return -110.0 + 12.0*sin(x*0.017)

static func water(point: Vector2) -> bool:
 return absf(point.x-river_x(point.y)) < 7.0 or (point.x < river_x(point.y) and absf(point.y-tributary_z(point.x)) < 3.5)

static func crossing(point: Vector2) -> bool:
 for z in BRIDGES:
  if absf(point.y-z) < 3.0 and absf(point.x-river_x(z)) < 12.0:
   return true
 # North road crosses the tributary.
 return absf(point.x) < 1.5 and absf(point.y-tributary_z(0)) < 7.0

static func segment_distance(p: Vector2,a:Vector2,b:Vector2) -> float:
 var ab := b-a
 return p.distance_to(a+ab*clampf((p-a).dot(ab)/ab.length_squared(),0,1))

static func road_distance(p:Vector2) -> float:
 var d := 10000.0
 for r in ROADS:
  d=minf(d,segment_distance(p,Vector2(r.x,r.y),Vector2(r.z,r.w)))
 return d

static func hash_cell(x:int,z:int,salt:int=0) -> float:
 # Integer hash uses only cell coordinates and a fixed layer salt.
 var n:int=(x*374761393+z*668265263+salt*1442695041)&0x7fffffff
 n=((n^(n>>13))*1274126177)&0x7fffffff
 return float(n&65535)/65535.0
