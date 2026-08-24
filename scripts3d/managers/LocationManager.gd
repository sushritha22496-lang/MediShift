extends Node3D

class_name LocationManager

enum LocationType { FOREST, PLAINS, COAST, VILLAGE }

class Location:
	var id: String
	var name: String
	var location_type: LocationType
	var spawn_position: Vector3
	var npcs: Array[String] = []
	var items: Array[String] = []
	var description: String

var locations: Dictionary = {}
var current_location: Location = null

signal location_changed(location: Location)

func _ready() -> void:
	_initialize_locations()

func _initialize_locations() -> void:
	var forest = Location.new()
	forest.id = "badrachalam_forest"
	forest.name = "Badrachalam Forest"
	forest.location_type = LocationType.FOREST
	forest.spawn_position = Vector3(0, 2, 0)
	forest.npcs = ["Hanuman", "Monkey Scouts"]
	forest.description = "The sacred Badrachalam Forest where Rama searches for allies"

	var coast = Location.new()
	coast.id = "coast_to_lanka"
	coast.name = "Forest Coast"
	coast.location_type = LocationType.COAST
	coast.spawn_position = Vector3(1500, 2, 1500)
	coast.npcs = ["Scouts", "Monkeys"]
	coast.description = "The shoreline where the ocean route to Lanka begins"

	var village = Location.new()
	village.id = "monkey_village"
	village.name = "Monkey Village"
	village.location_type = LocationType.VILLAGE
	village.spawn_position = Vector3(-1500, 2, 1000)
	village.npcs = ["Elder Monkeys", "Village Scouts"]
	village.description = "The settlement of the monkey kingdom"

	locations["badrachalam_forest"] = forest
	locations["coast_to_lanka"] = coast
	locations["monkey_village"] = village

	current_location = forest

func get_location(location_id: String) -> Location:
	return locations.get(location_id, null)

func change_location(location_id: String) -> bool:
	if not locations.has(location_id):
		return false

	current_location = locations[location_id]
	location_changed.emit(current_location)
	return true

func get_current_location() -> Location:
	return current_location

func get_all_locations() -> Array:
	return locations.values()

func get_location_description(location_id: String) -> String:
	if locations.has(location_id):
		return locations[location_id].description
	return ""
