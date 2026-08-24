extends BaseSystemSimple

class_name FastTravelSimple

class TravelPoint:
	var id: String
	var name: String
	var position: Vector3
	var discovered: bool = false
	var travel_cost: float = 50.0
	var travel_time: float = 1.0
	var level_requirement: int = 1
	var danger_level: int = 0
	var is_safe_point: bool = false
	var connected_points: Array[String] = []
	var travel_encounters: Array[String] = []
	var restriction: String = ""
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
	set_state("travel_cooldowns", {})
	set_state("total_travels", 0)
	set_state("travel_encounters_log", [])
	set_state("discovered_routes", [])
	_initialize_travel_points()

func _initialize_travel_points() -> void:
	var point1 = TravelPoint.new("forest_center", "Forest Center", Vector3(0, 0, 0))
	point1.discovered = true
	point1.is_safe_point = true
	point1.travel_cost = 0.0

	var point2 = TravelPoint.new("village", "Village", Vector3(100, 0, 100))
	point2.travel_cost = 50.0
	point2.travel_time = 2.0
	point2.level_requirement = 1
	point2.is_safe_point = true

	var point3 = TravelPoint.new("temple", "Temple", Vector3(-150, 0, 50))
	point3.travel_cost = 75.0
	point3.travel_time = 3.0
	point3.level_requirement = 3
	point3.danger_level = 1
	point3.travel_encounters = ["wandering_spirit", "temple_guardian"]

	var point4 = TravelPoint.new("mountains", "Mountains", Vector3(200, 50, -200))
	point4.travel_cost = 100.0
	point4.travel_time = 4.0
	point4.level_requirement = 5
	point4.danger_level = 2
	point4.travel_encounters = ["mountain_beast", "avalanche_warning"]

	var point5 = TravelPoint.new("river", "Sacred River", Vector3(0, 0, -200))
	point5.travel_cost = 60.0
	point5.travel_time = 2.5
	point5.level_requirement = 2
	point5.danger_level = 1
	point5.is_safe_point = true

	travel_points = [point1, point2, point3, point4, point5]
	set_state("current_id", "forest_center")

func discover_point(point_id: String) -> bool:
	for point in travel_points:
		if point.id == point_id and not point.discovered:
			point.discovered = true
			travel_point_discovered.emit(point)
			emit_event("discovered", point_id)
			return true
	return false

func travel_to(point_id: String, player: Node3D, player_level: int = 1, available_gold: float = 0.0) -> bool:
	for point in travel_points:
		if point.id == point_id and point.discovered:
			if player_level < point.level_requirement:
				return false
			if available_gold < point.travel_cost:
				return false
			var cooldowns = get_state("travel_cooldowns", {})
			if point_id in cooldowns:
				var last_travel = cooldowns[point_id]
				if (Time.get_ticks_msec() - last_travel) < 5000:
					return false
			travel_started.emit(point)
			await get_tree().create_timer(point.travel_time).timeout
			if not point.is_safe_point and randf() < (0.1 * point.danger_level):
				_trigger_travel_encounter(point)
			player.global_position = point.position
			set_state("current_id", point_id)
			cooldowns[point_id] = Time.get_ticks_msec()
			set_state("travel_cooldowns", cooldowns)
			var total = get_state("total_travels", 0) + 1
			set_state("total_travels", total)
			travel_completed.emit(point)
			emit_event("traveled", {"destination": point_id, "cost": point.travel_cost, "time": point.travel_time})
			return true
	return false

func _trigger_travel_encounter(point: TravelPoint) -> void:
	if point.travel_encounters.size() > 0:
		var encounter = point.travel_encounters[randi() % point.travel_encounters.size()]
		var log = get_state("travel_encounters_log", [])
		log.append({"encounter": encounter, "location": point.id})
		set_state("travel_encounters_log", log)
		emit_event("encounter_triggered", {"type": encounter, "location": point.id})

func get_discovered_points() -> Array:
	return travel_points.filter(func(p): return p.discovered)

func get_all_points() -> Array[TravelPoint]:
	return travel_points

func get_travel_point(point_id: String) -> TravelPoint:
	for point in travel_points:
		if point.id == point_id:
			return point
	return null

func get_travel_point_info(point_id: String) -> String:
	var point = get_travel_point(point_id)
	if not point:
		return "Unknown point"
	var safe = " [SAFE]" if point.is_safe_point else " [Level %d+]" % point.level_requirement
	var danger = " ★%d" % point.danger_level if point.danger_level > 0 else ""
	return "%s%s%s | Cost: %.0f | Time: %.1fs" % [point.name, safe, danger, point.travel_cost, point.travel_time]

func get_travel_text() -> String:
	var discovered = get_discovered_points()
	var total_travels = get_state("total_travels", 0)
	var text = "Travel Points: %d/%d | Travels: %d\n" % [discovered.size(), travel_points.size(), total_travels]
	for point in discovered:
		var status = "✓"
		var danger = " ★%d" % point.danger_level if point.danger_level > 0 else ""
		text += "%s %s (%.0f gold)%s\n" % [status, point.name, point.travel_cost, danger]
	return text
