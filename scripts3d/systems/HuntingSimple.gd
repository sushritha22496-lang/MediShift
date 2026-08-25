extends BaseSystemSimple

class_name HuntingSimple

class Game:
	var name: String
	var difficulty: String
	var meat_value: float
	var pelt_value: float
	var bones_count: int
	var level_requirement: int
	var weapon_requirement: String
	var stealth_bonus: float
	var awareness: float
	var can_be_tracked: bool
	var endangered_status: int
	func _init(p_name: String, p_difficulty: String, p_meat: float, p_pelt: float, p_bones: int) -> void:
		name = p_name
		difficulty = p_difficulty
		meat_value = p_meat
		pelt_value = p_pelt
		bones_count = p_bones
		level_requirement = ["easy", "medium", "hard", "very_hard"].find(p_difficulty) + 1
		weapon_requirement = "bow" if p_difficulty in ["easy", "medium"] else "melee"
		stealth_bonus = 0.2 if p_difficulty == "easy" else 0.1
		awareness = 0.5 if p_difficulty == "easy" else 1.0 if p_difficulty == "medium" else 1.5
		can_be_tracked = true
		endangered_status = 0

var game_types: Array[Game] = []

signal animal_hunted(game: Game)
signal level_up(new_level: int)
signal hunt_failed(reason: String)
signal perfect_hunt(game: Game)

func _ready() -> void:
	set_state("level", 1)
	set_state("hunts", 0)
	set_state("materials_collected", {})
	set_state("weapon_equipped", "bow")
	set_state("hunt_history", [])
	set_state("endangered_counts", {})
	set_state("perfect_hunt_tracking", [])
	set_state("animal_type_tracking", {})
	set_state("material_collection_history", [])
	set_state("hunting_statistics", {})
	set_state("failed_hunt_history", [])
	set_state("weapon_equip_history", [])
	_initialize_game()

func _initialize_game() -> void:
	game_types.append(Game.new("Deer", "easy", 150, 100, 3))
	game_types.append(Game.new("Boar", "medium", 250, 200, 5))
	game_types.append(Game.new("Bear", "hard", 500, 400, 10))
	game_types.append(Game.new("Tiger", "very_hard", 800, 600, 15))

func hunt(location: Vector3, stealth: float = 0.5, weapon_damage: float = 10.0) -> Game:
	var difficulty_roll = randf()
	var level = get_state("level", 1)
	var idx = 0 if difficulty_roll < 0.4 else (1 if difficulty_roll < 0.7 else (2 if difficulty_roll < 0.9 else 3))
	var selected_game = game_types[idx]
	if level < selected_game.level_requirement:
		_record_failed_hunt(selected_game.name, "level_too_low")
		hunt_failed.emit("Level too low")
		emit_event("hunt_failed", {"reason": "level_too_low"})
		return null
	var success_rate = 0.6 + (level * 0.05) - (selected_game.awareness * 0.1)
	success_rate += stealth * selected_game.stealth_bonus
	if randf() > success_rate:
		_record_failed_hunt(selected_game.name, "escaped")
		hunt_failed.emit("Animal escaped")
		emit_event("hunt_failed", {"reason": "escaped"})
		return null
	var is_perfect = randf() < (0.15 * (level / float(selected_game.level_requirement)))
	if is_perfect:
		selected_game.meat_value *= 1.3
		selected_game.pelt_value *= 1.3
		selected_game.bones_count += 2
		_record_perfect_hunt(selected_game.name)
		perfect_hunt.emit(selected_game)
	_collect_materials(selected_game)
	_record_hunt_attempt(selected_game.name, is_perfect)
	_track_animal_type(selected_game.name)
	_record_material_collection(selected_game)
	var hunts = get_state("hunts", 0) + 1
	set_state("hunts", hunts)
	selected_game.endangered_status += 1
	var endangered_counts = get_state("endangered_counts", {})
	endangered_counts[selected_game.name] = endangered_counts.get(selected_game.name, 0) + 1
	set_state("endangered_counts", endangered_counts)
	if hunts >= level * 8:
		_level_up()
	animal_hunted.emit(selected_game)
	emit_event("hunted", selected_game.name)
	return selected_game

