extends BaseSystemSimple

class_name PathfindingSimple

class Waypoint:
	var id: String
	var position: Vector3
	var connections: Array[String]
	func _init(p_id: String, p_pos: Vector3) -> void:
		id = p_id
		position = p_pos
		connections = []

var waypoints: Dictionary = {}
var waypoint_graph: Dictionary = {}

signal path_found(path: Array[Vector3])
signal path_failed(destination: Vector3)

func _ready() -> void:
	_initialize_waypoints()

func _initialize_waypoints() -> void:
	waypoints = {
		"w1": Waypoint.new("w1", Vector3(0, 0, 0)),
		"w2": Waypoint.new("w2", Vector3(50, 0, 50)),
		"w3": Waypoint.new("w3", Vector3(100, 0, 0)),
		"w4": Waypoint.new("w4", Vector3(-50, 0, 50)),
		"w5": Waypoint.new("w5", Vector3(0, 0, 100)),
		"w6": Waypoint.new("w6", Vector3(50, 0, -50))
	}
	
	waypoints["w1"].connections = ["w2", "w4", "w6"]
	waypoints["w2"].connections = ["w1", "w3", "w5"]
	waypoints["w3"].connections = ["w2", "w6"]
	waypoints["w4"].connections = ["w1", "w5"]
	waypoints["w5"].connections = ["w2", "w4"]
	waypoints["w6"].connections = ["w1", "w3"]

func find_path(start_pos: Vector3, end_pos: Vector3) -> Array[Vector3]:
	var start = _get_nearest_waypoint(start_pos)
	var end = _get_nearest_waypoint(end_pos)
	
	if start and end:
		var path = _bfs_path(start.id, end.id)
		if not path.is_empty():
			var waypoint_positions = []
			for waypoint_id in path:
				waypoint_positions.append(waypoints[waypoint_id].position)
			path_found.emit(waypoint_positions)
			emit_event("path_found", "")
			return waypoint_positions
	
	path_failed.emit(end_pos)
	emit_event("path_failed", "")
	return []

func add_waypoint(waypoint_id: String, position: Vector3) -> void:
	waypoints[waypoint_id] = Waypoint.new(waypoint_id, position)
	emit_event("waypoint_added", waypoint_id)

func connect_waypoints(waypoint_a: String, waypoint_b: String) -> void:
	if waypoint_a in waypoints and waypoint_b in waypoints:
		if waypoint_b not in waypoints[waypoint_a].connections:
			waypoints[waypoint_a].connections.append(waypoint_b)
		if waypoint_a not in waypoints[waypoint_b].connections:
			waypoints[waypoint_b].connections.append(waypoint_a)
		emit_event("waypoints_connected", waypoint_a)

func get_waypoint(waypoint_id: String) -> Waypoint:
	return waypoints.get(waypoint_id, null)

func get_nearest_waypoint(position: Vector3) -> Waypoint:
	return _get_nearest_waypoint(position)

func _get_nearest_waypoint(position: Vector3) -> Waypoint:
	var nearest: Waypoint = null
	var min_distance = INF
	for waypoint in waypoints.values():
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
			if neighbor not in visited:
				visited[neighbor] = true
				queue.append(path + [neighbor])
	
	return []

func get_pathfinding_text() -> String:
	return "Pathfinding\nWaypoints: %d\nConnections: active" % waypoints.size()
