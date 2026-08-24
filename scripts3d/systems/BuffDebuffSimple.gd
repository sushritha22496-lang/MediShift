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
	var stack_count: int
	var max_stacks: int
	var stat_modifiers: Dictionary
	var element: String
	var curable: bool
	var immunity_key: String
	func _init(p_id: String, p_name: String, p_type: String, p_power: float, p_duration: float, p_buff: bool, p_element: String = "none") -> void:
		id = p_id
		name = p_name
		effect_type = p_type
		power = p_power
		duration = p_duration
		remaining_time = p_duration
		is_buff = p_buff
		stack_count = 1
		max_stacks = 5
		stat_modifiers = {}
		element = p_element
		curable = not p_buff
		immunity_key = ""

signal buff_applied(effect: StatusEffect)
signal debuff_applied(effect: StatusEffect)
signal effect_expired(effect: StatusEffect)

func _ready() -> void:
	set_state("effects", [])
	set_state("immunities", [])
	set_state("effect_history", [])
	set_state("stat_modifier_history", [])
	set_state("immunity_history", [])
	set_state("effect_stacking_stats", {})
	set_state("duration_tracking", [])
	set_state("removal_tracking", [])
	set_state("buff_debuff_statistics", {})

func _process(delta: float) -> void:
	var effects = get_state("effects", []) as Array[StatusEffect]
	for i in range(effects.size() - 1, -1, -1):
		effects[i].remaining_time -= delta
		if effects[i].remaining_time <= 0:
			var expired = effects[i]
			effects.remove_at(i)
			effect_expired.emit(expired)
			emit_event("effect_expired", expired.id)

func apply_buff(buff_id: String, power: float, duration: float, element: String = "none") -> bool:
	if is_immune(buff_id):
		return false
	var effects = get_state("effects", []) as Array[StatusEffect]
	var existing = _get_effect_by_id(effects, buff_id)
	var effect = StatusEffect.new(buff_id, buff_id, "buff", power, duration, true, element)
	if existing and existing.stack_count < existing.max_stacks:
		existing.stack_count += 1
		existing.remaining_time = duration
		existing.power += power * 0.1
		_record_effect_stacking(buff_id, existing.stack_count)
	else:
		effects.append(effect)
	_record_effect_history(buff_id, "buff", power, duration)
	buff_applied.emit(effect)
	emit_event("buff_applied", buff_id)
	return true

func apply_debuff(debuff_id: String, power: float, duration: float, element: String = "none") -> bool:
	if is_immune(debuff_id):
		return false
	var effects = get_state("effects", []) as Array[StatusEffect]
	var existing = _get_effect_by_id(effects, debuff_id)
	var effect = StatusEffect.new(debuff_id, debuff_id, "debuff", power, duration, false, element)
	if existing and existing.stack_count < existing.max_stacks:
		existing.stack_count += 1
		existing.remaining_time = duration
		existing.power += power * 0.15
		_record_effect_stacking(debuff_id, existing.stack_count)
	else:
		effects.append(effect)
	_record_effect_history(debuff_id, "debuff", power, duration)
	debuff_applied.emit(effect)
	emit_event("debuff_applied", debuff_id)
	return true

func remove_effect(effect_id: String) -> bool:
	var effects = get_state("effects", []) as Array[StatusEffect]
	for i in range(effects.size()):
		if effects[i].id == effect_id:
			var effect = effects[i]
			effects.remove_at(i)
			_record_removal(effect_id, "removed")
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
		var stack_info = " x%d" % effect.stack_count if effect.stack_count > 1 else ""
		text += "%s (%s)%s - %.1fs\n" % [effect.name, type, stack_info, effect.remaining_time]
	return text if not effects.is_empty() else "Active Effects: None"

func add_immunity(immunity_key: String, duration: float) -> void:
	var immunities = get_state("immunities", [])
	immunities.append({"key": immunity_key, "remaining": duration})
	if immunities.size() > 50:
		immunities.pop_front()
	set_state("immunities", immunities)
	_record_immunity_history(immunity_key, duration)

func is_immune(immunity_key: String) -> bool:
	var immunities = get_state("immunities", [])
	for immunity in immunities:
		if immunity["key"] == immunity_key:
			return true
	return false

func remove_immunity(immunity_key: String) -> void:
	var immunities = get_state("immunities", [])
	for i in range(immunities.size() - 1, -1, -1):
		if immunities[i]["key"] == immunity_key:
			immunities.remove_at(i)
	set_state("immunities", immunities)

func cure_effect(effect_id: String) -> bool:
	var effects = get_state("effects", []) as Array[StatusEffect]
	for i in range(effects.size()):
		if effects[i].id == effect_id and effects[i].curable:
			var effect = effects[i]
			effects.remove_at(i)
			_record_removal(effect_id, "cured")
			effect_expired.emit(effect)
			emit_event("effect_cured", effect_id)
			return true
	return false

func _get_effect_by_id(effects: Array[StatusEffect], effect_id: String) -> StatusEffect:
	for effect in effects:
		if effect.id == effect_id:
			return effect
	return null

func get_stat_modifier(stat: String) -> float:
	var effects = get_state("effects", []) as Array[StatusEffect]
	var total_mod = 0.0
	for effect in effects:
		if stat in effect.stat_modifiers:
			total_mod += effect.stat_modifiers[stat] * effect.stack_count
	return total_mod

func _record_effect_history(effect_id: String, effect_type: String, power: float, duration: float) -> void:
	var history = get_state("effect_history", [])
	history.append({"effect": effect_id, "type": effect_type, "power": power, "duration": duration, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("effect_history", history)

func _record_effect_stacking(effect_id: String, stack_count: int) -> void:
	var stats = get_state("effect_stacking_stats", {})
	if effect_id not in stats:
		stats[effect_id] = {"max_stacks": 0, "times_stacked": 0}
	stats[effect_id]["max_stacks"] = maxf(stats[effect_id]["max_stacks"], stack_count)
	stats[effect_id]["times_stacked"] += 1
	set_state("effect_stacking_stats", stats)

func _record_immunity_history(immunity_key: String, duration: float) -> void:
	var history = get_state("immunity_history", [])
	history.append({"immunity": immunity_key, "duration": duration, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("immunity_history", history)

func _record_removal(effect_id: String, reason: String) -> void:
	var tracking = get_state("removal_tracking", [])
	tracking.append({"effect": effect_id, "reason": reason, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("removal_tracking", tracking)

func get_effect_history() -> Array:
	return get_state("effect_history", [])

func get_immunity_history() -> Array:
	return get_state("immunity_history", [])

func get_max_stack_count(effect_id: String) -> int:
	var stats = get_state("effect_stacking_stats", {})
	if effect_id in stats:
		return stats[effect_id]["max_stacks"]
	return 0

func update_buff_debuff_statistics() -> void:
	var stats = get_state("buff_debuff_statistics", {})
	var effects = get_state("effects", []) as Array[StatusEffect]
	var buffs = 0
	var debuffs = 0
	for effect in effects:
		if effect.is_buff:
			buffs += 1
		else:
			debuffs += 1
	stats["active_buffs"] = buffs
	stats["active_debuffs"] = debuffs
	stats["total_effects"] = effects.size()
	stats["removals"] = get_state("removal_tracking", []).size()
	set_state("buff_debuff_statistics", stats)

func get_buff_debuff_statistics() -> Dictionary:
	update_buff_debuff_statistics()
	return get_state("buff_debuff_statistics", {})
