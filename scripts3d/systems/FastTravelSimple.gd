extends Node3D

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
var current_point: TravelPoint = null

signal travel_point_discovered(point: TravelPoint)
signal travel_started(destination: TravelPoint)
signal travel_completed(destination: TravelPoint)

func _ready() -> void:
	_initialize_travel_points()

func _initialize_travel_points() -> void:
	var point1 = TravelPoint.new("forest_center", "Forest Center", Vector3(0, 0, 0))
	point1.discovered = true

	var point2 = TravelPoint.new("village", "Village", Vector3(100, 0, 100))
	var point3 = TravelPoint.new("temple", "Temple", Vector3(-150, 0, 50))
	var point4 = TravelPoint.new("mountains", "Mountains", Vector3(200, 50, -200))
	var point5 = TravelPoint.new("river", "Sacred River", Vector3(0, 0, -200))

	travel_points = [point1, point2, point3, point4, point5]
	current_point = point1

func discover_point(point_id: String) -> bool:
	for point in travel_points:
		if point.id == point_id and not point.discovered:
			point.discovered = true
			travel_point_discovered.emit(point)
			print("🗺️ Discovered: %s" % point.name)
			return true
	return false

func travel_to(point_id: String, player: Node3D) -> bool:
	for point in travel_points:
		if point.id == point_id and point.discovered:
			travel_started.emit(point)

			await get_tree().create_timer(1.0).timeout

			player.global_position = point.position
			current_point = point

			travel_completed.emit(point)
			print("✨ Traveled to: %s" % point.name)
			return true

	return false

func get_discovered_points() -> Array[TravelPoint]:
	var discovered: Array[TravelPoint] = []
	for point in travel_points:
		if point.discovered:
			discovered.append(point)
	return discovered

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
