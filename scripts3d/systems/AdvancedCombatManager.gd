extends Node3D

class_name AdvancedCombatManager

var combat_engine: CombatEngine
var current_battle: CombatEngine.BattleState
var player_characters: Array[Node3D] = []
var enemy_characters: Array[Node3D] = []
var is_in_combat: bool = false
var battle_camera: Camera3D = null

signal battle_start
signal round_complete
signal combat_end(victors: Array)

func _ready() -> void:
	combat_engine = CombatEngine.new()
	add_child(combat_engine)
	combat_engine.battle_started.connect(_on_battle_started)
	combat_engine.damage_dealt.connect(_on_damage_dealt)
	combat_engine.character_died.connect(_on_character_died)
	combat_engine.battle_ended.connect(_on_battle_ended)

func start_combat(players: Array[Node3D], enemies: Array[Node3D]) -> void:
	player_characters = players
	enemy_characters = enemies
	is_in_combat = true

	var player_chars: Array[CombatEngine.Character] = []
	for player in players:
		var char = CombatEngine.Character.new()
		char.name = player.get_character_name()
		char.max_health = 150.0
		char.health = 150.0
		char.attack = 20.0
		char.defense = 10.0
		char.speed = 12.0
		player_chars.append(char)

	var enemy_chars: Array[CombatEngine.Character] = []
	for enemy in enemies:
		var char = CombatEngine.Character.new()
		char.name = enemy.name if enemy.name else "Enemy"
		char.max_health = 60.0
		char.health = 60.0
		char.attack = 12.0
		char.defense = 5.0
		char.speed = 8.0
		enemy_chars.append(char)

	combat_engine.start_battle(player_chars, enemy_chars)
	battle_start.emit()
	await get_tree().create_timer(0.5).timeout
	_execute_combat_round()

func _execute_combat_round() -> void:
	if not combat_engine.current_battle or not combat_engine.current_battle.is_active:
		return

	var player_alive = player_characters.any(func(p): return p and p.is_node_ready())
	var enemy_alive = enemy_characters.any(func(e): return e and e.is_node_ready())

	if not player_alive or not enemy_alive:
		_end_combat()
		return

	for i in range(player_characters.size()):
		if i >= enemy_characters.size():
			break

		var attacker = player_characters[i]
		var defender = enemy_characters[i]

		if not attacker or not defender:
			continue

		_perform_attack(attacker, defender)
		await get_tree().create_timer(0.8).timeout

	round_complete.emit()
	await get_tree().create_timer(1.0).timeout
	_execute_combat_round()

func _perform_attack(attacker: Node3D, defender: Node3D) -> void:
	var attacker_char = CombatEngine.Character.new()
	attacker_char.attack = randf_range(15.0, 25.0)
	attacker_char.defense = randf_range(8.0, 12.0)

	var damage = attacker_char.attack * randf_range(0.8, 1.2)
	var critical = randf() < 0.2

	if critical:
		damage *= 1.5
		CombatVisualEffects.play_critical_hit(defender.global_position + Vector3(0, 1, 0), self)
	else:
		CombatVisualEffects.play_hit_effect(defender.global_position + Vector3(0, 1, 0), self, int(damage))

	CombatVisualEffects.play_attack_animation(attacker)

	if defender.has_node("Model"):
		var model = defender.get_node("Model")
		var shake_tween = create_tween()
		shake_tween.set_trans(Tween.TRANS_SINE)
		shake_tween.set_ease(Tween.EASE_IN_OUT)
		var original_pos = model.position
		shake_tween.tween_property(model, "position", original_pos + Vector3(randf_range(-0.2, 0.2), 0, 0), 0.05)
		shake_tween.tween_property(model, "position", original_pos, 0.05)

func _on_battle_started() -> void:
	print("Battle started!")

func _on_damage_dealt(attacker: CombatEngine.Character, defender: CombatEngine.Character, damage: float) -> void:
	print("%s dealt %.1f damage to %s" % [attacker.name, damage, defender.name])

func _on_character_died(character: CombatEngine.Character) -> void:
	print("%s has fallen!" % character.name)
	_fade_out_character(character)

func _on_battle_ended(winner: CombatEngine.Character) -> void:
	print("Battle ended! %s is victorious!" % winner.name)
	_end_combat()

func _fade_out_character(character: CombatEngine.Character) -> void:
	for node in get_tree().get_nodes_in_group("npcs"):
		if node.name == character.name:
			var tween = create_tween()
			if node.has_node("Model"):
				tween.tween_property(node.get_node("Model"), "modulate:a", 0.3, 1.0)

func _end_combat() -> void:
	is_in_combat = false
	combat_end.emit([])

func show_damage_popup(position: Vector3, damage: int) -> void:
	var label = Label3D.new()
	label.text = "%d" % damage
	label.position = position
	add_child(label)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", position.y + 2, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	await tween.finished
	label.queue_free()

func get_battle_status() -> Dictionary:
	if not combat_engine.current_battle:
		return {}

	var status = {
		"is_active": combat_engine.current_battle.is_active,
		"turn": combat_engine.current_battle.turn,
		"alive_combatants": 0
	}

	for char in combat_engine.current_battle.combatants:
		if char.is_alive:
			status.alive_combatants += 1

	return status
