extends BaseSystemSimple

class_name TeleportSimple

class Portal:
	var id: String
	var name: String
	var position: Vector3
	var destination: Vector3
	var requires_key: bool
	var activated: bool
	func _init(p_id: String, p_name: String, p_pos: Vector3, p_dest: Vector3) -> void:
		id = p_id
		name = p_name
		position = p_pos
		destination = p_dest
		requires_key = false
		activated = false

var portals: Array[Portal] = []

signal portal_discovered(portal: Portal)
signal portal_activated(portal: Portal)
signal teleport_started(portal_id: String)
signal teleport_completed(destination: Vector3)

func _ready() -> void:
	set_state("active_portals", [])
	set_state("teleport_keys", {})
	set_state("portal_cooldowns", {})
	set_state("teleport_history", [])
	set_state("portal_level_requirements", {})
	set_state("portal_energy_costs", {})
	set_state("portal_links", {})
	set_state("portal_malfunctions", [])
	set_state("destination_safety_levels", {})
	_initialize_portals()

func _initialize_portals() -> void:
	portals = [
		Portal.new("shrine_portal", "Shrine Portal", Vector3(0, 0, 150), Vector3(0, 0, 150)),
		Portal.new("forest_portal", "Forest Portal", Vector3(100, 0, 100), Vector3(100, 0, 100)),
		Portal.new("temple_portal", "Temple Portal", Vector3(-150, 0, 50), Vector3(-150, 0, 50)),
		Portal.new("mountain_portal", "Mountain Portal", Vector3(200, 50, -200), Vector3(200, 50, -200)),
		Portal.new("cave_portal", "Cave Portal", Vector3(50, 0, 50), Vector3(50, 5, 50))
	]

func discover_portal(portal_id: String) -> bool:
	var portal = _get_portal(portal_id)
	if portal and not portal.activated:
		portal.activated = true
		var active = get_state("active_portals", [])
		active.append(portal_id)
		set_state("active_portals", active)
		portal_discovered.emit(portal)
		emit_event("portal_discovered", portal_id)
		return true
	return false

func activate_portal(portal_id: String) -> bool:
	var portal = _get_portal(portal_id)
	if portal and not portal.activated:
		if portal.requires_key:
			var keys = get_state("teleport_keys", {})
			if portal_id not in keys or not keys[portal_id]:
				return false
		discover_portal(portal_id)
		portal_activated.emit(portal)
		emit_event("portal_activated", portal_id)
		return true
	return false

func teleport(portal_id: String, player: Node3D) -> bool:
	var portal = _get_portal(portal_id)
	if portal and portal.activated:
		teleport_started.emit(portal_id)
		await get_tree().create_timer(1.0).timeout
		player.global_position = portal.destination
		teleport_completed.emit(portal.destination)
		emit_event("teleported", portal_id)
		return true
	return false

func get_portal_key(portal_id: String) -> void:
	var keys = get_state("teleport_keys", {})
	keys[portal_id] = true
	set_state("teleport_keys", keys)
	emit_event("key_obtained", portal_id)

func get_active_portals() -> Array[Portal]:
	var active_ids = get_state("active_portals", [])
	var active_portals: Array[Portal] = []
	for p in portals:
		if p.id in active_ids:
			active_portals.append(p)
	return active_portals

func get_portal(portal_id: String) -> Portal:
	return _get_portal(portal_id)

func get_portal_text() -> String:
	var text = "Portals:\n"
	for portal in get_active_portals():
		text += "[%s] %s\n" % ["✓" if portal.activated else "?", portal.name]
	return text

func _get_portal(portal_id: String) -> Portal:
	for portal in portals:
		if portal.id == portal_id:
			return portal
	return null

func set_portal_cooldown(portal_id: String, cooldown_ms: int) -> void:
	var cooldowns = get_state("portal_cooldowns", {})
	cooldowns[portal_id] = {"start": Time.get_ticks_msec(), "duration": cooldown_ms}
	set_state("portal_cooldowns", cooldowns)
	emit_event("cooldown_set", portal_id)

func is_portal_on_cooldown(portal_id: String) -> bool:
	var cooldowns = get_state("portal_cooldowns", {})
	if portal_id not in cooldowns:
		return false
	var current = Time.get_ticks_msec()
	var start = cooldowns[portal_id]["start"]
	var duration = cooldowns[portal_id]["duration"]
	return (current - start) < duration

func record_teleport(portal_id: String, destination: Vector3, success: bool) -> void:
	var history = get_state("teleport_history", [])
	history.append({"portal": portal_id, "dest": destination, "success": success, "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("teleport_history", history)

func set_portal_level_requirement(portal_id: String, level_required: int) -> void:
	var requirements = get_state("portal_level_requirements", {})
	requirements[portal_id] = level_required
	set_state("portal_level_requirements", requirements)

func get_portal_level_requirement(portal_id: String) -> int:
	var requirements = get_state("portal_level_requirements", {})
	return requirements.get(portal_id, 1)

func set_portal_energy_cost(portal_id: String, cost: float) -> void:
	var costs = get_state("portal_energy_costs", {})
	costs[portal_id] = cost
	set_state("portal_energy_costs", costs)

func get_portal_energy_cost(portal_id: String) -> float:
	var costs = get_state("portal_energy_costs", {})
	return costs.get(portal_id, 10.0)

func link_portals(portal1_id: String, portal2_id: String) -> void:
	var links = get_state("portal_links", {})
	links[portal1_id] = portal2_id
	links[portal2_id] = portal1_id
	set_state("portal_links", links)
	emit_event("portals_linked", {"p1": portal1_id, "p2": portal2_id})

func get_linked_portal(portal_id: String) -> String:
	var links = get_state("portal_links", {})
	return links.get(portal_id, "")

func record_portal_malfunction(portal_id: String, malfunction_type: String) -> void:
	var malfunctions = get_state("portal_malfunctions", [])
	malfunctions.append({"portal": portal_id, "type": malfunction_type, "time": Time.get_ticks_msec()})
	if malfunctions.size() > 50:
		malfunctions.pop_front()
	set_state("portal_malfunctions", malfunctions)
	emit_event("malfunction_recorded", portal_id)

func set_destination_safety_level(destination: Vector3, safety: float) -> void:
	var safety_levels = get_state("destination_safety_levels", {})
	var key = "%d_%d_%d" % [int(destination.x), int(destination.y), int(destination.z)]
	safety_levels[key] = clampf(safety, 0.0, 1.0)
	set_state("destination_safety_levels", safety_levels)

func get_destination_safety_level(destination: Vector3) -> float:
	var safety_levels = get_state("destination_safety_levels", {})
	var key = "%d_%d_%d" % [int(destination.x), int(destination.y), int(destination.z)]
	return safety_levels.get(key, 0.5)

func get_teleport_success_rate() -> float:
	var history = get_state("teleport_history", [])
	if history.is_empty():
		return 0.0
	var successes = history.filter(func(h): return h["success"]).size()
	return float(successes) / float(history.size())
