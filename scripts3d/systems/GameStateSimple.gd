extends Node

class_name GameStateSimple

@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var max_mana: float = 50.0

var current_health: float
var current_stamina: float
var current_mana: float
var experience: float = 0.0
var level: int = 1
var gold: float = 0.0

var damage_history: Array = []
var healing_history: Array = []
var level_up_history: Array = []
var gold_history: Array = []
var death_count: int = 0

signal health_changed(current: float, max_val: float)
signal stamina_changed(current: float, max_val: float)
signal mana_changed(current: float, max_val: float)
signal level_up(new_level: int)

func _ready() -> void:
	current_health = max_health
	current_stamina = max_stamina
	current_mana = max_mana

func take_damage(amount: float) -> void:
	current_health = maxf(current_health - amount, 0.0)
	damage_history.append({"amount": amount, "hp_after": current_health, "time": Time.get_ticks_msec()})
	if damage_history.size() > 50:
		damage_history.pop_front()
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		_on_death()

func heal(amount: float) -> void:
	current_health = minf(current_health + amount, max_health)
	healing_history.append({"amount": amount, "hp_after": current_health, "time": Time.get_ticks_msec()})
	if healing_history.size() > 50:
		healing_history.pop_front()
	health_changed.emit(current_health, max_health)

func use_stamina(amount: float) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		stamina_changed.emit(current_stamina, max_stamina)
		return true
	return false

func restore_stamina(amount: float) -> void:
	current_stamina = minf(current_stamina + amount, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)

func use_mana(amount: float) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, max_mana)
		return true
	return false

func restore_mana(amount: float) -> void:
	current_mana = minf(current_mana + amount, max_mana)
	mana_changed.emit(current_mana, max_mana)

func add_experience(amount: float) -> void:
	experience += amount
	if experience >= level * 100:
		_level_up()

func _level_up() -> void:
	level += 1
	current_health = max_health
	current_stamina = max_stamina
	current_mana = max_mana
	level_up_history.append({"level": level, "experience": experience, "time": Time.get_ticks_msec()})
	if level_up_history.size() > 50:
		level_up_history.pop_front()
	level_up.emit(level)

func add_gold(amount: float) -> void:
	gold += amount
	gold_history.append({"amount": amount, "total_after": gold, "time": Time.get_ticks_msec()})
	if gold_history.size() > 50:
		gold_history.pop_front()

func get_stats_text() -> String:
	var text = "Stats:\n"
	text += "Level: %d\n" % level
	text += "HP: %.0f/%.0f\n" % [current_health, max_health]
	text += "Exp: %.0f\n" % experience
	text += "Gold: %.0f\n" % gold
	return text

func _on_death() -> void:
	death_count += 1
	print("💀 Rama has fallen!")

func get_game_state_statistics() -> Dictionary:
	var total_damage = 0.0
	for entry in damage_history:
		total_damage += entry["amount"]
	var total_healing = 0.0
	for entry in healing_history:
		total_healing += entry["amount"]
	return {
		"current_level": level,
		"current_health": current_health,
		"total_damage_taken": total_damage,
		"total_healing_received": total_healing,
		"damage_events": damage_history.size(),
		"healing_events": healing_history.size(),
		"level_ups": level_up_history.size(),
		"gold_transactions": gold_history.size(),
		"current_gold": gold,
		"death_count": death_count
	}
