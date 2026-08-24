extends BaseSystemSimple

class_name HealthBarSimple

signal health_changed(current: float, max_health: float)
signal health_depleted
signal health_restored(amount: float)

func _ready() -> void:
	set_state("current_health", 100.0)
	set_state("max_health", 100.0)
	set_state("health_regen", 0.0)
	set_state("health_regen_delay", 0.0)

func _process(delta: float) -> void:
	var regen_delay = get_state("health_regen_delay", 0.0)
	if regen_delay > 0:
		regen_delay -= delta
		set_state("health_regen_delay", regen_delay)
	elif get_state("health_regen", 0.0) > 0:
		restore_health(get_state("health_regen", 0.0) * delta)

func take_damage(amount: float) -> void:
	var current = get_state("current_health", 100.0)
	current = maxf(0.0, current - amount)
	set_state("current_health", current)
	set_state("health_regen_delay", 3.0)
	health_changed.emit(current, get_state("max_health", 100.0))
	emit_event("damage_taken", amount)
	if current <= 0:
		health_depleted.emit()
		emit_event("health_depleted", "")

func restore_health(amount: float) -> void:
	var current = get_state("current_health", 100.0)
	var max_hp = get_state("max_health", 100.0)
	current = minf(max_hp, current + amount)
	set_state("current_health", current)
	health_changed.emit(current, max_hp)
	health_restored.emit(amount)
	emit_event("health_restored", amount)

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

func get_health() -> float:
	return get_state("current_health", 100.0)

func get_max_health() -> float:
	return get_state("max_health", 100.0)

func get_health_percentage() -> float:
	var current = get_health()
	var max_hp = get_max_health()
	return (current / max_hp) * 100.0 if max_hp > 0 else 0.0

func is_alive() -> bool:
	return get_health() > 0.0

func get_health_text() -> String:
	return "HP: %.0f/%.0f (%.0f%%)" % [get_health(), get_max_health(), get_health_percentage()]
