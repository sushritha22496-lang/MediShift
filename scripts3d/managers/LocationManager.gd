extends Node3D

class_name LocationManager

class Location:
	var id: String
	var name: String
	var pos: Vector3
	var desc: String

	func _init(i: String, n: String, p: Vector3, d: String) -> void:
		id = i
		name = n
		pos = p
		desc = d

var locations: Dictionary = {}
var current: Location = null

signal location_changed(location: Location)

func _ready() -> void:
	var f = Location.new("forest", "Badrachalam Forest", Vector3(0, 2, 0), "Sacred forest where Rama seeks help")
	var c = Location.new("coast", "Forest Coast", Vector3(1500, 2, 1500), "Shoreline to Lanka")
	var v = Location.new("village", "Monkey Village", Vector3(-1500, 2, 1000), "Monkey settlement")
	locations = {"forest": f, "coast": c, "village": v}
	current = f

func change_location(loc_id: String) -> bool:
	if loc_id in locations:
		current = locations[loc_id]
		location_changed.emit(current)
		return true
	return false

func get_current() -> Location:
	return current
