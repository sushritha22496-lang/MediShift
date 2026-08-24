extends BaseSystemSimple

class_name FastTravelSimple

class TravelPoint:
	var id: String
	var name: String
	var position: Vector3
	var discovered: bool = false
	func _init(p_id: String, p_name: String, p_pos: Vector3) -> void:
		id = p_id
		name = p_name
		position = p_pos

var travel_points: Array[TravelPoint] = []

signal travel_point_discovered(point: TravelPoint)
signal travel_started(destination: TravelPoint)
signal travel_completed(destination: TravelPoint)

func _ready() -> void:
	set_state("current_id", "")
	_initialize_travel_points()

func _initialize_travel_points() -> void:
	var point1 = TravelPoint.new("forest_center", "Forest Center", Vector3(0, 0, 0))
	point1.discovered = true

	travel_points = [
		point1,
		TravelPoint.new("village", "Village", Vector3(100, 0, 100)),
		TravelPoint.new("temple", "Temple", Vector3(-150, 0, 50)),
		TravelPoint.new("mountains", "Mountains", Vector3(200, 50, -200)),
		TravelPoint.new("river", "Sacred River", Vector3(0, 0, -200))
	]
	set_state("current_id", "forest_center")

func discover_point(point_id: String) -> bool:
	for point in travel_points:
		if point.id == point_id and not point.discovered:
			point.discovered = true
			travel_point_discovered.emit(point)
			emit_event("discovered", point_id)
			return true
	return false

func travel_to(point_id: String, player: Node3D) -> bool:
	for point in travel_points:
		if point.id == point_id and point.discovered:
			travel_started.emit(point)
			await get_tree().create_timer(1.0).timeout
			player.global_position = point.position
			set_state("current_id", point_id)
			travel_completed.emit(point)
			emit_event("traveled", point_id)
			return true
	return false

func get_discovered_points() -> Array:
	return travel_points.filter(func(p): return p.discovered)

func get_all_points() -> Array[TravelPoint]:
	return travel_points

func get_travel_point(point_id: String) -> TravelPoint:
	for point in travel_points:
		if point.id == point_id:
			return point
	return null

func get_travel_text() -> String:
	var text = "Fast Travel Points:\n"
	for point in travel_points:
		var status = "✓" if point.discovered else "?"
		text += "%s %s\n" % [status, point.name]
	return text
