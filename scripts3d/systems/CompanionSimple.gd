extends BaseSystemSimple

class_name CompanionSimple

class Companion:
	var id: String
	var name: String
	var type: String
	var level: int = 1
	var experience: float = 0.0
	var health: float = 50.0
	var max_health: float = 50.0
	var attack: float = 5.0
	var defense: float = 3.0
	var loyalty: float = 50.0
	var is_active: bool = false
	var bond_level: int = 1
	var personality: String = ""
	var skills: Array[String] = []
	var equipment: Dictionary = {}
	var morale: float = 100.0
	var memories: Array[String] = []
	var special_attack: String = ""
	var evolution_stage: int = 1
	var max_evolution_stage: int = 3
	var stat_points: Dictionary = {"strength": 0, "agility": 0, "magic": 0}
	func _init(p_id: String, p_name: String, p_type: String) -> void:
		id = p_id
		name = p_name
		type = p_type
		_initialize_personality(p_type)

	func _initialize_personality(p_type: String) -> void:
		match p_type:
			"warrior":
				personality = "brave"
				skills = ["slash", "defend"]
				special_attack = "heroic_strike"
			"mage":
				personality = "curious"
				skills = ["fireball", "frostbolt"]
				special_attack = "arcane_burst"
			"rogue":
				personality = "cunning"
				skills = ["backstab", "dodge"]
				special_attack = "shadow_strike"
			"healer":
				personality = "gentle"
				skills = ["heal", "cleanse"]
				special_attack = "divine_blessing"

signal companion_acquired(companion: Companion)
signal companion_leveled_up(companion: Companion)
signal companion_defeated

