extends Node

class_name NPCManagerSimple

class NPCData:
	var npc_name: String
	var npc_node: Node3D
	var relationship: float = 0.0
	var is_companion: bool = false
	var dialogue_count: int = 0

	func _init(p_name: String, p_node: Node3D) -> void:
		npc_name = p_name
		npc_node = p_node

var npcs: Dictionary = {}
var companions: Array[NPCData] = []

signal npc_registered(npc: NPCData)
signal relationship_changed(npc_name: String, relationship: float)
signal companion_added(npc: NPCData)

func register_npc(npc_name: String, npc_node: Node3D) -> void:
	if not npc_name in npcs:
		var npc_data = NPCData.new(npc_name, npc_node)
		npcs[npc_name] = npc_data
		npc_registered.emit(npc_data)
		print("Registered NPC: %s" % npc_name)

func get_npc(npc_name: String) -> NPCData:
	return npcs.get(npc_name, null)

func add_relationship(npc_name: String, amount: float) -> void:
	if npc_name in npcs:
		npcs[npc_name].relationship = clamp(npcs[npc_name].relationship + amount, -100.0, 100.0)
		relationship_changed.emit(npc_name, npcs[npc_name].relationship)
		print("%s relationship: %.1f" % [npc_name, npcs[npc_name].relationship])

func add_companion(npc_name: String) -> bool:
	if npc_name in npcs:
		var npc_data = npcs[npc_name]
		if not npc_data.is_companion:
			npc_data.is_companion = true
			companions.append(npc_data)
			companion_added.emit(npc_data)
			print("Added companion: %s" % npc_name)
			return true
	return false

func increment_dialogue(npc_name: String) -> void:
	if npc_name in npcs:
		npcs[npc_name].dialogue_count += 1

func get_relationship(npc_name: String) -> float:
	if npc_name in npcs:
		return npcs[npc_name].relationship
	return 0.0

func get_companions() -> Array[NPCData]:
	return companions

func get_all_npcs() -> Dictionary:
	return npcs

func get_npcs_text() -> String:
	var text = "NPCs [%d]:\n" % npcs.size()
	for npc_name in npcs:
		var npc = npcs[npc_name]
		var companion = "★" if npc.is_companion else " "
		text += "%s %s (Rel: %.0f)\n" % [companion, npc_name, npc.relationship]
	return text
