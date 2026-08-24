extends Node3D

class_name SpawnManagerSimple

@export var spawn_radius: float = 50.0
@export var max_enemies: int = 5
@export var spawn_interval: float = 10.0
@export var world_bounds: Vector3 = Vector3(500, 50, 500)

var spawn_timer: float = 0.0
var spawned_entities: Array[Node3D] = []

signal entity_spawned(entity: Node3D)

func _process(delta: float) -> void:
	spawn_timer -= delta
	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		_spawn_random_entity()

	_clean_dead_entities()

func spawn_enemy_at(position: Vector3, enemy_scene: String) -> Node3D:
	if not ResourceLoader.exists(enemy_scene):
		return null

	var enemy = load(enemy_scene).instantiate()
	if enemy:
		enemy.global_position = position
		add_child(enemy)
		spawned_entities.append(enemy)
		entity_spawned.emit(enemy)
	return enemy

func spawn_collectible_at(position: Vector3, item_name: String, quantity: int = 1) -> Node3D:
	var collectible = Node3D.new()
	collectible.name = item_name
	collectible.global_position = position
	add_child(collectible)
	spawned_entities.append(collectible)
	entity_spawned.emit(collectible)
	return collectible

func _spawn_random_entity() -> void:
	if spawned_entities.size() >= max_enemies:
		return

	var spawn_pos = Vector3(
		randf_range(-world_bounds.x / 2, world_bounds.x / 2),
		world_bounds.y / 2,
		randf_range(-world_bounds.z / 2, world_bounds.z / 2)
	)

	var entity = Node3D.new()
	entity.name = "RandomEntity"
	entity.global_position = spawn_pos
	add_child(entity)
	spawned_entities.append(entity)

func _clean_dead_entities() -> void:
	for i in range(spawned_entities.size() - 1, -1, -1):
		if not is_instance_valid(spawned_entities[i]):
			spawned_entities.remove_at(i)

func get_spawned_count() -> int:
	return spawned_entities.size()

func clear_all() -> void:
	for entity in spawned_entities:
		if is_instance_valid(entity):
			entity.queue_free()
	spawned_entities.clear()
