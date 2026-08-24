extends BaseSystemSimple

class_name DamageIndicatorSimple

class DamageNumber:
	var value: float
	var position: Vector3
	var damage_type: String
	var lifetime: float
	var creation_time: float
	func _init(p_value: float, p_pos: Vector3, p_type: String = "normal", p_lifetime: float = 2.0) -> void:
		value = p_value
		position = p_pos
		damage_type = p_type
		lifetime = p_lifetime
		creation_time = Time.get_ticks_msec()

var active_indicators: Array[DamageNumber] = []

signal damage_displayed(value: float, damage_type: String)
signal critical_hit_displayed(value: float)
signal heal_displayed(value: float)

func _ready() -> void:
	set_state("total_damage_shown", 0.0)
	set_state("total_heals_shown", 0.0)
	set_state("critical_count", 0)

func _process(delta: float) -> void:
	var current_time = Time.get_ticks_msec()
	for i in range(active_indicators.size() - 1, -1, -1):
		var indicator = active_indicators[i]
		var elapsed = (current_time - indicator.creation_time) / 1000.0
		if elapsed >= indicator.lifetime:
			active_indicators.remove_at(i)

func show_damage(position: Vector3, damage: float, is_critical: bool = false) -> void:
	var damage_type = "critical" if is_critical else "normal"
	var indicator = DamageNumber.new(damage, position, damage_type)
	active_indicators.append(indicator)
	var total = get_state("total_damage_shown", 0.0)
	total += damage
	set_state("total_damage_shown", total)
	damage_displayed.emit(damage, damage_type)
	emit_event("damage_displayed", damage_type)
	if is_critical:
		var count = get_state("critical_count", 0)
		count += 1
		set_state("critical_count", count)
		critical_hit_displayed.emit(damage)
		emit_event("critical_hit", "")

func show_heal(position: Vector3, heal_amount: float) -> void:
	var indicator = DamageNumber.new(heal_amount, position, "heal")
	active_indicators.append(indicator)
	var total = get_state("total_heals_shown", 0.0)
	total += heal_amount
	set_state("total_heals_shown", total)
	heal_displayed.emit(heal_amount)
	emit_event("heal_displayed", heal_amount)

func get_active_indicators() -> Array[DamageNumber]:
	return active_indicators

func get_critical_count() -> int:
	return get_state("critical_count", 0)

func get_total_damage_shown() -> float:
	return get_state("total_damage_shown", 0.0)

func get_total_heals_shown() -> float:
	return get_state("total_heals_shown", 0.0)

func get_indicator_text() -> String:
	var text = "Damage Indicators\n"
	text += "Active: %d | Damage: %.0f | Heals: %.0f\n" % [active_indicators.size(), get_total_damage_shown(), get_total_heals_shown()]
	text += "Critical Hits: %d" % get_critical_count()
	return text
