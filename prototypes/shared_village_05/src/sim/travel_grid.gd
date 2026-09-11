extends AStarGrid2D

# Shared by any traveler. No rendering, input or camera dependencies.
const LAND = preload("res://src/sim/landscape.gd")
var prefer_paths := true
var costs := PackedFloat32Array()

func prepare(footprints: Array[Rect2]) -> void:
	region = Rect2i(0, 0, 1024, 1024)
	cell_size = Vector2.ONE
	diagonal_mode = DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	update()
	costs.resize(1024 * 1024)
	costs.fill(2.5)
	for field in LAND.FARMS:
		paint_cost(field, 4.0)
	for road in LAND.ROADS:
		var start := Vector2(road.x, road.y)
		var finish := Vector2(road.z, road.w)
		var steps := ceili(start.distance_to(finish) * 2)
		for i in range(steps + 1):
			var center := start.lerp(finish, float(i) / maxi(steps, 1))
			for dz in range(-2, 3):
				for dx in range(-2, 3):
					var p := Vector2i(center.round()) + Vector2i(dx, dz)
					if Vector2(p).distance_to(center) <= 1.8:
						var id := p + Vector2i(512, 512)
						if is_in_boundsv(id): costs[id.y * 1024 + id.x] = 1.0
	paint_cost(Rect2(-10, -10, 20, 20), 1.0)
	for z in range(-512, 512):
		var center := roundi(LAND.river_x(z))
		for x in range(center - 8, center + 9):
			block_water(Vector2(x, z))
	for x in range(-512, 110):
		var center := roundi(LAND.tributary_z(x))
		for z in range(center - 5, center + 6): block_water(Vector2(x, z))
	for rect in footprints: block_rect(rect)
	for rect in LAND.field_barriers(): block_rect(rect)

func paint_cost(rect: Rect2, cost: float) -> void:
	var start := Vector2i(rect.position.ceil()) + Vector2i(512, 512)
	var end := Vector2i(rect.end.floor()) + Vector2i(512, 512)
	for y in range(maxi(0, start.y), mini(1023, end.y) + 1):
		for x in range(maxi(0, start.x), mini(1023, end.x) + 1): costs[y * 1024 + x] = cost

func block_water(p: Vector2) -> void:
	var id := Vector2i(p) + Vector2i(512, 512)
	if is_in_boundsv(id) and LAND.water(p) and not LAND.crossing(p): set_point_solid(id)

func block_rect(rect: Rect2) -> void:
	var start := Vector2i((rect.position + Vector2.ONE * 512).ceil())
	var end := Vector2i((rect.end + Vector2.ONE * 512).floor())
	var blocked := Rect2i(start, end - start + Vector2i.ONE).intersection(region)
	if blocked.has_area(): fill_solid_region(blocked, true)

func _compute_cost(from_id: Vector2i, to_id: Vector2i) -> float:
	return Vector2(from_id).distance_to(Vector2(to_id)) * (costs[to_id.y * 1024 + to_id.x] if prefer_paths else 1.0)

func _estimate_cost(from_id: Vector2i, to_id: Vector2i) -> float:
	return Vector2(from_id).distance_to(Vector2(to_id))
