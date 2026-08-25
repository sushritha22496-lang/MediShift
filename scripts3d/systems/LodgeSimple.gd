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
	set_state("room_rental_history", [])
	set_state("rest_efficiency", {})
	set_state("room_preference", {})
	set_state("total_rest_time", 0)
	set_state("healing_received_history", [])
	set_state("room_satisfaction", {})
	set_state("lodge_statistics", {})
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
			_record_rental_history(room_id, nights, total_cost)
			_update_room_preference(room_id)
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
		var total_time = get_state("total_rest_time", 0) + 1
		set_state("total_rest_time", total_time)
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
		_record_healing_received(room_id, healing)
		_update_rest_efficiency(room_id, healing)
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

func _record_rental_history(room_id: String, nights: int, cost: float) -> void:
	var history = get_state("room_rental_history", [])
	history.append({"room": room_id, "nights": nights, "cost": cost, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("room_rental_history", history)

func _update_room_preference(room_id: String) -> void:
	var prefs = get_state("room_preference", {})
	prefs[room_id] = prefs.get(room_id, 0) + 1
	set_state("room_preference", prefs)

func _record_healing_received(room_id: String, amount: float) -> void:
	var history = get_state("healing_received_history", [])
	history.append({"room": room_id, "healing": amount, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("healing_received_history", history)

func _update_rest_efficiency(room_id: String, healing: float) -> void:
	var efficiency = get_state("rest_efficiency", {})
	if room_id not in efficiency:
		efficiency[room_id] = {"total_healing": 0.0, "rest_count": 0}
	efficiency[room_id]["total_healing"] += healing
	efficiency[room_id]["rest_count"] += 1
	set_state("rest_efficiency", efficiency)

func get_room_preference_count(room_id: String) -> int:
	var prefs = get_state("room_preference", {})
	return prefs.get(room_id, 0)

func get_most_preferred_room() -> String:
	var prefs = get_state("room_preference", {})
	var max_room = ""
	var max_count = 0
	for room_id in prefs:
		if prefs[room_id] > max_count:
			max_count = prefs[room_id]
			max_room = room_id
	return max_room

func get_average_healing_per_rest(room_id: String) -> float:
	var efficiency = get_state("rest_efficiency", {})
	if room_id in efficiency and efficiency[room_id]["rest_count"] > 0:
		return efficiency[room_id]["total_healing"] / float(efficiency[room_id]["rest_count"])
	return 0.0

func set_room_satisfaction(room_id: String, satisfaction: float) -> void:
	var satisfaction_map = get_state("room_satisfaction", {})
	satisfaction_map[room_id] = clampf(satisfaction, 0.0, 1.0)
	set_state("room_satisfaction", satisfaction_map)

func get_room_satisfaction(room_id: String) -> float:
	var satisfaction_map = get_state("room_satisfaction", {})
	return satisfaction_map.get(room_id, 0.5)

func get_total_rest_time() -> int:
	return get_state("total_rest_time", 0)

func get_rental_history() -> Array:
	return get_state("room_rental_history", [])

func update_lodge_statistics() -> void:
	var stats = get_state("lodge_statistics", {})
	stats["total_spent"] = get_state("total_spent", 0.0)
	stats["total_nights"] = get_state("total_rest_time", 0)
	stats["rentals"] = get_state("room_rental_history", []).size()
	stats["most_used_room"] = get_most_preferred_room()
	stats["available_rooms"] = get_available_rooms().size()
	stats["total_rooms"] = rooms.size()
	stats["healing_events"] = get_state("healing_received_history", []).size()
	set_state("lodge_statistics", stats)

func get_lodge_statistics() -> Dictionary:
	update_lodge_statistics()
	return get_state("lodge_statistics", {})
