extends BaseSystemSimple

class_name InnSimple

@export var rest_cost: float = 50.0
@export var base_healing: float = 100.0

signal rest_started
signal rest_completed(health_recovered: float)
signal meal_purchased(meal_name: String, bonus: Dictionary)
signal room_upgraded(room_type: String)

class Room:
	var type: String
	var cost: float
	var healing_multiplier: float = 1.0
	var amenities: Array[String] = []
	var stat_bonuses: Dictionary = {}
	func _init(p_type: String, p_cost: float, p_multiplier: float = 1.0) -> void:
		type = p_type
		cost = p_cost
		healing_multiplier = p_multiplier

func _ready() -> void:
	set_state("is_resting", false)
	set_state("quality", "comfortable")
	set_state("rooms", {})
	set_state("total_rests", 0)
	set_state("inn_reputation", 0.0)
	set_state("current_room_type", "standard")
	set_state("status_effects_removed", {})
	set_state("rest_history", [])
	set_state("meal_purchase_history", [])
	set_state("room_upgrade_history", [])
	set_state("inn_statistics", {})
	_initialize_rooms()

func _initialize_rooms() -> void:
	var rooms = {}
	var standard = Room.new("standard", 50.0, 1.0)
	standard.amenities = ["bed", "water"]
	rooms["standard"] = standard

	var comfortable = Room.new("comfortable", 100.0, 1.3)
	comfortable.amenities = ["bed", "bath", "fire"]
	comfortable.stat_bonuses = {"strength": 0.5}
	rooms["comfortable"] = comfortable

	var luxurious = Room.new("luxurious", 200.0, 1.8)
	luxurious.amenities = ["bed", "bath", "fire", "food"]
	luxurious.stat_bonuses = {"strength": 1.0, "vitality": 1.0}
	rooms["luxurious"] = luxurious

	set_state("rooms", rooms)

func rest(player: Node3D, rest_hours: int = 1, room_type: String = "standard") -> bool:
	if get_state("is_resting", false):
		return false
	var rooms = get_state("rooms", {})
	var room = rooms.get(room_type, rooms["standard"])
	set_state("is_resting", true)
	set_state("current_room_type", room_type)
	rest_started.emit()
	emit_event("rest_started", room_type)
	await get_tree().create_timer(rest_hours * 0.5).timeout
	var healing = base_healing * rest_hours * room.healing_multiplier
	if player.has_method("heal"):
		player.heal(healing)
	_remove_status_effects()
	var total_rests = get_state("total_rests", 0) + 1
	set_state("total_rests", total_rests)
	set_state("is_resting", false)
	var history = get_state("rest_history", [])
	history.append({"room": room_type, "hours": rest_hours, "healing": healing, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("rest_history", history)
	rest_completed.emit(healing)
	emit_event("rest_completed", {"healing": healing, "room": room_type})
	return true

func _remove_status_effects() -> void:
	var effects_removed = get_state("status_effects_removed", {})
	var removed_count = effects_removed.get("poison", 0) + effects_removed.get("curse", 0)
	emit_event("status_effects_removed", removed_count)

func purchase_meal(meal_type: String) -> Dictionary:
	var bonus = {}
	match meal_type:
		"simple":
			bonus = {"healing": 50.0, "cost": 20.0}
		"hearty":
			bonus = {"healing": 100.0, "strength_bonus": 0.5, "cost": 50.0}
		"exotic":
			bonus = {"healing": 150.0, "strength_bonus": 1.0, "magic_bonus": 0.5, "cost": 100.0}
	if bonus.size() > 0:
		var history = get_state("meal_purchase_history", [])
		history.append({"meal": meal_type, "bonus": bonus, "time": Time.get_ticks_msec()})
		if history.size() > 50:
			history.pop_front()
		set_state("meal_purchase_history", history)
		meal_purchased.emit(meal_type, bonus)
		emit_event("meal_purchased", meal_type)
	return bonus

func upgrade_room(new_room_type: String) -> bool:
	var current = get_state("current_room_type", "standard")
	if current != new_room_type:
		set_state("current_room_type", new_room_type)
		var history = get_state("room_upgrade_history", [])
		history.append({"from": current, "to": new_room_type, "time": Time.get_ticks_msec()})
		if history.size() > 50:
			history.pop_front()
		set_state("room_upgrade_history", history)
		room_upgraded.emit(new_room_type)
		emit_event("room_upgraded", new_room_type)
		return true
	return false

func add_inn_reputation(amount: float) -> void:
	var rep = get_state("inn_reputation", 0.0)
	set_state("inn_reputation", rep + amount)
	emit_event("inn_reputation_changed", rep + amount)

func get_room_cost(room_type: String) -> float:
	var rooms = get_state("rooms", {})
	var room = rooms.get(room_type, rooms["standard"])
	return room.cost if room else rest_cost

func get_rest_cost() -> float:
	return rest_cost

func get_inn_text() -> String:
	var current_room = get_state("current_room_type", "standard")
	var rooms = get_state("rooms", {})
	var room = rooms.get(current_room, rooms["standard"])
	var total_rests = get_state("total_rests", 0)
	var healing = base_healing * room.healing_multiplier
	return "🏨 Inn | Room: %s | Rest: %d times\nCost: %.0f | Heal: %.0f HP/hour" % [current_room, total_rests, room.cost, healing]

func set_rest_quality(quality: String) -> void:
	set_state("quality", quality)
	emit_event("quality_set", quality)

func update_inn_statistics() -> void:
	var stats = get_state("inn_statistics", {})
	var meal_hist = get_state("meal_purchase_history", [])
	var total_healing = 0.0
	for entry in get_state("rest_history", []):
		total_healing += entry["healing"]
	stats["total_rests"] = get_state("total_rests", 0)
	stats["total_healing_from_rest"] = total_healing
	stats["meals_purchased"] = meal_hist.size()
	stats["room_upgrades"] = get_state("room_upgrade_history", []).size()
	stats["inn_reputation"] = get_state("inn_reputation", 0.0)
	stats["current_room"] = get_state("current_room_type", "standard")
	set_state("inn_statistics", stats)

func get_inn_statistics() -> Dictionary:
	update_inn_statistics()
	return get_state("inn_statistics", {})