func _collect_materials(game: Game) -> void:
	var materials = get_state("materials_collected", {})
	materials["meat"] = materials.get("meat", 0.0) + game.meat_value
	materials["pelt"] = materials.get("pelt", 0.0) + game.pelt_value
	materials["bones"] = materials.get("bones", 0) + game.bones_count
	set_state("materials_collected", materials)

func _level_up() -> void:
	var level = get_state("level", 1) + 1
	set_state("level", level)
	level_up.emit(level)
	emit_event("level_up", level)

func get_hunting_level() -> int:
	return get_state("level", 1)

func get_total_hunts() -> int:
	return get_state("hunts", 0)

func _record_failed_hunt(animal_name: String, reason: String) -> void:
	var history = get_state("failed_hunt_history", [])
	history.append({"animal": animal_name, "reason": reason, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("failed_hunt_history", history)

func equip_weapon(weapon_type: String) -> void:
	set_state("weapon_equipped", weapon_type)
	var history = get_state("weapon_equip_history", [])
	history.append({"weapon": weapon_type, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("weapon_equip_history", history)
	emit_event("weapon_equipped", weapon_type)

func _record_perfect_hunt(animal_name: String) -> void:
	var tracking = get_state("perfect_hunt_tracking", [])
	tracking.append({"animal": animal_name, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("perfect_hunt_tracking", tracking)

func _track_animal_type(animal_name: String) -> void:
	var tracking = get_state("animal_type_tracking", {})
	tracking[animal_name] = tracking.get(animal_name, 0) + 1
	set_state("animal_type_tracking", tracking)

func _record_hunt_attempt(animal_name: String, perfect: bool) -> void:
	var history = get_state("hunt_history", [])
	history.append({"animal": animal_name, "perfect": perfect, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("hunt_history", history)

func _record_material_collection(game: Game) -> void:
	var history = get_state("material_collection_history", [])
	history.append({
		"animal": game.name,
		"meat": game.meat_value,
		"pelt": game.pelt_value,
		"bones": game.bones_count,
		"time": Time.get_ticks_msec()
	})
	if history.size() > 50:
		history.pop_front()
	set_state("material_collection_history", history)

func update_hunting_statistics() -> void:
	var stats = get_state("hunting_statistics", {})
	var history = get_state("hunt_history", [])
	var perfect_hunts = get_state("perfect_hunt_tracking", []).size()
	var total_hunts = get_state("hunts", 0)
	stats["total_hunts"] = total_hunts
	stats["perfect_hunts"] = perfect_hunts
	stats["hunt_success_rate"] = float(history.size()) / float(total_hunts) if total_hunts > 0 else 0.0
	stats["current_level"] = get_state("level", 1)
	stats["animal_types_hunted"] = get_state("animal_type_tracking", {}).size()
	var materials = get_state("materials_collected", {})
	stats["total_meat"] = materials.get("meat", 0.0)
	stats["total_pelts"] = materials.get("pelt", 0.0)
	stats["total_bones"] = materials.get("bones", 0)
	stats["failed_hunts"] = get_state("failed_hunt_history", []).size()
	stats["weapon_changes"] = get_state("weapon_equip_history", []).size()
	stats["current_weapon"] = get_state("weapon_equipped", "bow")
	set_state("hunting_statistics", stats)

func get_hunting_statistics() -> Dictionary:
	update_hunting_statistics()
	return get_state("hunting_statistics", {})

func get_hunting_text() -> String:
	var level = get_state("level", 1)
	var hunts = get_state("hunts", 0)
	return "Hunting Level: %d | Hunts: %d" % [level, hunts]
