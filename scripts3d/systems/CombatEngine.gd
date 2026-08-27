extends Node

class_name CombatEngine

class Character:
	var name: String
	var max_health: float = 100.0
	var health: float = 100.0
	var attack: float = 10.0
	var defense: float = 5.0
	var speed: float = 1.0
	var level: int = 1
	var is_alive: bool = true

	func damage(amt: float) -> float:
		var dmg = max(1.0, amt - (defense * 0.5))
		health = max(0, health - dmg)
		is_alive = health > 0
		return dmg

	func heal(amt: float) -> void:
		health = min(max_health, health + amt)

	func get_health_percent() -> float:
		return health / max_health if max_health > 0 else 0.0

class BattleState:
	var combatants: Array[Character] = []
	var turn: int = 0
	var active_index: int = 0
	var winner: Character = null
	var is_active: bool = false

var current_battle: BattleState = null

signal battle_started
signal turn_changed(combatant: Character)
signal damage_dealt(attacker: Character, defender: Character, amount: float)
signal character_died(character: Character)
signal battle_ended(winner: Character)

func start_battle(player_team: Array[Character], enemy_team: Array[Character]) -> void:
	current_battle = BattleState.new()
	current_battle.combatants = player_team + enemy_team
	current_battle.is_active = true
	current_battle.turn = 0
	current_battle.active_index = 0
	battle_started.emit()

func execute_turn(attacker_idx: int, defender_idx: int) -> void:
	if not current_battle or not current_battle.is_active:
		return

	var attacker = current_battle.combatants[attacker_idx]
	var defender = current_battle.combatants[defender_idx]

	var damage = attacker.attack * randf_range(0.8, 1.2)
	var actual_damage = defender.damage(damage)

	damage_dealt.emit(attacker, defender, actual_damage)

	if not defender.is_alive:
		character_died.emit(defender)
		_check_battle_end()

func next_turn() -> void:
	if not current_battle or not current_battle.is_active:
		return

	current_battle.turn += 1
	current_battle.active_index = (current_battle.active_index + 1) % current_battle.combatants.size()

	var current = current_battle.combatants[current_battle.active_index]
	if current.is_alive:
		turn_changed.emit(current)

func _check_battle_end() -> void:
	if not current_battle:
		return

	var alive_count = 0
	var last_alive = null
	for combatant in current_battle.combatants:
		if combatant.is_alive:
			alive_count += 1
			last_alive = combatant

	if alive_count <= 1:
		current_battle.is_active = false
		current_battle.winner = last_alive
		battle_ended.emit(last_alive)

func get_battle_state() -> BattleState:
	return current_battle

func is_battle_active() -> bool:
	return current_battle and current_battle.is_active
