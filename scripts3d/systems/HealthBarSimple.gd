extends BaseSystemSimple

class_name HealthBarSimple

signal health_changed(current: float, max_health: float)
signal health_depleted
signal health_restored(amount: float)
signal shield_gained(amount: float)
signal shield_broken
signal status_effect_applied(effect: String)

func _ready() -> void:
	set_state("current_health", 100.0)
	set_state("max_health", 100.0)
	set_state("shield_health", 0.0)
	set_state("max_shield", 50.0)
	set_state("health_regen", 0.0)
	set_state("health_regen_delay", 0.0)
	set_state("status_effects", [])
	set_state("damage_history", [])
	set_state("total_damage_taken", 0.0)
	set_state("total_healing_done", 0.0)
	set_state("last_damage_type", "")
	set_state("health_restoration_history", [])
	set_state("shield_history", [])
	set_state("health_statistics", {})
	set_state("status_effect_history", [])

func _process(delta: float) -> void:
	var regen_delay = get_state("health_regen_delay", 0.0)
	if regen_delay > 0:
		regen_delay -= delta
		set_state("health_regen_delay", regen_delay)
	elif get_state("health_regen", 0.0) > 0:
		restore_health(get_state("health_regen", 0.0) * delta)

func take_damage(amount: float, damage_type: String = "physical") -> void:
	var shield = get_state("shield_health", 0.0)
	var remaining_damage = amount
	if shield > 0:
		var shield_absorbed = minf(shield, amount)
		shield = shield - shield_absorbed
		remaining_damage = amount - shield_absorbed
		set_state("shield_health", shield)
		if shield <= 0:
			shield_broken.emit()
			emit_event("shield_broken", "")
	var current = get_state("current_health", 100.0)
	current = maxf(0.0, current - remaining_damage)
	set_state("current_health", current)
	set_state("health_regen_delay", 3.0)
	set_state("last_damage_type", damage_type)
	var history = get_state("damage_history", [])
	history.append({"amount": amount, "type": damage_type, "timestamp": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("damage_history", history)
	var total = get_state("total_damage_taken", 0.0)
	set_state("total_damage_taken", total + remaining_damage)
	health_changed.emit(current, get_state("max_health", 100.0))
	emit_event("damage_taken", {"amount": remaining_damage, "type": damage_type, "shield_absorbed": minf(shield, amount)})
	if current <= 0:
		health_depleted.emit()
		emit_event("health_depleted", "")

func _record_health_restoration(amount: float, new_health: float) -> void:
	var history = get_state("health_restoration_history", [])
	history.append({"amount": amount, "new_health": new_health, "timestamp": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("health_restoration_history", history)

func _record_shield_change(amount: float, new_shield: float) -> void:
	var history = get_state("shield_history", [])
	history.append({"amount": amount, "new_shield": new_shield, "timestamp": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("shield_history", history)

func restore_health(amount: float) -> void:
	var current = get_state("current_health", 100.0)
	var max_hp = get_state("max_health", 100.0)
	var old_health = current
	current = minf(max_hp, current + amount)
	set_state("current_health", current)
	var total_healing = get_state("total_healing_done", 0.0)
	set_state("total_healing_done", total_healing + (current - old_health))
	_record_health_restoration(amount, current)
	health_changed.emit(current, max_hp)
	health_restored.emit(amount)
	emit_event("health_restored", {"amount": amount, "new_health": current})

func gain_shield(amount: float) -> void:
	var shield = get_state("shield_health", 0.0)
	var max_shield = get_state("max_shield", 50.0)
	shield = minf(max_shield, shield + amount)
	set_state("shield_health", shield)
	_record_shield_change(amount, shield)
	shield_gained.emit(shield)
	emit_event("shield_gained", {"amount": amount, "total_shield": shield})

func set_health(amount: float) -> void:
	var max_hp = get_state("max_health", 100.0)
	amount = clampf(amount, 0.0, max_hp)
	set_state("current_health", amount)
	health_changed.emit(amount, max_hp)
	emit_event("health_set", amount)

func set_max_health(amount: float) -> void:
	set_state("max_health", maxf(1.0, amount))
	var current = get_state("current_health", 100.0)
	health_changed.emit(current, amount)
	emit_event("max_health_set", amount)

func add_status_effect(effect_name: String, duration: float = 5.0) -> void:
	var effects = get_state("status_effects", [])
	effects.append({"name": effect_name, "duration": duration, "start_time": Time.get_ticks_msec()})
	set_state("status_effects", effects)
	var history = get_state("status_effect_history", [])
	history.append({"effect": effect_name, "duration": duration, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("status_effect_history", history)
	status_effect_applied.emit(effect_name)
	emit_event("status_effect_applied", effect_name)

func get_active_status_effects() -> Array:
	var effects = get_state("status_effects", [])
	var active: Array = []
	for effect in effects:
		var elapsed = (Time.get_ticks_msec() - effect["start_time"]) / 1000.0
		if elapsed < effect["duration"]:
			active.append(effect["name"])
	return active

func clear_status_effects() -> void:
	set_state("status_effects", [])
	emit_event("status_effects_cleared", "")

func get_health() -> float:
	return get_state("current_health", 100.0)

func get_max_health() -> float:
	return get_state("max_health", 100.0)

func get_shield() -> float:
	return get_state("shield_health", 0.0)

func get_max_shield() -> float:
	return get_state("max_shield", 50.0)

func get_health_percentage() -> float:
	var current = get_health()
	var max_hp = get_max_health()
	return (current / max_hp) * 100.0 if max_hp > 0 else 0.0

func get_shield_percentage() -> float:
	var shield = get_shield()
	var max_shield = get_max_shield()
	return (shield / max_shield) * 100.0 if max_shield > 0 else 0.0

func is_alive() -> bool:
	return get_health() > 0.0

func get_total_effective_health() -> float:
	return get_health() + get_shield()

func get_damage_history() -> Array:
	return get_state("damage_history", [])

func get_total_damage_taken() -> float:
	return get_state("total_damage_taken", 0.0)

func get_total_healing_done() -> float:
	return get_state("total_healing_done", 0.0)

func get_health_text() -> String:
	var hp = get_health()
	var max_hp = get_max_health()
	var shield = get_shield()
	var text = "HP: %.0f/%.0f" % [hp, max_hp]
	if shield > 0:
		text += " | Shield: %.0f" % shield
	var effects = get_active_status_effects()
	if not effects.is_empty():
		text += " | Effects: %d" % effects.size()
	return text

func update_health_statistics() -> void:
	var stats = get_state("health_statistics", {})
	var damage_hist = get_state("damage_history", [])
	var restoration_hist = get_state("health_restoration_history", [])
	var shield_hist = get_state("shield_history", [])
	stats["total_damage_incidents"] = damage_hist.size()
	stats["total_restoration_events"] = restoration_hist.size()
	stats["total_shield_events"] = shield_hist.size()
	stats["total_damage_taken"] = get_state("total_damage_taken", 0.0)
	stats["total_healing_done"] = get_state("total_healing_done", 0.0)
	stats["current_health"] = get_health()
	stats["current_shield"] = get_shield()
	if not damage_hist.is_empty():
		var avg_damage = 0.0
		for entry in damage_hist:
			avg_damage += entry["amount"]
		stats["average_damage_per_incident"] = avg_damage / float(damage_hist.size())
	var type_breakdown = {}
	for entry in damage_hist:
		type_breakdown[entry["type"]] = type_breakdown.get(entry["type"], 0) + 1
	stats["damage_type_breakdown"] = type_breakdown
	stats["status_effects_applied"] = get_state("status_effect_history", []).size()
	stats["is_alive"] = is_alive()
	set_state("health_statistics", stats)

func get_health_statistics() -> Dictionary:
	update_health_statistics()
	return get_state("health_statistics", {})
