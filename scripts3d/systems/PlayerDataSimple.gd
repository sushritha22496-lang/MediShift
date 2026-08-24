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

func set_player_name(name: String) -> void:
	var old_name = get_state("player_name", "")
	set_state("player_name", name)
	player_renamed.emit(old_name, name)
	emit_event("player_renamed", name)

func get_player_name() -> String:
	return get_state("player_name", "Rama")

func set_player_class(class_name: String) -> void:
	set_state("player_class", class_name)
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
