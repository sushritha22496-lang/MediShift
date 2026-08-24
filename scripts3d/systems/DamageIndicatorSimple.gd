extends BaseSystemSimple

class_name DamageIndicatorSimple

class DamageNumber:
	var value: float
	var position: Vector3
	var damage_type: String
	var lifetime: float
	var creation_time: float
	var color: Color
	var scale: float = 1.0
	var float_speed: float = 1.0
	var source_entity: String = ""
	var merged_count: int = 1
	func _init(p_value: float, p_pos: Vector3, p_type: String = "normal", p_lifetime: float = 2.0) -> void:
		value = p_value
		position = p_pos
		damage_type = p_type
		lifetime = p_lifetime
		creation_time = Time.get_ticks_msec()
		color = _get_type_color(p_type)
	func _get_type_color(p_type: String) -> Color:
		var colors = {
			"normal": Color.WHITE,
			"critical": Color.YELLOW,
			"heal": Color.GREEN,
			"fire": Color.ORANGE_RED,
			"ice": Color.LIGHT_BLUE,
			"poison": Color.PURPLE,
			"lightning": Color.YELLOW,
			"holy": Color.GOLD,
			"dark": Color.DARK_GRAY
		}
		return colors.get(p_type, Color.WHITE)

var active_indicators: Array[DamageNumber] = []
var damage_type_colors: Dictionary = {}
var combo_counter: int = 0
var combo_timer: float = 0.0
var min_damage_threshold: float = 1.0

signal damage_displayed(value: float, damage_type: String)
signal critical_hit_displayed(value: float)
signal heal_displayed(value: float)
signal combo_milestone_reached(combo_count: int)

func _ready() -> void:
	set_state("total_damage_shown", 0.0)
	set_state("total_heals_shown", 0.0)
	set_state("critical_count", 0)
	set_state("indicator_history", [])
	set_state("highest_combo", 0)
	set_state("damage_source_tracking", {})
	set_state("dps_tracker", [])
	_initialize_type_colors()

func _initialize_type_colors() -> void:
	damage_type_colors = {
		"normal": Color.WHITE,
		"critical": Color.YELLOW,
		"heal": Color.GREEN,
		"fire": Color.ORANGE_RED,
		"ice": Color.LIGHT_BLUE,
		"poison": Color.PURPLE,
		"lightning": Color.YELLOW,
		"holy": Color.GOLD,
		"dark": Color.DARK_GRAY
	}

func _process(delta: float) -> void:
	combo_timer -= delta
	if combo_timer <= 0:
		combo_counter = 0
	var current_time = Time.get_ticks_msec()
	for i in range(active_indicators.size() - 1, -1, -1):
		var indicator = active_indicators[i]
		var elapsed = (current_time - indicator.creation_time) / 1000.0
		if elapsed >= indicator.lifetime:
			active_indicators.remove_at(i)
	_update_dps_tracker(delta)

func show_damage(position: Vector3, damage: float, is_critical: bool = false, damage_type: String = "physical", source: String = "") -> void:
	if damage < min_damage_threshold:
		return
	var display_type = "critical" if is_critical else damage_type
	var indicator = DamageNumber.new(damage, position, display_type)
	indicator.source_entity = source
	indicator.color = damage_type_colors.get(display_type, Color.WHITE)
	if is_critical:
		indicator.scale = 1.5
		indicator.float_speed = 1.3
	active_indicators.append(indicator)
	_update_combo(damage)
	var total = get_state("total_damage_shown", 0.0)
	total += damage
	set_state("total_damage_shown", total)
	_track_damage_source(source, damage)
	_add_to_dps(damage)
	damage_displayed.emit(damage, display_type)
	emit_event("damage_displayed", {"damage": damage, "type": display_type, "source": source})
	if is_critical:
		var count = get_state("critical_count", 0)
		count += 1
		set_state("critical_count", count)
		critical_hit_displayed.emit(damage)
		emit_event("critical_hit", {"damage": damage})

func show_damage_type(position: Vector3, damage: float, damage_type: String = "fire", source: String = "") -> void:
	show_damage(position, damage, false, damage_type, source)

func show_heal(position: Vector3, heal_amount: float, source: String = "") -> void:
	if heal_amount < min_damage_threshold:
		return
	var indicator = DamageNumber.new(heal_amount, position, "heal")
	indicator.source_entity = source
	indicator.color = damage_type_colors["heal"]
	active_indicators.append(indicator)
	_update_combo(heal_amount)
	var total = get_state("total_heals_shown", 0.0)
	total += heal_amount
	set_state("total_heals_shown", total)
	_track_damage_source(source, heal_amount)
	heal_displayed.emit(heal_amount)
	emit_event("heal_displayed", {"heal": heal_amount, "source": source})

func _update_combo(value: float) -> void:
	combo_counter += 1
	combo_timer = 2.0
	var highest = get_state("highest_combo", 0)
	if combo_counter > highest:
		set_state("highest_combo", combo_counter)
		if combo_counter % 5 == 0:
			combo_milestone_reached.emit(combo_counter)
			emit_event("combo_milestone", combo_counter)

func _track_damage_source(source: String, amount: float) -> void:
	if source.is_empty():
		return
	var tracking = get_state("damage_source_tracking", {})
	if source not in tracking:
		tracking[source] = 0
	tracking[source] += amount
	set_state("damage_source_tracking", tracking)

func _add_to_dps(damage: float) -> void:
	var dps = get_state("dps_tracker", [])
	dps.append({"damage": damage, "timestamp": Time.get_ticks_msec()})
	if dps.size() > 100:
		dps.pop_front()
	set_state("dps_tracker", dps)

func _update_dps_tracker(delta: float) -> void:
	var dps = get_state("dps_tracker", [])
	var now = Time.get_ticks_msec()
	while dps.size() > 0 and (now - dps[0]["timestamp"]) > 10000:
		dps.pop_front()
	set_state("dps_tracker", dps)

func get_current_dps() -> float:
	var dps = get_state("dps_tracker", [])
	if dps.is_empty():
		return 0.0
	var total_damage = 0.0
	for entry in dps:
		total_damage += entry["damage"]
	return total_damage / 10.0

func get_active_indicators() -> Array[DamageNumber]:
	return active_indicators

func get_critical_count() -> int:
	return get_state("critical_count", 0)

func get_total_damage_shown() -> float:
	return get_state("total_damage_shown", 0.0)

func get_total_heals_shown() -> float:
	return get_state("total_heals_shown", 0.0)

func get_combo_count() -> int:
	return combo_counter

func get_highest_combo() -> int:
	return get_state("highest_combo", 0)

func get_damage_source_tracking() -> Dictionary:
	return get_state("damage_source_tracking", {})

func get_top_damage_source() -> String:
	var sources = get_damage_source_tracking()
	var top_source = ""
	var top_damage = 0.0
	for source in sources.keys():
		if sources[source] > top_damage:
			top_damage = sources[source]
			top_source = source
	return top_source

func set_min_damage_threshold(threshold: float) -> void:
	min_damage_threshold = threshold

func get_indicator_text() -> String:
	var text = "Indicators: %d | Damage: %.0f | Heals: %.0f\n" % [active_indicators.size(), get_total_damage_shown(), get_total_heals_shown()]
	text += "Combo: %d/%d | Crits: %d | DPS: %.0f" % [combo_counter, get_highest_combo(), get_critical_count(), get_current_dps()]
	return text
