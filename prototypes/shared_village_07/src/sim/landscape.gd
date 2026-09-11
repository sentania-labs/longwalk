class_name RiverLandscape
extends RefCounted

# Frozen authored map description. Coordinate sampling is order independent.
const HALF_SIZE := 512.0
const BRIDGES := [15.0, -175.0, 245.0]
const FARMS := [Rect2(-155,-70,64,45), Rect2(-155,-14,60,48), Rect2(-92,90,65,42), Rect2(-15,100,56,45), Rect2(140,45,60,60), Rect2(210,50,50,50), Rect2(140,-200,65,55), Rect2(-245,180,65,55)]
const ROADS := [Vector4(-480,-75,-350,-22), Vector4(-350,-22,-210,15), Vector4(-210,15,-165,15), Vector4(-165,15,-165,-20), Vector4(-165,-20,-85,-20), Vector4(-85,-20,-60,15), Vector4(-60,15,0,8), Vector4(0,8,40,15), Vector4(40,15,85,15), Vector4(85,15,140,15), Vector4(140,15,240,35), Vector4(240,35,330,25), Vector4(330,25,480,90), Vector4(0,8,-20,-60), Vector4(-20,-60,0,-110), Vector4(0,-110,0,-175), Vector4(0,-175,-30,-280), Vector4(-30,-280,35,-420), Vector4(0,8,-7,75), Vector4(-7,75,-21,83), Vector4(-21,83,-21,152), Vector4(-21,152,0,165), Vector4(0,165,0,245), Vector4(0,245,30,340), Vector4(30,340,-10,460), Vector4(-165,-20,-165,-77), Vector4(-165,-77,-102,-77), Vector4(-123,-77,-123,-71), Vector4(-165,10,-156,10), Vector4(-21,140,-70,140), Vector4(-70,140,-70,133), Vector4(-21,120,-16,120), Vector4(135,14,130,115), Vector4(130,115,180,115), Vector4(130,75,139,75), Vector4(240,35,240,49), Vector4(0,-175,130,-175), Vector4(130,-175,130,-207), Vector4(130,-207,190,-207), Vector4(172,-207,172,-201), Vector4(0,245,170,245), Vector4(-165,15,-170,85), Vector4(-170,85,-195,148), Vector4(-195,148,-253,170), Vector4(-253,170,-253,240), Vector4(-253,240,-215,240), Vector4(-253,210,-246,210)]

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

# One 5m gateway per field. x is east/west, y is north/south.
const GATES := [Vector2(-123,-71), Vector2(-156,10), Vector2(-70,133), Vector2(-16,120), Vector2(139,75), Vector2(240,49), Vector2(172,-201), Vector2(-246,210)]

static func field_barriers() -> Array[Rect2]:
 var result: Array[Rect2] = []
 for i in range(FARMS.size()):
  var field: Rect2 = FARMS[i].grow(1)
  var gate: Vector2 = GATES[i]
  for side in [Vector4(field.position.x,field.position.y,field.end.x,field.position.y), Vector4(field.position.x,field.end.y,field.end.x,field.end.y), Vector4(field.position.x,field.position.y,field.position.x,field.end.y), Vector4(field.end.x,field.position.y,field.end.x,field.end.y)]:
   var a := Vector2(side.x,side.y)
   var b := Vector2(side.z,side.w)
   if segment_distance(gate,a,b) < 0.1:
    var direction := (b-a).normalized()
    result.append(Rect2(a,gate-direction*2.5-a).abs().grow(0.45))
    result.append(Rect2(gate+direction*2.5,b-gate-direction*2.5).abs().grow(0.45))
   else:
    result.append(Rect2(a,b-a).abs().grow(0.45))
 return result
