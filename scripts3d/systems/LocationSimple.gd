extends Node

class_name LocationSimple

class Location:
	var id: String
	var name: String
	var description: String
	var position: Vector3
	var visited: bool = false

	func _init(p_id: String, p_name: String, p_desc: String, p_pos: Vector3) -> void:
		id = p_id
		name = p_name
		description = p_desc
		position = p_pos

var locations: Array[Location] = []
var current_location: Location = null

signal location_discovered(location: Location)
signal location_entered(location: Location)

func _ready() -> void:
	_initialize_locations()

func _initialize_locations() -> void:
	var loc1 = Location.new("forest", "Badrachalam Forest", "Ancient forest where Rama searches for Sita", Vector3(0, 0, 0))
	var loc2 = Location.new("village", "Settlements", "Small villages with merchants and NPCs", Vector3(100, 0, 100))
	var loc3 = Location.new("temple", "Temple", "Sacred temple for meditation and healing", Vector3(-150, 0, 50))
	var loc4 = Location.new("mountains", "Mountains", "Treacherous mountain peaks", Vector3(200, 50, -200))
	var loc5 = Location.new("river", "Sacred River", "The holy Godavari River", Vector3(0, 0, -200))

	locations = [loc1, loc2, loc3, loc4, loc5]
	current_location = loc1
	current_location.visited = true

func discover_location(location_id: String) -> bool:
	for location in locations:
		if location.id == location_id:
			if not location.visited:
				location.visited = true
				location_discovered.emit(location)
				print("📍 Discovered: %s" % location.name)
				return true
	return false

func enter_location(location_id: String) -> bool:
	for location in locations:
		if location.id == location_id:
			current_location = location
			location_entered.emit(location)
			print("📍 Entered: %s" % location.name)
			return true
	return false

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
	var text = "Locations:\n"
	for location in locations:
		var status = "✓" if location.visited else "?"
		text += "%s %s\n" % [status, location.name]
	return text
