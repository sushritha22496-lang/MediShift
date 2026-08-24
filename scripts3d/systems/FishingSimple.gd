extends BaseSystemSimple

class_name FishingSimple

class Fish:
	var name: String
	var rarity: String
	var weight: float
	var value: float
	func _init(p_name: String, p_rarity: String, p_weight: float, p_value: float) -> void:
		name = p_name
		rarity = p_rarity
		weight = p_weight
		value = p_value

var fish_types: Dictionary = {
	"common": [
		Fish.new("Carp", "common", 2.5, 50),
		Fish.new("Trout", "common", 1.8, 45)
	],
	"uncommon": [
		Fish.new("Salmon", "uncommon", 5.0, 150),
		Fish.new("Bass", "uncommon", 3.5, 120)
	],
	"rare": [
		Fish.new("Tuna", "rare", 20.0, 500),
		Fish.new("Swordfish", "rare", 25.0, 600)
	]
}

signal fish_caught(fish: Fish)
signal level_up(new_level: int)

func _ready() -> void:
	set_state("level", 1)
	set_state("catches", 0)

func start_fishing(location: Vector3) -> Fish:
	var rarity_roll = randf()
	var rarity = "common" if rarity_roll <= 0.4 else ("uncommon" if rarity_roll <= 0.7 else "rare")
	var fish_list = fish_types.get(rarity, [])
	if fish_list.is_empty():
		return null
	var fish = fish_list[randi() % fish_list.size()]
	var catches = get_state("catches", 0) + 1
	set_state("catches", catches)
	if catches >= get_state("level", 1) * 10:
		_level_up()
	fish_caught.emit(fish)
	emit_event("fish_caught", fish.name)
	return fish

func _level_up() -> void:
	var level = get_state("level", 1) + 1
	set_state("level", level)
	level_up.emit(level)
	emit_event("level_up", level)

func get_fishing_level() -> int:
	return get_state("level", 1)

func get_total_catches() -> int:
	return get_state("catches", 0)

func get_fishing_text() -> String:
	var level = get_state("level", 1)
	var catches = get_state("catches", 0)
	return "Fishing Level: %d | Catches: %d" % [level, catches]
