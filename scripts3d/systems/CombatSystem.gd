extends Node3D

class_name CombatSystem

class Combatant:
	var name: String
	var health: int
	var max_health: int
	var attack_power: int
	var defense: int
	var speed: int

enum CombatState { IDLE, COMBAT, VICTORY, DEFEAT }

var current_state: CombatState = CombatState.IDLE
var player: Combatant = null
var enemy: Combatant = null
var combat_log: Array[String] = []

signal combat_started(player_name: String, enemy_name: String)
signal combat_ended(winner: String)
signal damage_dealt(attacker: String, defender: String, damage: int)
signal health_changed(combatant: String, health: int)

func _ready() -> void:
	pass

func start_combat(player_combatant: Combatant, enemy_combatant: Combatant) -> void:
	player = player_combatant
	enemy = enemy_combatant
	current_state = CombatState.COMBAT
	combat_log.clear()

	combat_started.emit(player.name, enemy.name)

func execute_attack(attacker: Combatant, defender: Combatant) -> int:
	var damage = calculate_damage(attacker, defender)
	defender.health = max(0, defender.health - damage)

	damage_dealt.emit(attacker.name, defender.name, damage)
	health_changed.emit(defender.name, defender.health)

	var log_entry = "%s attacked %s for %d damage!" % [attacker.name, defender.name, damage]
	combat_log.append(log_entry)

	if defender.health <= 0:
		end_combat(attacker.name)

	return damage

func calculate_damage(attacker: Combatant, defender: Combatant) -> int:
	var base_damage = attacker.attack_power
	var defense_reduction = defender.defense * 0.1
	var variance = randf_range(0.8, 1.2)

	var final_damage = int((base_damage - defense_reduction) * variance)
	return max(1, final_damage)

func player_turn(action: String = "attack") -> void:
	if current_state != CombatState.COMBAT or not player or not enemy:
		return

	match action:
		"attack":
			execute_attack(player, enemy)
			enemy_turn()
		"defend":
			player.defense += 2
			enemy_turn()
		"heal":
			player.health = min(player.max_health, player.health + 20)
			health_changed.emit(player.name, player.health)
			enemy_turn()

func enemy_turn() -> void:
	if current_state != CombatState.COMBAT or not enemy or not player:
		return

	var actions = ["attack", "attack", "defend", "heal"]
	var action = actions[randi() % actions.size()]

	match action:
		"attack":
			execute_attack(enemy, player)
		"defend":
			enemy.defense += 1
		"heal":
			enemy.health = min(enemy.max_health, enemy.health + 15)
			health_changed.emit(enemy.name, enemy.health)

func end_combat(winner: String) -> void:
	current_state = CombatState.VICTORY if winner == player.name else CombatState.DEFEAT
	combat_ended.emit(winner)

func get_combat_log() -> Array:
	return combat_log.duplicate()

func is_in_combat() -> bool:
	return current_state == CombatState.COMBAT

func heal_combatant(combatant: Combatant, amount: int) -> void:
	combatant.health = min(combatant.max_health, combatant.health + amount)
	health_changed.emit(combatant.name, combatant.health)
