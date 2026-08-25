extends BaseSystemSimple

class_name PathfindingSimple

class Waypoint:
	var id: String
	var position: Vector3
	var connections: Array[String]
	var region: String = "default"
	var cost: float = 1.0
	var traversable: bool = true
	var danger_level: int = 0
	func _init(p_id: String, p_pos: Vector3) -> void:
		id = p_id
		position = p_pos
		connections = []

var waypoints: Dictionary = {}
var waypoint_graph: Dictionary = {}
var path_cache: Dictionary = {}

signal path_found(path: Array[Vector3])
signal path_failed(destination: Vector3)
signal waypoint_reached(waypoint_id: String)
signal path_recalculated(reason: String)

func _ready() -> void:
	set_state("path_calculations", 0)
	set_state("cache_hits", 0)
	set_state("cache_misses", 0)
	set_state("obstacles", [])
	set_state("pathfinding_history", [])
	_initialize_waypoints()

func _initialize_waypoints() -> void:
	var w1 = Waypoint.new("w1", Vector3(0, 0, 0))
	w1.region = "forest"
	var w2 = Waypoint.new("w2", Vector3(50, 0, 50))
	w2.region = "forest"
	var w3 = Waypoint.new("w3", Vector3(100, 0, 0))
	w3.region = "grassland"
	var w4 = Waypoint.new("w4", Vector3(-50, 0, 50))
	w4.region = "forest"
	var w5 = Waypoint.new("w5", Vector3(0, 0, 100))
	w5.region = "grassland"
	var w6 = Waypoint.new("w6", Vector3(50, 0, -50))
	w6.region = "mountain"
	w6.danger_level = 2
	waypoints = {"w1": w1, "w2": w2, "w3": w3, "w4": w4, "w5": w5, "w6": w6}
	waypoints["w1"].connections = ["w2", "w4", "w6"]
	waypoints["w2"].connections = ["w1", "w3", "w5"]
	waypoints["w3"].connections = ["w2", "w6"]
	waypoints["w4"].connections = ["w1", "w5"]
	waypoints["w5"].connections = ["w2", "w4"]
	waypoints["w6"].connections = ["w1", "w3"]

func find_path(start_pos: Vector3, end_pos: Vector3, use_cache: bool = true) -> Array[Vector3]:
	var start = _get_nearest_waypoint(start_pos)
	var end = _get_nearest_waypoint(end_pos)
	if not start or not end:
		path_failed.emit(end_pos)
		return []
	var cache_key = "%s_to_%s" % [start.id, end.id]
	if use_cache and cache_key in path_cache:
		var cached = get_state("cache_hits", 0)
		set_state("cache_hits", cached + 1)
		emit_event("path_cache_hit", cache_key)
		return path_cache[cache_key]
	var cache_misses = get_state("cache_misses", 0)
	set_state("cache_misses", cache_misses + 1)
	var calc_count = get_state("path_calculations", 0)
	set_state("path_calculations", calc_count + 1)
	var path = _bfs_path(start.id, end.id)
	if not path.is_empty():
		var waypoint_positions = []
		var path_cost = 0.0
		for i in range(path.size()):
			var waypoint_id = path[i]
			waypoint_positions.append(waypoints[waypoint_id].position)
			if i > 0:
				var prev_waypoint = waypoints[path[i-1]]
				path_cost += waypoint_positions[i].distance_to(waypoint_positions[i-1])
		path_cache[cache_key] = waypoint_positions
		var history = get_state("pathfinding_history", [])
		history.append({"start": start.id, "end": end.id, "cost": path_cost, "length": path.size(), "timestamp": Time.get_ticks_msec()})
		if history.size() > 100:
			history.pop_front()
		set_state("pathfinding_history", history)
		path_found.emit(waypoint_positions)
		emit_event("path_found", {"cost": path_cost, "waypoints": path.size()})
		return waypoint_positions
	path_failed.emit(end_pos)
	emit_event("path_failed", {"start": start.id, "end": end.id})
	return []

func add_waypoint(waypoint_id: String, position: Vector3, region: String = "default") -> void:
	var waypoint = Waypoint.new(waypoint_id, position)
	waypoint.region = region
	waypoints[waypoint_id] = waypoint
	_clear_path_cache()
	emit_event("waypoint_added", waypoint_id)

func connect_waypoints(waypoint_a: String, waypoint_b: String) -> void:
	if waypoint_a in waypoints and waypoint_b in waypoints:
		if waypoint_b not in waypoints[waypoint_a].connections:
			waypoints[waypoint_a].connections.append(waypoint_b)
		if waypoint_a not in waypoints[waypoint_b].connections:
			waypoints[waypoint_b].connections.append(waypoint_a)
		_clear_path_cache()
		emit_event("waypoints_connected", waypoint_a)

func add_obstacle(obstacle_id: String, position: Vector3, radius: float = 5.0) -> void:
	var obstacles = get_state("obstacles", [])
	obstacles.append({"id": obstacle_id, "position": position, "radius": radius})
	set_state("obstacles", obstacles)
	_clear_path_cache()
	emit_event("obstacle_added", obstacle_id)

func remove_obstacle(obstacle_id: String) -> void:
	var obstacles = get_state("obstacles", [])
	obstacles = obstacles.filter(func(o): return o["id"] != obstacle_id)
	set_state("obstacles", obstacles)
	_clear_path_cache()
	emit_event("obstacle_removed", obstacle_id)

func _clear_path_cache() -> void:
	path_cache.clear()
	set_state("cache_hits", 0)
	set_state("cache_misses", 0)

func get_waypoint(waypoint_id: String) -> Waypoint:
	return waypoints.get(waypoint_id, null)

func get_nearest_waypoint(position: Vector3) -> Waypoint:
	return _get_nearest_waypoint(position)

func get_waypoints_by_region(region: String) -> Array[Waypoint]:
	var result: Array[Waypoint] = []
	for waypoint in waypoints.values():
		if waypoint.region == region:
			result.append(waypoint)
	return result

func get_path_statistics() -> Dictionary:
	return {
		"calculations": get_state("path_calculations", 0),
		"cache_hits": get_state("cache_hits", 0),
		"cache_misses": get_state("cache_misses", 0),
		"cache_size": path_cache.size(),
		"total_waypoints": waypoints.size(),
		"obstacles_active": get_state("obstacles", []).size(),
		"paths_found_history": get_state("pathfinding_history", []).size()
	}

func get_pathfinding_history() -> Array:
	return get_state("pathfinding_history", [])

func _get_nearest_waypoint(position: Vector3) -> Waypoint:
	var nearest: Waypoint = null
	var min_distance = INF
	for waypoint in waypoints.values():
		if waypoint.traversable:
			var distance = position.distance_to(waypoint.position)
			if distance < min_distance:
				min_distance = distance
				nearest = waypoint
	return nearest

func _bfs_path(start_id: String, end_id: String) -> Array:
	var queue = [[start_id]]
	var visited = {start_id: true}
	while queue.size() > 0:
		var path = queue.pop_front()
		var current = path[-1]
		if current == end_id:
			return path
		for neighbor in waypoints[current].connections:
			if neighbor not in visited and waypoints[neighbor].traversable:
				visited[neighbor] = true
				queue.append(path + [neighbor])
	return []

func get_pathfinding_text() -> String:
	var stats = get_path_statistics()
	var text = "Pathfinding: %d waypoints | Cache: %d (hits: %d)\n" % [waypoints.size(), stats["cache_size"], stats["cache_hits"]]
	text += "Calcs: %d | Obstacles: %d" % [stats["calculations"], get_state("obstacles", []).size()]
	return text
