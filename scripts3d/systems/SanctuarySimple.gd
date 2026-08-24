extends BaseSystemSimple

class_name SanctuarySimple

class Sanctuary:
	var id: String
	var name: String
	var position: Vector3
	var discovered: bool
	var healing_rate: float
	func _init(p_id: String, p_name: String, p_pos: Vector3, p_rate: float = 1.0) -> void:
		id = p_id
		name = p_name
		position = p_pos
		discovered = false
		healing_rate = p_rate

var sanctuaries: Array[Sanctuary] = []

signal sanctuary_discovered(sanctuary: Sanctuary)
signal sanctuary_entered(sanctuary_id: String)
signal sanctuary_exited(sanctuary_id: String)
signal player_healed(amount: float)

func _ready() -> void:
	set_state("active_sanctuary", "")
	set_state("discovered_sanctuaries", [])
	_initialize_sanctuaries()

func _initialize_sanctuaries() -> void:
	sanctuaries = [
		Sanctuary.new("shrine_main", "Main Shrine", Vector3(0, 0, 0), 1.5),
		Sanctuary.new("temple_safe", "Sacred Temple", Vector3(-150, 0, 50), 1.2),
		Sanctuary.new("forest_grove", "Enchanted Grove", Vector3(100, 0, 100), 1.0),
		Sanctuary.new("mountain_peak", "Mountain Peak", Vector3(200, 50, -200), 1.3),
		Sanctuary.new("cave_shelter", "Crystal Cavern", Vector3(50, 0, 50), 1.1)
	]

func discover_sanctuary(sanctuary_id: String) -> bool:
	var sanctuary = _get_sanctuary(sanctuary_id)
	if sanctuary and not sanctuary.discovered:
		sanctuary.discovered = true
		var discovered = get_state("discovered_sanctuaries", [])
		discovered.append(sanctuary_id)
		set_state("discovered_sanctuaries", discovered)
		sanctuary_discovered.emit(sanctuary)
		emit_event("sanctuary_discovered", sanctuary_id)
		return true
	return false

func enter_sanctuary(sanctuary_id: String) -> bool:
	var sanctuary = _get_sanctuary(sanctuary_id)
	if sanctuary and sanctuary.discovered:
		set_state("active_sanctuary", sanctuary_id)
		sanctuary_entered.emit(sanctuary_id)
		emit_event("sanctuary_entered", sanctuary_id)
		return true
	return false

func exit_sanctuary() -> void:
	set_state("active_sanctuary", "")
	sanctuary_exited.emit("")
	emit_event("sanctuary_exited", "")

func heal_in_sanctuary(player: Node, amount: float) -> void:
	var sanctuary_id = get_state("active_sanctuary", "")
	if sanctuary_id == "":
		return
	var sanctuary = _get_sanctuary(sanctuary_id)
	if sanctuary:
		var total_heal = amount * sanctuary.healing_rate
		if player.has_method("heal"):
			player.heal(total_heal)
		player_healed.emit(total_heal)
		emit_event("player_healed", sanctuary_id)

func get_active_sanctuary() -> Sanctuary:
	var sanctuary_id = get_state("active_sanctuary", "")
	return _get_sanctuary(sanctuary_id) if sanctuary_id != "" else null

func is_in_sanctuary() -> bool:
	return get_state("active_sanctuary", "") != ""

func get_discovered_sanctuaries() -> Array[Sanctuary]:
	var discovered_ids = get_state("discovered_sanctuaries", [])
	var discovered: Array[Sanctuary] = []
	for s in sanctuaries:
		if s.id in discovered_ids:
			discovered.append(s)
	return discovered

func get_sanctuary_text() -> String:
	var active = get_active_sanctuary()
	if active:
		return "Sanctuary: %s (Healing: %.0f%%)" % [active.name, active.healing_rate * 100.0]
	return "No sanctuary entered\nDiscovered: %d" % get_discovered_sanctuaries().size()

func _get_sanctuary(sanctuary_id: String) -> Sanctuary:
	for sanctuary in sanctuaries:
		if sanctuary.id == sanctuary_id:
			return sanctuary
	return null
