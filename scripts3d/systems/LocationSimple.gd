extends Node

class_name LocationSimple

class Location:
	var id: String
	var name: String
	var description: String
	var position: Vector3
	var visited: bool = false
	var difficulty_tier: int = 1
	var environmental_hazards: Array[String] = []
	var npcs_present: Array[String] = []
	var enemies_present: Array[String] = []
	var available_resources: Dictionary = {}
	var exp_multiplier: float = 1.0
	var loot_rate_multiplier: float = 1.0
	var weather_type: String = "clear"
	var secrets_found: int = 0
	var total_secrets: int = 3
	var points_of_interest: Array[String] = []
	var discovery_reward: Dictionary = {}
	var time_spent: float = 0.0

	func _init(p_id: String, p_name: String, p_desc: String, p_pos: Vector3) -> void:
		id = p_id
		name = p_name
		description = p_desc
		position = p_pos

var locations: Array[Location] = []
var current_location: Location = null
var discovery_history: Array = []
var entry_history: Array = []
var secret_discovery_history: Array = []

signal location_discovered(location: Location)
signal location_entered(location: Location)
signal secret_found(data: Dictionary)

func _ready() -> void:
	_initialize_locations()

func _initialize_locations() -> void:
	var loc1 = Location.new("forest", "Badrachalam Forest", "Ancient forest where Rama searches for Sita", Vector3(0, 0, 0))
	loc1.visited = true
	loc1.difficulty_tier = 1
	loc1.environmental_hazards = ["wild_animals"]
	loc1.npcs_present = ["merchant", "hunter"]
	loc1.available_resources = {"herbs": 10, "wood": 15}
	loc1.exp_multiplier = 1.0
	loc1.loot_rate_multiplier = 1.0
	loc1.points_of_interest = ["ancient_shrine", "crystal_pond"]

	var loc2 = Location.new("village", "Settlements", "Small villages with merchants and NPCs", Vector3(100, 0, 100))
	loc2.difficulty_tier = 1
	loc2.environmental_hazards = []
	loc2.npcs_present = ["innkeeper", "blacksmith", "trader"]
	loc2.enemies_present = ["bandit", "thief"]
	loc2.available_resources = {"food": 20}
	loc2.exp_multiplier = 0.8
	loc2.loot_rate_multiplier = 0.9

	var loc3 = Location.new("temple", "Temple", "Sacred temple for meditation and healing", Vector3(-150, 0, 50))
	loc3.difficulty_tier = 2
	loc3.environmental_hazards = ["spiritual_guardians"]
	loc3.enemies_present = ["guardian_spirit", "cursed_monk"]
	loc3.available_resources = {"holy_water": 5, "incense": 8}
	loc3.exp_multiplier = 1.3
	loc3.loot_rate_multiplier = 1.2
	loc3.discovery_reward = {"bonus_exp": 100}

	var loc4 = Location.new("mountains", "Mountains", "Treacherous mountain peaks", Vector3(200, 50, -200))
	loc4.difficulty_tier = 3
	loc4.environmental_hazards = ["avalanche", "thin_air", "extreme_cold"]
	loc4.enemies_present = ["mountain_beast", "ice_dragon"]
	loc4.available_resources = {"ore": 12, "crystals": 5}
	loc4.exp_multiplier = 1.8
	loc4.loot_rate_multiplier = 1.5

	var loc5 = Location.new("river", "Sacred River", "The holy Godavari River", Vector3(0, 0, -200))
	loc5.difficulty_tier = 2
	loc5.environmental_hazards = ["strong_currents", "water_spirits"]
	loc5.enemies_present = ["river_naga", "water_elemental"]
	loc5.available_resources = {"pearls": 6, "rare_fish": 10}
	loc5.exp_multiplier = 1.4
	loc5.loot_rate_multiplier = 1.3

	locations = [loc1, loc2, loc3, loc4, loc5]
	current_location = loc1

func discover_location(location_id: String) -> Dictionary:
	for location in locations:
		if location.id == location_id:
			if not location.visited:
				location.visited = true
				discovery_history.append({"location": location_id, "tier": location.difficulty_tier, "time": Time.get_ticks_msec()})
				if discovery_history.size() > 50:
					discovery_history.pop_front()
				location_discovered.emit(location)
				return location.discovery_reward
	return {}

func enter_location(location_id: String) -> bool:
	for location in locations:
		if location.id == location_id:
			current_location = location
			entry_history.append({"location": location_id, "time": Time.get_ticks_msec()})
			if entry_history.size() > 50:
				entry_history.pop_front()
			location_entered.emit(location)
			return true
	return false

func spend_time_in_location(time: float) -> void:
	if current_location:
		current_location.time_spent += time

func find_secret(location_id: String) -> bool:
	for location in locations:
		if location.id == location_id:
			if location.secrets_found < location.total_secrets:
				location.secrets_found += 1
				secret_discovery_history.append({"location": location_id, "secrets_found": location.secrets_found, "time": Time.get_ticks_msec()})
				if secret_discovery_history.size() > 50:
					secret_discovery_history.pop_front()
				secret_found.emit({"location": location_id, "secrets": location.secrets_found})
				return true
	return false

func get_location_danger_level() -> int:
	if current_location:
		return current_location.difficulty_tier
	return 0

func get_location_bonuses() -> Dictionary:
	if current_location:
		return {"exp_mult": current_location.exp_multiplier, "loot_mult": current_location.loot_rate_multiplier}
	return {}

func get_location(location_id: String) -> Location:
	for location in locations:
		if location.id == location_id:
			return location
	return null

func get_all_locations() -> Array[Location]:
	return locations

func get_visited_locations() -> Array[Location]:
	var visited: Array[Location] = []
	for location in locations:
		if location.visited:
			visited.append(location)
	return visited

func get_locations_text() -> String:
	var visited = get_visited_locations()
	var text = "Locations: %d/%d discovered\n" % [visited.size(), locations.size()]
	for location in visited:
		var danger = "★" * location.difficulty_tier
		var secrets = " [%d/%d secrets]" % [location.secrets_found, location.total_secrets]
		text += "✓ %s %s%s\n" % [location.name, danger, secrets]
	return text

func get_location_statistics() -> Dictionary:
	var total_secrets_found = 0
	var total_secrets_possible = 0
	var total_time_spent = 0.0
	for location in locations:
		total_secrets_found += location.secrets_found
		total_secrets_possible += location.total_secrets
		total_time_spent += location.time_spent
	return {
		"total_locations": locations.size(),
		"visited_locations": get_visited_locations().size(),
		"discoveries_recorded": discovery_history.size(),
		"entries_recorded": entry_history.size(),
		"secrets_found_total": total_secrets_found,
		"secrets_possible_total": total_secrets_possible,
		"secrets_discovery_events": secret_discovery_history.size(),
		"total_time_spent": total_time_spent,
		"current_location": current_location.id if current_location else ""
	}
