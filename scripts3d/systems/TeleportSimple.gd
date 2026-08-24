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
