extends BaseSystemSimple

class_name LodgeSimple

class Room:
	var id: String
	var name: String
	var quality: String
	var cost_per_night: float
	var healing_bonus: float
	var occupied: bool
	func _init(p_id: String, p_name: String, p_quality: String, p_cost: float, p_bonus: float) -> void:
		id = p_id
		name = p_name
		quality = p_quality
		cost_per_night = p_cost
		healing_bonus = p_bonus
		occupied = false

var rooms: Array[Room] = []

signal room_rented(room: Room, nights: int)
signal room_vacated(room_id: String)
signal night_passed
signal player_rested(hp_recovered: float)

func _ready() -> void:
	set_state("current_room", "")
	set_state("nights_left", 0)
	set_state("total_spent", 0.0)
	_initialize_rooms()

func _initialize_rooms() -> void:
	rooms = [
		Room.new("r1", "Small Room", "basic", 10.0, 0.5),
		Room.new("r2", "Comfortable Room", "standard", 25.0, 1.0),
		Room.new("r3", "Deluxe Suite", "luxury", 50.0, 1.5),
		Room.new("r4", "Royal Chamber", "elite", 100.0, 2.0)
	]

func rent_room(room_id: String, nights: int, gold: float) -> bool:
	var room = _get_room(room_id)
	if room and not room.occupied:
		var total_cost = room.cost_per_night * nights
		if gold >= total_cost:
			room.occupied = true
			set_state("current_room", room_id)
			set_state("nights_left", nights)
			var spent = get_state("total_spent", 0.0)
			spent += total_cost
			set_state("total_spent", spent)
			room_rented.emit(room, nights)
			emit_event("room_rented", room_id)
			return true
	return false

func pass_night() -> void:
	var room_id = get_state("current_room", "")
	if room_id == "":
		return
	var room = _get_room(room_id)
	if room:
		var nights = get_state("nights_left", 0)
		nights -= 1
		set_state("nights_left", nights)
		if nights <= 0:
			vacate_room()
		night_passed.emit()
		emit_event("night_passed", room_id)

func rest_in_room(player: Node) -> void:
	var room_id = get_state("current_room", "")
	if room_id == "":
		return
	var room = _get_room(room_id)
	if room and player.has_method("heal"):
		var healing = 50.0 * room.healing_bonus
		player.heal(healing)
		player_rested.emit(healing)
		emit_event("player_rested", room_id)

func vacate_room() -> void:
	var room_id = get_state("current_room", "")
	var room = _get_room(room_id)
	if room:
		room.occupied = false
		set_state("current_room", "")
		set_state("nights_left", 0)
		room_vacated.emit(room_id)
		emit_event("room_vacated", room_id)

func get_room(room_id: String) -> Room:
	return _get_room(room_id)

func get_available_rooms() -> Array[Room]:
	return rooms.filter(func(r): return not r.occupied)

func get_current_room() -> Room:
	var room_id = get_state("current_room", "")
	return _get_room(room_id) if room_id != "" else null

func get_lodge_text() -> String:
	var room = get_current_room()
	if room:
		var nights = get_state("nights_left", 0)
		return "%s\nNights left: %d\nHealing bonus: %.0f%%" % [room.name, nights, room.healing_bonus * 100.0]
	return "Lodge\nAvailable rooms: %d\nTotal spent: %.0f gold" % [get_available_rooms().size(), get_state("total_spent", 0.0)]

func _get_room(room_id: String) -> Room:
	for room in rooms:
		if room.id == room_id:
			return room
	return null
