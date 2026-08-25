extends BaseSystemSimple

class_name PlayerDataSimple

signal player_renamed(old_name: String, new_name: String)
signal player_data_updated
signal level_up(new_level: int)

func _ready() -> void:
	set_state("player_name", "Rama")
	set_state("player_level", 1)
	set_state("player_exp", 0)
	set_state("player_hp", 100)
	set_state("player_max_hp", 100)
	set_state("player_mana", 50)
	set_state("player_max_mana", 50)
	set_state("player_class", "warrior")
	set_state("gender", "male")
	set_state("playtime", 0.0)
	set_state("level_progression", [])
	set_state("stat_change_history", [])
	set_state("experience_history", [])
	set_state("class_change_history", [])
	set_state("gender_impact_bonuses", {})
	set_state("playtime_milestones", [])
	set_state("character_statistics", {})
	set_state("session_start_time", Time.get_ticks_msec())

func set_player_name(name: String) -> void:
	var old_name = get_state("player_name", "")
	set_state("player_name", name)
	player_renamed.emit(old_name, name)
	emit_event("player_renamed", name)

func get_player_name() -> String:
	return get_state("player_name", "Rama")

func set_player_class(class_name: String) -> void:
	var old_class = get_state("player_class", "warrior")
	set_state("player_class", class_name)
	_record_class_change(old_class, class_name)
	player_data_updated.emit()
	emit_event("class_set", class_name)

func get_player_class() -> String:
	return get_state("player_class", "warrior")

func get_player_level() -> int:
	return get_state("player_level", 1)

func add_experience(amount: float) -> void:
	var exp = get_state("player_exp", 0.0)
	exp += amount
	set_state("player_exp", exp)
	_record_experience(amount)
	emit_event("exp_gained", amount)

	var exp_required = 100.0 * get_player_level()
	if exp >= exp_required:
		level_up()

func level_up() -> void:
	var level = get_state("player_level", 1)
	level += 1
	set_state("player_level", level)
	set_state("player_exp", 0.0)

	var max_hp = get_state("player_max_hp", 100.0)
	max_hp += 20.0
	set_state("player_max_hp", max_hp)
	set_state("player_hp", max_hp)

	_record_level_progression(level)
	level_up.emit(level)
	player_data_updated.emit()
	emit_event("level_up", level)

func get_player_data() -> Dictionary:
	return {
		"name": get_player_name(),
		"level": get_player_level(),
		"class": get_player_class(),
		"hp": get_state("player_hp", 0),
		"max_hp": get_state("player_max_hp", 0),
		"mana": get_state("player_mana", 0),
		"max_mana": get_state("player_max_mana", 0),
		"playtime": get_state("playtime", 0.0)
	}

func get_player_text() -> String:
	var data = get_player_data()
	return "%s (Lvl %d %s)\nHP: %.0f/%.0f | Mana: %.0f/%.0f" % [data["name"], data["level"], data["class"].capitalize(), data["hp"], data["max_hp"], data["mana"], data["max_mana"]]

func _record_level_progression(level: int) -> void:
	var progression = get_state("level_progression", [])
	progression.append({"level": level, "time": Time.get_ticks_msec()})
	if progression.size() > 100:
		progression.pop_front()
	set_state("level_progression", progression)

func _record_experience(amount: float) -> void:
	var history = get_state("experience_history", [])
	history.append({"amount": amount, "total": get_state("player_exp", 0.0), "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("experience_history", history)

func _record_class_change(old_class: String, new_class: String) -> void:
	var history = get_state("class_change_history", [])
	history.append({"from": old_class, "to": new_class, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("class_change_history", history)

func record_stat_change(stat_name: String, old_value: float, new_value: float) -> void:
	var history = get_state("stat_change_history", [])
	history.append({"stat": stat_name, "old": old_value, "new": new_value, "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("stat_change_history", history)

func set_gender_impact_bonus(gender: String, bonus_type: String, value: float) -> void:
	var bonuses = get_state("gender_impact_bonuses", {})
	if gender not in bonuses:
		bonuses[gender] = {}
	bonuses[gender][bonus_type] = value
	set_state("gender_impact_bonuses", bonuses)
	emit_event("gender_bonus_set", gender)

func get_gender_impact_bonus(bonus_type: String) -> float:
	var gender = get_state("gender", "male")
	var bonuses = get_state("gender_impact_bonuses", {})
	if gender in bonuses and bonus_type in bonuses[gender]:
		return bonuses[gender][bonus_type]
	return 0.0

func record_playtime_milestone(milestone_name: String, playtime_ms: int) -> void:
	var milestones = get_state("playtime_milestones", [])
	milestones.append({"name": milestone_name, "playtime": playtime_ms, "time": Time.get_ticks_msec()})
	set_state("playtime_milestones", milestones)
	emit_event("milestone_reached", milestone_name)

func get_session_duration() -> int:
	var start = get_state("session_start_time", 0)
	return Time.get_ticks_msec() - start

func update_character_statistics() -> void:
	var stats = get_state("character_statistics", {})
	stats["level"] = get_player_level()
	stats["experience"] = get_state("player_exp", 0.0)
	stats["class"] = get_player_class()
	stats["level_ups"] = get_state("level_progression", []).size()
	stats["class_changes"] = get_state("class_change_history", []).size()
	stats["session_duration"] = get_session_duration()
	stats["experience_events"] = get_state("experience_history", []).size()
	stats["stat_changes"] = get_state("stat_change_history", []).size()
	stats["playtime_milestones"] = get_state("playtime_milestones", []).size()
	set_state("character_statistics", stats)

func get_character_statistics() -> Dictionary:
	update_character_statistics()
	return get_state("character_statistics", {})

func get_level_progression() -> Array:
	return get_state("level_progression", [])

func get_experience_history() -> Array:
	return get_state("experience_history", [])
