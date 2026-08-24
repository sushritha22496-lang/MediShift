extends Node

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

var fishing_level: int = 1
var total_catches: int = 0

signal fish_caught(fish: Fish)
signal level_up(new_level: int)

func start_fishing(location: Vector3) -> Fish:
	var rarity_roll = randf()
	var rarity = "common"

	if rarity_roll > 0.7:
		rarity = "rare"
	elif rarity_roll > 0.4:
		rarity = "uncommon"

	var fish_list = fish_types.get(rarity, [])
	if fish_list.is_empty():
		return null

	var fish = fish_list[randi() % fish_list.size()]
	total_catches += 1

	if total_catches >= fishing_level * 10:
		_level_up()

	fish_caught.emit(fish)
	print("🎣 Caught: %s (%s)" % [fish.name, fish.rarity])
	return fish

func _level_up() -> void:
	fishing_level += 1
	level_up.emit(fishing_level)
	print("🎣 Fishing level: %d" % fishing_level)

func get_fishing_level() -> int:
	return fishing_level

func get_total_catches() -> int:
	return total_catches

func get_fishing_text() -> String:
	return "Fishing Level: %d | Catches: %d" % [fishing_level, total_catches]
