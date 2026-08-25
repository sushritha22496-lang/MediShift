extends BaseSystemSimple

class_name MapMarkerSimple

class Marker:
	var id: String
	var name: String
	var position: Vector3
	var marker_type: String
	var discovered: bool
	var description: String
	func _init(p_id: String, p_name: String, p_pos: Vector3, p_type: String = "landmark") -> void:
		id = p_id
		name = p_name
		position = p_pos
		marker_type = p_type
		discovered = false
		description = ""

var markers: Array[Marker] = []

signal marker_discovered(marker: Marker)
signal marker_visited(marker_id: String)
signal marker_pinned(marker_id: String)
signal marker_unpinned(marker_id: String)

func _ready() -> void:
	set_state("discovered_markers", [])
	set_state("pinned_markers", [])
	set_state("discovery_history", [])
	set_state("visit_history", [])
	set_state("pin_history", [])
	_initialize_markers()

func _initialize_markers() -> void:
	var types = ["landmark", "dungeon", "camp", "village", "shrine", "cave"]
	var names = ["Ancient Ruins", "Dark Cavern", "Warrior's Camp", "Monkey Village", "Sacred Shrine", "Crystal Cave"]
	var positions = [
		Vector3(100, 0, 100),
		Vector3(-100, 0, -100),
		Vector3(200, 0, -50),
		Vector3(-50, 0, 200),
		Vector3(0, 0, 150),
		Vector3(150, 0, 0)
	]

	for i in range(types.size()):
		var marker = Marker.new("marker_%d" % i, names[i], positions[i], types[i])
		markers.append(marker)

func discover_marker(marker_id: String) -> bool:
	for marker in markers:
		if marker.id == marker_id and not marker.discovered:
			marker.discovered = true
			var discovered = get_state("discovered_markers", [])
			discovered.append(marker_id)
			set_state("discovered_markers", discovered)
			var history = get_state("discovery_history", [])
			history.append({"marker": marker_id, "type": marker.marker_type, "time": Time.get_ticks_msec()})
			if history.size() > 50:
				history.pop_front()
			set_state("discovery_history", history)
			marker_discovered.emit(marker)
			emit_event("marker_discovered", marker_id)
			return true
	return false

func visit_marker(marker_id: String) -> void:
	if discover_marker(marker_id):
		var history = get_state("visit_history", [])
		history.append({"marker": marker_id, "time": Time.get_ticks_msec()})
		if history.size() > 50:
			history.pop_front()
		set_state("visit_history", history)
		marker_visited.emit(marker_id)
		emit_event("marker_visited", marker_id)

func pin_marker(marker_id: String) -> bool:
	var marker = _get_marker(marker_id)
	if marker and marker.discovered:
		var pinned = get_state("pinned_markers", [])
		if marker_id not in pinned:
			pinned.append(marker_id)
			set_state("pinned_markers", pinned)
			_record_pin_event(marker_id, true)
			marker_pinned.emit(marker_id)
			emit_event("marker_pinned", marker_id)
			return true
	return false

func unpin_marker(marker_id: String) -> bool:
	var pinned = get_state("pinned_markers", [])
	if marker_id in pinned:
		pinned.erase(marker_id)
		set_state("pinned_markers", pinned)
		_record_pin_event(marker_id, false)
		marker_unpinned.emit(marker_id)
		emit_event("marker_unpinned", marker_id)
		return true
	return false

func _record_pin_event(marker_id: String, pinned: bool) -> void:
	var history = get_state("pin_history", [])
	history.append({"marker": marker_id, "pinned": pinned, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("pin_history", history)

func set_marker_description(marker_id: String, desc: String) -> void:
	var marker = _get_marker(marker_id)
	if marker:
		marker.description = desc
		emit_event("marker_description_set", marker_id)

func get_discovered_markers() -> Array[Marker]:
	return markers.filter(func(m): return m.discovered)

func get_markers_by_type(marker_type: String) -> Array[Marker]:
	return markers.filter(func(m): return m.marker_type == marker_type)

func get_marker_distance(marker_id: String, player_pos: Vector3) -> float:
	var marker = _get_marker(marker_id)
	if marker:
		return player_pos.distance_to(marker.position)
	return -1.0

func get_nearest_marker(player_pos: Vector3) -> Marker:
	var nearest: Marker = null
	var min_dist = INF
	for marker in markers:
		if marker.discovered:
			var dist = player_pos.distance_to(marker.position)
			if dist < min_dist:
				min_dist = dist
				nearest = marker
	return nearest

func get_map_text() -> String:
	var text = "Map Markers:\n"
	for marker in get_discovered_markers():
		text += "[%s] %s\n" % [marker.marker_type.capitalize(), marker.name]
	return text

func _get_marker(marker_id: String) -> Marker:
	for marker in markers:
		if marker.id == marker_id:
			return marker
	return null

func get_map_marker_statistics() -> Dictionary:
	return {
		"total_markers": markers.size(),
		"discovered_markers": get_discovered_markers().size(),
		"pinned_markers": get_state("pinned_markers", []).size(),
		"discovery_events": get_state("discovery_history", []).size(),
		"visit_events": get_state("visit_history", []).size(),
		"pin_events": get_state("pin_history", []).size()
	}
