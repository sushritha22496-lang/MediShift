extends Node3D

class_name EffectsSimple

var active_effects: Array[Node3D] = []
var effect_history: Array = []

signal effect_created(effect: Node3D)

func _record_effect(effect_type: String, position: Vector3) -> void:
	effect_history.append({"type": effect_type, "position": position, "time": Time.get_ticks_msec()})
	if effect_history.size() > 100:
		effect_history.pop_front()
	effect_created.emit(null)

func create_hit_effect(position: Vector3) -> void:
	var marker = Node3D.new()
	marker.global_position = position
	add_child(marker)
	active_effects.append(marker)
	_record_effect("hit", position)

	await get_tree().create_timer(0.5).timeout
	if marker and is_instance_valid(marker):
		marker.queue_free()
		active_effects.erase(marker)

func create_healing_effect(position: Vector3) -> void:
	var marker = Node3D.new()
	marker.global_position = position
	add_child(marker)
	active_effects.append(marker)
	_record_effect("healing", position)
	print("✨ Healing effect at %s" % position)

	await get_tree().create_timer(1.0).timeout
	if marker and is_instance_valid(marker):
		marker.queue_free()
		active_effects.erase(marker)

func create_explosion_effect(position: Vector3, radius: float = 5.0) -> void:
	var marker = Node3D.new()
	marker.global_position = position
	add_child(marker)
	active_effects.append(marker)
	_record_effect("explosion", position)
	print("💥 Explosion at %s with radius %.1f" % [position, radius])

	await get_tree().create_timer(1.5).timeout
	if marker and is_instance_valid(marker):
		marker.queue_free()
		active_effects.erase(marker)

func create_buff_effect(position: Vector3, buff_name: String) -> void:
	var marker = Node3D.new()
	marker.global_position = position
	add_child(marker)
	active_effects.append(marker)
	_record_effect("buff_%s" % buff_name, position)
	print("⚡ %s buff applied" % buff_name)

	await get_tree().create_timer(2.0).timeout
	if marker and is_instance_valid(marker):
		marker.queue_free()
		active_effects.erase(marker)

func create_damage_number(position: Vector3, damage: float, is_critical: bool = false) -> void:
	var color = Color.YELLOW if is_critical else Color.WHITE
	_record_effect("critical_damage" if is_critical else "damage", position)
	print("💥 Damage %.0f%s" % [damage, " (CRITICAL!)" if is_critical else ""])

	await get_tree().create_timer(1.0).timeout

func clear_all_effects() -> void:
	for effect in active_effects:
		if effect and is_instance_valid(effect):
			effect.queue_free()
	active_effects.clear()

func get_active_effects_count() -> int:
	return active_effects.size()

func get_effects_statistics() -> Dictionary:
	var type_counts = {}
	for entry in effect_history:
		type_counts[entry["type"]] = type_counts.get(entry["type"], 0) + 1
	return {
		"total_effects_created": effect_history.size(),
		"active_effects": active_effects.size(),
		"effect_type_counts": type_counts
	}
