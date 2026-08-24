extends BaseSystemSimple

class_name TreasureSimple

class Treasure:
	var id: String
	var name: String
	var position: Vector3
	var value: float
	var discovered: bool
	var locked: bool
	var difficulty: int
	var trapped: bool
	var cursed: bool
	var trap_type: String
	var guardian: String
	var unlock_requirement: String
	var puzzle_required: bool
	var security_layers: int
	func _init(p_id: String, p_name: String, p_pos: Vector3, p_value: float, p_diff: int = 1) -> void:
		id = p_id
		name = p_name
		position = p_pos
		value = p_value
		discovered = false
		locked = true
		difficulty = p_diff
		trapped = difficulty > 1
		cursed = difficulty > 3
		trap_type = "poison" if trapped else ""
		guardian = ""
		unlock_requirement = ""
		puzzle_required = difficulty > 2
		security_layers = 1 + difficulty

var treasures: Array[Treasure] = []

signal treasure_discovered(treasure: Treasure)
signal treasure_unlocked(treasure_id: String)
signal treasure_looted(treasure_id: String, value: float)
signal trap_triggered(treasure_id: String, trap_type: String)
signal puzzle_triggered(treasure_id: String)
signal curse_applied(treasure_id: String)

func _ready() -> void:
	set_state("discovered_treasures", [])
	set_state("looted_treasures", [])
	set_state("total_value_found", 0.0)
	set_state("treasure_access_log", [])
	set_state("security_bypasses", [])
	_initialize_treasures()

func _initialize_treasures() -> void:
	treasures = [
		Treasure.new("t1", "Merchant's Chest", Vector3(100, 0, 100), 500.0, 1),
		Treasure.new("t2", "Ancient Artifact", Vector3(-50, 0, -50), 1000.0, 2),
		Treasure.new("t3", "Dragon's Hoard", Vector3(200, 50, -200), 5000.0, 4),
		Treasure.new("t4", "Royal Jewels", Vector3(-150, 0, 50), 2000.0, 3),
		Treasure.new("t5", "Hidden Cache", Vector3(0, 0, 200), 750.0, 2)
	]

func discover_treasure(treasure_id: String) -> bool:
	var treasure = _get_treasure(treasure_id)
	if treasure and not treasure.discovered:
		treasure.discovered = true
		var discovered = get_state("discovered_treasures", [])
		discovered.append(treasure_id)
		set_state("discovered_treasures", discovered)
		treasure_discovered.emit(treasure)
		emit_event("treasure_discovered", treasure_id)
		return true
	return false

func unlock_treasure(treasure_id: String, lockpicking_skill: float = 0.0) -> bool:
	var treasure = _get_treasure(treasure_id)
	if treasure and treasure.discovered and treasure.locked:
		if lockpicking_skill < treasure.difficulty * 10.0:
			return false
		if treasure.puzzle_required:
			puzzle_triggered.emit(treasure_id)
			emit_event("puzzle_triggered", treasure_id)
			return false
		treasure.locked = false
		treasure_unlocked.emit(treasure_id)
		emit_event("treasure_unlocked", treasure_id)
		return true
	return false

func loot_treasure(treasure_id: String) -> float:
	var treasure = _get_treasure(treasure_id)
	if treasure and treasure.discovered and not treasure.locked:
		var looted = get_state("looted_treasures", [])
		if treasure_id not in looted:
			var damage = 0.0
			if treasure.trapped and randf() < 0.5:
				trap_triggered.emit(treasure_id, treasure.trap_type)
				damage = (treasure.difficulty * 10.0)
				emit_event("trap_triggered", treasure_id)
			if treasure.cursed:
				curse_applied.emit(treasure_id)
				emit_event("curse_applied", treasure_id)
			looted.append(treasure_id)
			set_state("looted_treasures", looted)
			var total = get_state("total_value_found", 0.0)
			total += treasure.value
			set_state("total_value_found", total)
			treasure_looted.emit(treasure_id, treasure.value)
			emit_event("treasure_looted", treasure_id)
			return treasure.value - damage
	return 0.0

func get_treasure(treasure_id: String) -> Treasure:
	return _get_treasure(treasure_id)

func get_discovered_treasures() -> Array[Treasure]:
	var discovered_ids = get_state("discovered_treasures", [])
	var discovered: Array[Treasure] = []
	for t in treasures:
		if t.id in discovered_ids:
			discovered.append(t)
	return discovered

func get_treasure_distance(treasure_id: String, player_pos: Vector3) -> float:
	var treasure = _get_treasure(treasure_id)
	if treasure:
		return player_pos.distance_to(treasure.position)
	return -1.0

func get_treasure_text() -> String:
	var discovered = get_discovered_treasures()
	var looted = get_state("looted_treasures", [])
	var text = "Treasures: %d discovered, %d looted\nTotal value: %.0f\n" % [discovered.size(), looted.size(), get_state("total_value_found", 0.0)]
	for treasure in discovered.slice(0, 3):
		var status = "🔓" if not treasure.locked else "🔒"
		text += "%s %s (%.0f)\n" % [status, treasure.name, treasure.value]
	return text

func solve_puzzle(treasure_id: String) -> bool:
	var treasure = _get_treasure(treasure_id)
	if treasure and treasure.puzzle_required:
		treasure.puzzle_required = false
		emit_event("puzzle_solved", treasure_id)
		return true
	return false

func disarm_trap(treasure_id: String, trap_skill: float = 0.0) -> bool:
	var treasure = _get_treasure(treasure_id)
	if treasure and treasure.trapped:
		if trap_skill < treasure.difficulty * 5.0:
			return false
		treasure.trapped = false
		emit_event("trap_disarmed", treasure_id)
		return true
	return false

func remove_curse(treasure_id: String) -> bool:
	var treasure = _get_treasure(treasure_id)
	if treasure and treasure.cursed:
		treasure.cursed = false
		treasure.value *= 1.2
		emit_event("curse_removed", treasure_id)
		return true
	return false

func get_treasure_security_level(treasure_id: String) -> int:
	var treasure = _get_treasure(treasure_id)
	if treasure:
		var level = treasure.security_layers
		if treasure.trapped:
			level += 1
		if treasure.cursed:
			level += 2
		if treasure.puzzle_required:
			level += 1
		return level
	return 0

func _get_treasure(treasure_id: String) -> Treasure:
	for treasure in treasures:
		if treasure.id == treasure_id:
			return treasure
	return null

func log_treasure_access(treasure_id: String, action: String) -> void:
	var log = get_state("treasure_access_log", [])
	log.append({"treasure": treasure_id, "action": action, "timestamp": Time.get_ticks_msec()})
	if log.size() > 100:
		log.pop_front()
	set_state("treasure_access_log", log)

func record_security_bypass(treasure_id: String, bypass_type: String) -> void:
	var bypasses = get_state("security_bypasses", [])
	bypasses.append({"treasure": treasure_id, "type": bypass_type, "time": Time.get_ticks_msec()})
	set_state("security_bypasses", bypasses)
	emit_event("security_bypassed", {"treasure": treasure_id, "type": bypass_type})

func get_treasure_access_log() -> Array:
	return get_state("treasure_access_log", [])
