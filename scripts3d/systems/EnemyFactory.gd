extends Node3D

class_name EnemyFactory

enum EnemyType { FOREST_DEMON, SEA_DEMON, LANKA_GUARD, RAVANA_COMMANDER, RAVANA_BOSS }

var enemy_scene = preload("res://scenes3d/enemies/demon_guard_3d.tscn")
var spawned_enemies: Array = []

signal enemy_spawned(enemy: Node3D)
signal wave_complete

func create_enemy(type: EnemyType, position: Vector3) -> Node3D:
	if not enemy_scene:
		push_error("Enemy scene not found")
		return null

	var enemy = enemy_scene.instantiate()
	enemy.global_position = position
	add_child(enemy)

	_configure_enemy(enemy, type)
	spawned_enemies.append(enemy)
	enemy_spawned.emit(enemy)

	return enemy

func _configure_enemy(enemy: Node3D, type: EnemyType) -> void:
	var health = 0
	var attack = 0
	var defense = 0
	var speed = 0
	var name_str = ""

	match type:
		EnemyType.FOREST_DEMON:
			health = 30
			attack = 5
			defense = 2
			speed = 1.0
			name_str = "Forest Demon"

		EnemyType.SEA_DEMON:
			health = 45
			attack = 8
			defense = 3
			speed = 1.2
			name_str = "Sea Demon"

		EnemyType.LANKA_GUARD:
			health = 60
			attack = 12
			defense = 5
			speed = 1.3
			name_str = "Lanka Guard"

		EnemyType.RAVANA_COMMANDER:
			health = 80
			attack = 15
			defense = 7
			speed = 1.4
			name_str = "Demon Commander"

		EnemyType.RAVANA_BOSS:
			health = 200
			attack = 25
			defense = 10
			speed = 1.5
			name_str = "Ravana - Demon King"

	if enemy.has_meta("character_name"):
		enemy.set_meta("character_name", name_str)
	if enemy.has_method("set_stats"):
		enemy.set_stats(health, attack, defense, speed)

func spawn_wave(positions: Array, enemy_types: Array) -> void:
	for i in range(positions.size()):
		if i < enemy_types.size():
			await get_tree().create_timer(0.5).timeout
			create_enemy(enemy_types[i], positions[i])

	wave_complete.emit()

func spawn_forest_ambush(position: Vector3, count: int = 3) -> void:
	var positions = []
	for i in range(count):
		var offset = Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		positions.append(position + offset)

	var types = []
	for i in range(count):
		types.append(EnemyType.FOREST_DEMON)

	await spawn_wave(positions, types)

func spawn_boss_encounter(position: Vector3) -> Node3D:
	var boss = create_enemy(EnemyType.RAVANA_BOSS, position)
	return boss

func get_all_enemies() -> Array:
	return spawned_enemies.filter(func(e): return is_instance_valid(e))

func clear_enemies() -> void:
	for enemy in spawned_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	spawned_enemies.clear()
