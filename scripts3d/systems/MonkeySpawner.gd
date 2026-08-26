extends Node3D

class_name MonkeySpawner

var monkey_scene = preload("res://scenes3d/npcs/monkey_npc_3d.tscn")
var spawned_monkeys: Array = []
var max_monkeys: int = 5

signal monkey_joined(monkey: MonkeyNPC)
signal team_complete

func _ready() -> void:
	add_to_group("spawners")

func spawn_monkey(position: Vector3, team_leader: Node3D = null) -> MonkeyNPC:
	if spawned_monkeys.size() >= max_monkeys:
		return null

	if not monkey_scene:
		push_error("Monkey scene not found")
		return null

	var monkey = monkey_scene.instantiate()
	monkey.global_position = position
	add_child(monkey)
	spawned_monkeys.append(monkey)
	monkey_joined.emit(monkey)

	if spawned_monkeys.size() >= max_monkeys:
		team_complete.emit()

	return monkey

func spawn_wave(positions: Array, leader: Node3D) -> void:
	for pos in positions:
		await get_tree().create_timer(0.3).timeout
		spawn_monkey(pos, leader)

func get_team_size() -> int:
	return spawned_monkeys.size()

func clear_monkeys() -> void:
	for monkey in spawned_monkeys:
		if monkey:
			monkey.queue_free()
	spawned_monkeys.clear()
