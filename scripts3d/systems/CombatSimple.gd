extends BaseSystemSimple

class_name CombatSimple

@export var attack_range: float = 3.0
@export var attack_cooldown: float = 1.0
@export var attack_damage: float = 10.0

signal attack_performed(target: Node3D, damage: float)
signal damage_received(attacker: Node3D, damage: float, blocked: bool)
signal combo_started
signal combo_changed(combo_count: int)
signal stance_changed(stance: String)
signal parry_successful
signal combo_broken

func _ready() -> void:
	set_state("can_attack", true)
	set_state("cooldown_timer", 0.0)
	set_state("combo_counter", 0)
	set_state("last_attack_time", 0.0)
	set_state("armor_bonus", 0.0)
	set_state("resistance", {})
	set_state("current_stance", "normal")
	set_state("parry_ready", false)
	set_state("stance_bonuses", {"aggressive": 1.25, "defensive": 0.75, "balanced": 1.0})
	set_state("combo_timeout", 0.0)
	set_state("damage_log", [])
	set_state("total_damage_dealt", 0.0)
	set_state("damage_taken_log", [])
	set_state("attack_history", [])
	set_state("combo_history", [])
	set_state("stance_change_history", [])
	set_state("combat_statistics", {})

func _physics_process(delta: float) -> void:
	if not get_state("can_attack", true):
		var timer = get_state("cooldown_timer", 0.0) - delta
		set_state("cooldown_timer", timer)
		if timer <= 0.0:
			set_state("can_attack", true)

func _record_attack(attack_type: String, damage: float, combo: int) -> void:
	var history = get_state("attack_history", [])
	history.append({"type": attack_type, "damage": damage, "combo": combo, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("attack_history", history)

func _record_damage_taken(damage: float, attack_type: String, element: String) -> void:
	var history = get_state("damage_taken_log", [])
	history.append({"damage": damage, "type": attack_type, "element": element, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("damage_taken_log", history)

func _record_combo_change(combo: int) -> void:
	var history = get_state("combo_history", [])
	history.append({"combo": combo, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("combo_history", history)

func _record_stance_change(stance: String) -> void:
	var history = get_state("stance_change_history", [])
	history.append({"stance": stance, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("stance_change_history", history)

func perform_attack(attacker: Node3D, target: Node3D, attack_type: String = "melee", multiplier: float = 1.0) -> bool:
	if not get_state("can_attack", true):
		return false
	var distance = attacker.global_position.distance_to(target.global_position)
	if distance > attack_range:
		return false
	var damage = attack_damage * multiplier
	var combo = get_state("combo_counter", 0) + 1
	set_state("combo_counter", combo)
	var total = get_state("total_damage_dealt", 0.0)
	set_state("total_damage_dealt", total + damage)
	_record_attack(attack_type, damage, combo)
	_record_combo_change(combo)
	combo_changed.emit(combo)
	if combo == 1:
		combo_started.emit()
	set_state("last_attack_time", Time.get_ticks_msec())
	set_state("can_attack", false)
	set_state("cooldown_timer", attack_cooldown)
	attack_performed.emit(target, damage)
	emit_event("attack_performed", {"target": target, "damage": damage, "type": attack_type, "combo": combo})
	return true

func take_damage(damage: float, attack_type: String = "physical", element: String = "none") -> float:
	var armor = get_state("armor_bonus", 0.0)
	var resistance = get_state("resistance", {})
	var reduction = armor * 0.05
	var element_resist = resistance.get(element, 0.0)
	var final_dmg = damage * (1.0 - reduction) * (1.0 - element_resist)
	_record_damage_taken(final_dmg, attack_type, element)
	damage_received.emit(null, final_dmg, false)
	emit_event("damage_taken", final_dmg)
	return final_dmg

func reset_cooldown() -> void:
	set_state("can_attack", true)
	set_state("cooldown_timer", 0.0)

func reset_combo() -> void:
	set_state("combo_counter", 0)
	_record_combo_change(0)
	emit_event("combo_reset", 0)

func get_cooldown_remaining() -> float:
	return get_state("cooldown_timer", 0.0) if not get_state("can_attack", true) else 0.0

func set_armor_bonus(bonus: float) -> void:
	set_state("armor_bonus", bonus)
	emit_event("armor_changed", bonus)

func set_stance(new_stance: String) -> void:
	var valid = ["aggressive", "defensive", "balanced"]
	if new_stance in valid:
		set_state("current_stance", new_stance)
		_record_stance_change(new_stance)
		stance_changed.emit(new_stance)
		emit_event("stance_changed", new_stance)

func get_stance_damage_multiplier() -> float:
	var stance = get_state("current_stance", "normal")
	var bonuses = get_state("stance_bonuses", {})
	return bonuses.get(stance, 1.0)

func get_stance_defense_multiplier() -> float:
	var stance = get_state("current_stance", "normal")
	return 1.5 if stance == "defensive" else (0.75 if stance == "aggressive" else 1.0)

func attempt_parry() -> bool:
	if randf() < 0.4:
		set_state("parry_ready", true)
		parry_successful.emit()
		emit_event("parry", true)
		return true
	return false

func update_combo(delta: float) -> void:
	var timeout = get_state("combo_timeout", 0.0) - delta
	set_state("combo_timeout", timeout)
	if timeout <= 0.0 and get_state("combo_counter", 0) > 0:
		reset_combo()

func log_damage(damage: float, target: String = "") -> void:
	var log = get_state("damage_log", [])
	log.append({"damage": damage, "target": target, "time": Time.get_ticks_msec()})
	if log.size() > 100:
		log.pop_front()
	set_state("damage_log", log)
	var total = get_state("total_damage_dealt", 0.0)
	set_state("total_damage_dealt", total + damage)

func update_combat_statistics() -> void:
	var stats = get_state("combat_statistics", {})
	var attack_hist = get_state("attack_history", [])
	var damage_taken_hist = get_state("damage_taken_log", [])
	var combo_hist = get_state("combo_history", [])
	var stance_hist = get_state("stance_change_history", [])
	stats["total_attacks"] = attack_hist.size()
	stats["total_damage_dealt"] = get_state("total_damage_dealt", 0.0)
	stats["total_damage_taken"] = 0.0
	for entry in damage_taken_hist:
		stats["total_damage_taken"] += entry["damage"]
	stats["total_damage_taken_incidents"] = damage_taken_hist.size()
	stats["combo_changes"] = combo_hist.size()
	stats["stance_changes"] = stance_hist.size()
	stats["current_stance"] = get_state("current_stance", "normal")
	stats["current_combo"] = get_state("combo_counter", 0)
	set_state("combat_statistics", stats)

func get_combat_statistics() -> Dictionary:
	update_combat_statistics()
	return get_state("combat_statistics", {})
