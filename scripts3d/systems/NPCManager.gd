extends Node3D

class_name NPCManager

var npcs: Dictionary = {}
var active_npcs: Array[Node3D] = []

signal npc_spawned(npc: Node3D)
signal npc_despawned(npc: Node3D)
signal npc_dialogue_started(npc_name: String)

func _ready() -> void:
	pass

func register_npc(npc: Node3D, npc_id: String) -> void:
	if npcs.has(npc_id):
		return

	npcs[npc_id] = npc
	active_npcs.append(npc)
	npc_spawned.emit(npc)

	if npc.has_signal("dialogue_triggered"):
		npc.dialogue_triggered.connect(_on_npc_dialogue)

func unregister_npc(npc_id: String) -> void:
	if not npcs.has(npc_id):
		return

	var npc = npcs[npc_id]
	npcs.erase(npc_id)
	active_npcs.erase(npc)
	npc_despawned.emit(npc)

func get_npc(npc_id: String) -> Node3D:
	return npcs.get(npc_id, null)

func get_nearby_npcs(position: Vector3, radius: float) -> Array[Node3D]:
	var nearby = []
	for npc in active_npcs:
		if position.distance_to(npc.global_position) <= radius:
			nearby.append(npc)
	return nearby

func get_all_npcs() -> Array[Node3D]:
	return active_npcs.duplicate()

func _on_npc_dialogue(npc_name: String) -> void:
	npc_dialogue_started.emit(npc_name)

func spawn_npc_at(npc_scene: PackedScene, position: Vector3, npc_id: String) -> Node3D:
	var npc = npc_scene.instantiate()
	npc.global_position = position
	add_child(npc)
	register_npc(npc, npc_id)
	return npc

func despawn_npc(npc_id: String) -> void:
	var npc = get_npc(npc_id)
	if npc:
		unregister_npc(npc_id)
		npc.queue_free()
