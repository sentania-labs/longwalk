extends Control
const LAND=preload("res://src/sim/landscape.gd")
var world:Node3D
const SIZE:=220.0
func _ready() -> void:
 custom_minimum_size=Vector2(SIZE,SIZE+28)
 size=custom_minimum_size
 mouse_filter=Control.MOUSE_FILTER_STOP
 tooltip_text="Region map: click to move the camera. Space returns to the traveler."
func point(p:Vector2)->Vector2:
 return (p+Vector2.ONE*512)/1024*SIZE
func _process(_delta:float)->void: queue_redraw()
func _draw()->void:
 draw_style_box(_style(),Rect2(Vector2(-6,-6),Vector2(SIZE+12,SIZE+40)))
 draw_rect(Rect2(Vector2.ZERO,Vector2.ONE*SIZE),Color("596348"))
 for f in LAND.FARMS: draw_rect(Rect2(point(f.position),f.size/1024*SIZE),Color("a29656"))
 for r in LAND.ROADS: draw_line(point(Vector2(r.x,r.y)),point(Vector2(r.z,r.w)),Color("c3b58b"),1.5)
 var main:=PackedVector2Array()
 for z in range(-512,513,8): main.append(point(Vector2(LAND.river_x(z),z)))
 draw_polyline(main,Color("5c9da3"),3)
 var stream:=PackedVector2Array()
 for x in range(-512,90,8): stream.append(point(Vector2(x,LAND.tributary_z(x))))
 draw_polyline(stream,Color("5c9da3"),2)
 draw_circle(point(Vector2.ZERO),5,Color("e6d2a2"))
 if world and world.avatar:
  draw_circle(point(Vector2(world.avatar.position.x,world.avatar.position.z)),3.5,Color("fce69a"))
  var pos:=point(Vector2(world.focus.x,world.focus.z))
  draw_arc(pos,7,0,TAU,24,Color.WHITE,1.5)
 draw_string(ThemeDB.fallback_font,Vector2(5,SIZE+21),"REGION   1,024 × 1,024 m",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e7dfc7"))
func _style()->StyleBoxFlat:
 var s:=StyleBoxFlat.new();s.bg_color=Color("18231e");s.set_corner_radius_all(8);return s
func _gui_input(event:InputEvent)->void:
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and event.position.y<SIZE:
  var p:Vector2=event.position/SIZE*1024-Vector2.ONE*512
  if world.inspecting: world._set_inspection(false)
  world._set_follow(false)
  world.pan_velocity=Vector3.ZERO
  world.focus_target=Vector3(clampf(p.x,-495,495),1.2,clampf(p.y,-495,495))
  world.status_label.text="Region view moved. Space returns to the traveler."
  accept_event()
