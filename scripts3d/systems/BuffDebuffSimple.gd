extends BaseSystemSimple

class_name BuffDebuffSimple

class StatusEffect:
	var id: String
	var name: String
	var effect_type: String
	var power: float
	var duration: float
	var remaining_time: float
	var is_buff: bool
	func _init(p_id: String, p_name: String, p_type: String, p_power: float, p_duration: float, p_buff: bool) -> void:
		id = p_id
		name = p_name
		effect_type = p_type
		power = p_power
		duration = p_duration
		remaining_time = p_duration
		is_buff = p_buff

signal buff_applied(effect: StatusEffect)
signal debuff_applied(effect: StatusEffect)
signal effect_expired(effect: StatusEffect)

func _ready() -> void:
	set_state("effects", [])

func _process(delta: float) -> void:
	var effects = get_state("effects", []) as Array[StatusEffect]
	for i in range(effects.size() - 1, -1, -1):
		effects[i].remaining_time -= delta
		if effects[i].remaining_time <= 0:
			var expired = effects[i]
			effects.remove_at(i)
			effect_expired.emit(expired)

func apply_buff(buff_id: String, power: float, duration: float) -> void:
	var effect = StatusEffect.new(buff_id, buff_id, "buff", power, duration, true)
	var effects = get_state("effects", []) as Array[StatusEffect]
	effects.append(effect)
	buff_applied.emit(effect)
	emit_event("buff_applied", buff_id)

func apply_debuff(debuff_id: String, power: float, duration: float) -> void:
	var effect = StatusEffect.new(debuff_id, debuff_id, "debuff", power, duration, false)
	var effects = get_state("effects", []) as Array[StatusEffect]
	effects.append(effect)
	debuff_applied.emit(effect)
	emit_event("debuff_applied", debuff_id)

func remove_effect(effect_id: String) -> bool:
	var effects = get_state("effects", []) as Array[StatusEffect]
	for i in range(effects.size()):
		if effects[i].id == effect_id:
			var effect = effects[i]
			effects.remove_at(i)
			effect_expired.emit(effect)
			return true
	return false

func get_effect(effect_id: String) -> StatusEffect:
	var effects = get_state("effects", []) as Array[StatusEffect]
	for effect in effects:
		if effect.id == effect_id:
			return effect
	return null

func has_effect(effect_id: String) -> bool:
	return get_effect(effect_id) != null

func clear_all_effects() -> void:
	set_state("effects", [])

func get_active_effects() -> Array:
	return get_state("effects", [])

func get_effects_text() -> String:
	var effects = get_state("effects", []) as Array[StatusEffect]
	var text = "Active Effects [%d]:\n" % effects.size()
	for effect in effects:
		var type = "Buff" if effect.is_buff else "Debuff"
		text += "%s (%s) - %.1fs\n" % [effect.name, type, effect.remaining_time]
	return text if not effects.is_empty() else "Active Effects: None"