func _record_acquisition(companion_id: String, name: String, comp_type: String) -> void:
	var history = get_state("acquisition_history", [])
	history.append({"id": companion_id, "name": name, "type": comp_type, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("acquisition_history", history)

func _record_level_progression(companion_id: String, new_level: int) -> void:
	var history = get_state("level_progression", [])
	history.append({"companion": companion_id, "level": new_level, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("level_progression", history)

func _record_loyalty_change(companion_id: String, new_loyalty: float) -> void:
	var history = get_state("loyalty_tracking", [])
	history.append({"companion": companion_id, "loyalty": new_loyalty, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("loyalty_tracking", history)

func _record_evolution(companion_id: String, new_stage: int) -> void:
	var history = get_state("evolution_history", [])
	history.append({"companion": companion_id, "stage": new_stage, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("evolution_history", history)

func _record_special_attack(companion_id: String, attack: String) -> void:
	var history = get_state("special_attack_history", [])
	history.append({"companion": companion_id, "attack": attack, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("special_attack_history", history)

func _record_stat_point(companion_id: String, stat: String) -> void:
	var history = get_state("stat_point_history", [])
	history.append({"companion": companion_id, "stat": stat, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("stat_point_history", history)

func _ready() -> void:
	set_state("companions", [])
	set_state("active_id", "")
	set_state("companion_bonds", {})
	set_state("companion_memories", {})
	set_state("synergy_bonuses", {})
	set_state("acquisition_history", [])
	set_state("level_progression", [])
	set_state("loyalty_tracking", [])
	set_state("evolution_history", [])
	set_state("companion_statistics", {})
	set_state("special_attack_history", [])
	set_state("stat_point_history", [])

func acquire_companion(name: String, comp_type: String) -> Companion:
	var companions = get_state("companions", []) as Array[Companion]
	var companion = Companion.new("comp_%d" % companions.size(), name, comp_type)
	companions.append(companion)
	_record_acquisition(companion.id, name, comp_type)
	companion_acquired.emit(companion)
	emit_event("companion_acquired", name)
	return companion

func set_active_companion(companion_id: String) -> bool:
	var companions = get_state("companions", []) as Array[Companion]
	for companion in companions:
		if companion.id == companion_id:
			set_state("active_id", companion_id)
			companion.is_active = true
			return true
	return false

func add_experience(amount: float) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	var active_id = get_state("active_id", "")
	for companion in companions:
		if companion.id == active_id:
			companion.experience += amount
			if companion.experience >= companion.level * 100:
				_level_up_companion(companion)

func _level_up_companion(companion: Companion) -> void:
	companion.level += 1
	companion.max_health += 10 + (companion.stat_points["strength"] * 2)
	companion.health = companion.max_health
	companion.attack += 2 + (companion.stat_points["strength"] * 0.5)
	companion.defense += 1 + (companion.stat_points["agility"] * 0.3)
	companion.experience = 0
	_record_level_progression(companion.id, companion.level)
	if companion.level % 5 == 0:
		_check_bond_progression(companion)
	companion_leveled_up.emit(companion)
	emit_event("companion_levelup", companion.id)

func _check_bond_progression(companion: Companion) -> void:
	var loyalty = companion.loyalty
	var new_bond = int(loyalty / 20.0) + 1
	if new_bond > companion.bond_level:
		companion.bond_level = new_bond
		emit_event("bond_increased", {"companion": companion.id, "level": new_bond})

func record_memory(companion_id: String, event: String) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	for companion in companions:
		if companion.id == companion_id:
			companion.memories.append(event)
			increase_loyalty(1.0)
			emit_event("memory_recorded", {"companion": companion_id, "event": event})

func use_special_attack(companion_id: String) -> bool:
	var companions = get_state("companions", []) as Array[Companion]
	for companion in companions:
		if companion.id == companion_id and companion.special_attack != "":
			if companion.health > 10:
				companion.health -= 10
				_record_special_attack(companion_id, companion.special_attack)
				emit_event("special_attack_used", {"companion": companion_id, "attack": companion.special_attack})
				return true
	return false

func evolve_companion(companion_id: String) -> bool:
	var companions = get_state("companions", []) as Array[Companion]
	for companion in companions:
		if companion.id == companion_id and companion.evolution_stage < companion.max_evolution_stage:
			if companion.loyalty >= 80.0 and companion.level >= companion.evolution_stage * 10:
				companion.evolution_stage += 1
				companion.max_health = int(companion.max_health * 1.2)
				companion.health = companion.max_health
				companion.attack *= 1.15
				companion.defense *= 1.1
				_record_evolution(companion_id, companion.evolution_stage)
				emit_event("companion_evolved", {"companion": companion_id, "stage": companion.evolution_stage})
				return true
	return false

func adjust_morale(companion_id: String, delta: float) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	for companion in companions:
		if companion.id == companion_id:
			companion.morale = clamp(companion.morale + delta, 0.0, 100.0)
			if companion.morale < 30.0:
				companion.attack *= 0.8
				companion.defense *= 0.8

func add_stat_point(companion_id: String, stat: String) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	for companion in companions:
		if companion.id == companion_id and stat in companion.stat_points:
			companion.stat_points[stat] += 1
			_record_stat_point(companion_id, stat)
			emit_event("stat_point_added", {"companion": companion_id, "stat": stat})

func heal_companion(amount: float) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	var active_id = get_state("active_id", "")
	for companion in companions:
		if companion.id == active_id:
			companion.health = minf(companion.health + amount, companion.max_health)

func damage_companion(amount: float) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	var active_id = get_state("active_id", "")
	for companion in companions:
		if companion.id == active_id:
			companion.health = maxf(companion.health - amount, 0.0)
			if companion.health <= 0:
				companion_defeated.emit()

func increase_loyalty(amount: float) -> void:
	var companions = get_state("companions", []) as Array[Companion]
	var active_id = get_state("active_id", "")
	for companion in companions:
		if companion.id == active_id:
			companion.loyalty = minf(companion.loyalty + amount, 100.0)
			_record_loyalty_change(companion.id, companion.loyalty)

func get_companion(companion_id: String) -> Companion:
	var companions = get_state("companions", []) as Array[Companion]
	for companion in companions:
		if companion.id == companion_id:
			return companion
	return null

func get_companions() -> Array:
	return get_state("companions", [])

func get_companion_text() -> String:
	var companions = get_state("companions", []) as Array[Companion]
	var text = "Companions [%d]:\n" % companions.size()
	for companion in companions:
		var status = "★" if companion.is_active else " "
		var bond_stars = "♥" * companion.bond_level
		text += "%s %s [%s] Lvl %d E%d | HP: %.0f | Loyalty: %.0f%% | Morale: %.0f\n" % [status, companion.name, companion.personality, companion.level, companion.evolution_stage, companion.health, companion.loyalty, companion.morale]
	return text

func update_companion_statistics() -> void:
	var stats = get_state("companion_statistics", {})
	var companions = get_state("companions", []) as Array[Companion]
	stats["total_acquired"] = get_state("acquisition_history", []).size()
	stats["total_companions"] = companions.size()
	stats["total_levelups"] = get_state("level_progression", []).size()
	stats["total_evolutions"] = get_state("evolution_history", []).size()
	stats["loyalty_events"] = get_state("loyalty_tracking", []).size()
	stats["special_attacks_used"] = get_state("special_attack_history", []).size()
	stats["stat_points_allocated"] = get_state("stat_point_history", []).size()
	if not companions.is_empty():
		var avg_level = 0.0
		var avg_loyalty = 0.0
		for comp in companions:
			avg_level += comp.level
			avg_loyalty += comp.loyalty
		stats["average_level"] = avg_level / float(companions.size())
		stats["average_loyalty"] = avg_loyalty / float(companions.size())
	set_state("companion_statistics", stats)

func get_companion_statistics() -> Dictionary:
	update_companion_statistics()
	return get_state("companion_statistics", {})
