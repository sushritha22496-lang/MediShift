extends BaseSystemSimple

class_name CaravanSimple

class Caravan:
	var id: String
	var name: String
	var merchant_name: String
	var current_location: String
	var inventory: Dictionary
	var last_seen_day: int
	func _init(p_id: String, p_name: String, p_merchant: String) -> void:
		id = p_id
		name = p_name
		merchant_name = p_merchant
		current_location = "market"
		inventory = {}
		last_seen_day = 0

var caravans: Array[Caravan] = []

signal caravan_encountered(caravan: Caravan)
signal caravan_departed(caravan_id: String)
signal caravan_arrived(caravan_id: String, location: String)

func _ready() -> void:
	set_state("active_caravans", [])
	set_state("caravan_visits", {})
	set_state("caravan_visit_history", [])
	set_state("trade_history", [])
	set_state("caravan_location_tracking", {})
	set_state("merchant_preference", {})
	set_state("caravan_statistics", {})
	_initialize_caravans()

func _initialize_caravans() -> void:
	caravans = [
		Caravan.new("c1", "Eastern Traders", "Merchant Rajesh"),
		Caravan.new("c2", "Sacred Route Caravan", "Captain Vikram"),
		Caravan.new("c3", "Mountain Passage Merchants", "Elder Priya")
	]
	for caravan in caravans:
		caravan.inventory = {
			"health_potion": 20,
			"mana_potion": 15,
			"rare_gem": 5
		}

func encounter_caravan(caravan_id: String) -> bool:
	var caravan = _get_caravan(caravan_id)
	if caravan:
		var active = get_state("active_caravans", [])
		if caravan_id not in active:
			active.append(caravan_id)
			set_state("active_caravans", active)
		_record_visit_history(caravan_id)
		_record_merchant_preference(caravan.merchant_name)
		caravan_encountered.emit(caravan)
		emit_event("caravan_encountered", caravan_id)
		return true
	return false

func depart_caravan(caravan_id: String, destination: String) -> bool:
	var caravan = _get_caravan(caravan_id)
	if caravan:
		caravan.current_location = destination
		_track_caravan_location(caravan_id, destination)
		caravan_departed.emit(caravan_id)
		emit_event("caravan_departed", caravan_id)
		await get_tree().create_timer(3.0).timeout
		caravan_arrived.emit(caravan_id, destination)
		emit_event("caravan_arrived", destination)
		return true
	return false

func trade_with_caravan(caravan_id: String, item: String, quantity: int) -> bool:
	var caravan = _get_caravan(caravan_id)
	if caravan and item in caravan.inventory:
		if caravan.inventory[item] >= quantity:
			caravan.inventory[item] -= quantity
			_record_trade_history(caravan_id, item, quantity)
			emit_event("trade_completed", caravan_id)
			return true
	return false

func get_caravan(caravan_id: String) -> Caravan:
	return _get_caravan(caravan_id)

func get_active_caravans() -> Array[Caravan]:
	var active_ids = get_state("active_caravans", [])
	var active: Array[Caravan] = []
	for c in caravans:
		if c.id in active_ids:
			active.append(c)
	return active

func get_caravan_at_location(location: String) -> Array[Caravan]:
	return caravans.filter(func(c): return c.current_location == location)

func get_caravan_text() -> String:
	var active = get_active_caravans()
	var text = "Active Caravans: %d\n" % active.size()
	for caravan in active.slice(0, 3):
		text += "%s - %s at %s\n" % [caravan.name, caravan.merchant_name, caravan.current_location]
	return text

func _get_caravan(caravan_id: String) -> Caravan:
	for caravan in caravans:
		if caravan.id == caravan_id:
			return caravan
	return null

func _record_visit_history(caravan_id: String) -> void:
	var history = get_state("caravan_visit_history", [])
	history.append({"caravan": caravan_id, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("caravan_visit_history", history)
	var visits = get_state("caravan_visits", {})
	visits[caravan_id] = visits.get(caravan_id, 0) + 1
	set_state("caravan_visits", visits)

func _record_trade_history(caravan_id: String, item: String, quantity: int) -> void:
	var history = get_state("trade_history", [])
	history.append({"caravan": caravan_id, "item": item, "quantity": quantity, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("trade_history", history)

func _track_caravan_location(caravan_id: String, location: String) -> void:
	var tracking = get_state("caravan_location_tracking", {})
	if caravan_id not in tracking:
		tracking[caravan_id] = []
	tracking[caravan_id].append({"location": location, "time": Time.get_ticks_msec()})
	set_state("caravan_location_tracking", tracking)

func _record_merchant_preference(merchant_name: String) -> void:
	var prefs = get_state("merchant_preference", {})
	prefs[merchant_name] = prefs.get(merchant_name, 0) + 1
	set_state("merchant_preference", prefs)

func get_caravan_visit_count(caravan_id: String) -> int:
	var visits = get_state("caravan_visits", {})
	return visits.get(caravan_id, 0)

func get_most_visited_caravan() -> String:
	var visits = get_state("caravan_visits", {})
	var max_caravan = ""
	var max_visits = 0
	for caravan_id in visits:
		if visits[caravan_id] > max_visits:
			max_visits = visits[caravan_id]
			max_caravan = caravan_id
	return max_caravan

func get_trade_history() -> Array:
	return get_state("trade_history", [])

func get_merchant_preference_count(merchant_name: String) -> int:
	var prefs = get_state("merchant_preference", {})
	return prefs.get(merchant_name, 0)

func update_caravan_statistics() -> void:
	var stats = get_state("caravan_statistics", {})
	stats["total_visits"] = get_state("caravan_visit_history", []).size()
	stats["total_trades"] = get_state("trade_history", []).size()
	stats["active_caravans"] = get_state("active_caravans", []).size()
	stats["most_visited"] = get_most_visited_caravan()
	set_state("caravan_statistics", stats)

func get_caravan_statistics() -> Dictionary:
	update_caravan_statistics()
	return get_state("caravan_statistics", {})
