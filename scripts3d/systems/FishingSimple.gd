extends BaseSystemSimple

class_name FishingSimple

class Fish:
	var name: String
	var rarity: String
	var weight: float
	var value: float
	var difficulty: int
	var speed: float
	var locations: Array[String]
	var required_level: int
	var best_time: String
	func _init(p_name: String, p_rarity: String, p_weight: float, p_value: float, p_difficulty: int = 1) -> void:
		name = p_name
		rarity = p_rarity
		weight = p_weight
		value = p_value
		difficulty = p_difficulty
		speed = 1.0 + (p_difficulty * 0.3)
		locations = []
		required_level = p_difficulty
		best_time = "day"

var fish_types: Dictionary = {
	"common": [
		Fish.new("Carp", "common", 2.5, 50, 1),
		Fish.new("Trout", "common", 1.8, 45, 1)
	],
	"uncommon": [
		Fish.new("Salmon", "uncommon", 5.0, 150, 2),
		Fish.new("Bass", "uncommon", 3.5, 120, 2)
	],
	"rare": [
		Fish.new("Tuna", "rare", 20.0, 500, 4),
		Fish.new("Swordfish", "rare", 25.0, 600, 5)
	]
}

signal fish_caught(fish: Fish)
signal level_up(new_level: int)
signal catch_failed
signal perfect_catch(fish: Fish)

func _ready() -> void:
	set_state("level", 1)
	set_state("catches", 0)
	set_state("total_weight", 0.0)
	set_state("equipment", {"rod": "basic", "bait": "worm"})
	set_state("fishing_spots", {})
	set_state("catch_history", [])
	set_state("rarity_distribution", {})
	set_state("perfect_catch_tracking", [])
	set_state("location_statistics", {})
	set_state("fishing_statistics", {})
	set_state("equipment_change_history", [])

func start_fishing(location: Vector3, time_of_day: String = "day", weather: String = "clear") -> Fish:
	var rarity_roll = randf()
	var level = get_state("level", 1)
	var rarity_bonus = 0.1 if weather == "rain" else 0.0
	var rarity = "common" if rarity_roll <= (0.4 - rarity_bonus) else ("uncommon" if rarity_roll <= (0.7 - rarity_bonus) else "rare")
	var fish_list = fish_types.get(rarity, [])
	if fish_list.is_empty():
		return null
	var fish = fish_list[randi() % fish_list.size()]
	if fish.required_level > level:
		catch_failed.emit()
		emit_event("catch_failed", {"reason": "level_too_low"})
		return null
	var success_rate = 0.5 + (level * 0.05) - (fish.difficulty * 0.1)
	if randf() > success_rate:
		catch_failed.emit()
		emit_event("catch_failed", {"reason": "lost_fish"})
		return null
	var is_perfect = randf() < (0.1 * (level / float(fish.difficulty)))
	if is_perfect:
		fish.value *= 1.5
		perfect_catch.emit(fish)
	var catches = get_state("catches", 0) + 1
	set_state("catches", catches)
	var total_weight = get_state("total_weight", 0.0) + fish.weight
	set_state("total_weight", total_weight)
	var history = get_state("catch_history", [])
	history.append({"fish": fish.name, "time": Time.get_ticks_msec(), "perfect": is_perfect, "weight": fish.weight, "rarity": fish.rarity})
	if history.size() > 50:
		history.pop_front()
	set_state("catch_history", history)
	_track_rarity(fish.rarity)
	if is_perfect:
		_record_perfect_catch(fish.name)
	_record_location_visit(location)
	if catches >= level * 10:
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
	var total_weight = get_state("total_weight", 0.0)
	var equipment = get_state("equipment", {})
	return "Fishing Level: %d | Catches: %d | Weight: %.1f kg | Rod: %s" % [level, catches, total_weight, equipment.get("rod", "basic")]

func _record_equipment_change(slot: String, item: String) -> void:
	var history = get_state("equipment_change_history", [])
	history.append({"slot": slot, "item": item, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("equipment_change_history", history)

func equip_rod(rod_type: String) -> void:
	var equipment = get_state("equipment", {})
	equipment["rod"] = rod_type
	set_state("equipment", equipment)
	_record_equipment_change("rod", rod_type)
	emit_event("rod_equipped", rod_type)

func equip_bait(bait_type: String) -> void:
	var equipment = get_state("equipment", {})
	equipment["bait"] = bait_type
	set_state("equipment", equipment)
	_record_equipment_change("bait", bait_type)
	emit_event("bait_equipped", bait_type)

func get_catch_history() -> Array:
	return get_state("catch_history", [])

func get_average_weight() -> float:
	var catches = get_state("catches", 0)
	if catches == 0:
		return 0.0
	return get_state("total_weight", 0.0) / float(catches)

func _track_rarity(rarity: String) -> void:
	var dist = get_state("rarity_distribution", {})
	dist[rarity] = dist.get(rarity, 0) + 1
	set_state("rarity_distribution", dist)

func _record_perfect_catch(fish_name: String) -> void:
	var tracking = get_state("perfect_catch_tracking", [])
	tracking.append({"fish": fish_name, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("perfect_catch_tracking", tracking)

func _record_location_visit(location: Vector3) -> void:
	var spots = get_state("location_statistics", {})
	var location_key = "%d_%d_%d" % [int(location.x), int(location.y), int(location.z)]
	if location_key not in spots:
		spots[location_key] = {"visits": 0, "catches": 0}
	spots[location_key]["visits"] += 1
	spots[location_key]["catches"] += 1
	set_state("location_statistics", spots)

func update_fishing_statistics() -> void:
	var stats = get_state("fishing_statistics", {})
	var history = get_state("catch_history", [])
	var perfect_catches = get_state("perfect_catch_tracking", []).size()
	stats["total_catches"] = get_state("catches", 0)
	stats["total_weight"] = get_state("total_weight", 0.0)
	stats["current_level"] = get_state("level", 1)
	stats["perfect_catches"] = perfect_catches
	stats["rarity_breakdown"] = get_state("rarity_distribution", {})
	stats["unique_locations"] = get_state("location_statistics", {}).size()
	if history.size() > 0:
		stats["average_weight"] = get_average_weight()
	stats["equipment_changes"] = get_state("equipment_change_history", []).size()
	stats["largest_catch"] = get_largest_catch()
	set_state("fishing_statistics", stats)

func get_fishing_statistics() -> Dictionary:
	update_fishing_statistics()
	return get_state("fishing_statistics", {})

func get_largest_catch() -> float:
	var history = get_catch_history()
	var max_weight = 0.0
	for entry in history:
		if entry.get("weight", 0.0) > max_weight:
			max_weight = entry["weight"]
	return max_weight
