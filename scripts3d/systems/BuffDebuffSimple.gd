extends Node

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

var active_effects: Array[StatusEffect] = []

signal buff_applied(effect: StatusEffect)
signal debuff_applied(effect: StatusEffect)
signal effect_expired(effect: StatusEffect)

func _process(delta: float) -> void:
	for i in range(active_effects.size() - 1, -1, -1):
		active_effects[i].remaining_time -= delta
		if active_effects[i].remaining_time <= 0:
			var expired = active_effects[i]
			active_effects.remove_at(i)
			effect_expired.emit(expired)

func apply_buff(buff_id: String, power: float, duration: float) -> void:
	var effect = StatusEffect.new(buff_id, buff_id, "buff", power, duration, true)
	active_effects.append(effect)
	buff_applied.emit(effect)
	print("✨ Buff applied: %s" % buff_id)

func apply_debuff(debuff_id: String, power: float, duration: float) -> void:
	var effect = StatusEffect.new(debuff_id, debuff_id, "debuff", power, duration, false)
	active_effects.append(effect)
	debuff_applied.emit(effect)
	print("⚠️ Debuff applied: %s" % debuff_id)

func remove_effect(effect_id: String) -> bool:
	for i in range(active_effects.size()):
		if active_effects[i].id == effect_id:
			var effect = active_effects[i]
			active_effects.remove_at(i)
			effect_expired.emit(effect)
			return true
	return false

func get_effect(effect_id: String) -> StatusEffect:
	for effect in active_effects:
		if effect.id == effect_id:
			return effect
	return null

func has_effect(effect_id: String) -> bool:
	return get_effect(effect_id) != null

func clear_all_effects() -> void:
	active_effects.clear()

func get_active_effects() -> Array[StatusEffect]:
	return active_effects

func get_effects_text() -> String:
	var text = "Active Effects [%d]:\n" % active_effects.size()
	for effect in active_effects:
		var type = "Buff" if effect.is_buff else "Debuff"
		text += "%s (%s) - %.1fs\n" % [effect.name, type, effect.remaining_time]
	if active_effects.is_empty():
		text = "Active Effects: None"
	return text
