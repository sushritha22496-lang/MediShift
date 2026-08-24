extends Node3D

class_name RelationshipSystem

enum RelationshipType { HOSTILE, NEUTRAL, FRIENDLY, ALLIED }

class Relationship:
	var npc_name: String
	var reputation: int = 0
	var relationship_type: RelationshipType = RelationshipType.NEUTRAL
	var interactions: int = 0
	var likes: Array[String] = []
	var dislikes: Array[String] = []

var relationships: Dictionary = {}

signal reputation_changed(npc_name: String, new_reputation: int)
signal relationship_changed(npc_name: String, new_type: RelationshipType)

func _ready() -> void:
	pass

func initialize_relationship(npc_name: String) -> void:
	if relationships.has(npc_name):
		return

	var rel = Relationship.new()
	rel.npc_name = npc_name
	relationships[npc_name] = rel

func add_reputation(npc_name: String, amount: int) -> void:
	if not relationships.has(npc_name):
		initialize_relationship(npc_name)

	var rel = relationships[npc_name]
	rel.reputation += amount
	rel.interactions += 1

	_update_relationship_type(npc_name)
	reputation_changed.emit(npc_name, rel.reputation)

func get_reputation(npc_name: String) -> int:
	if not relationships.has(npc_name):
		return 0
	return relationships[npc_name].reputation

func get_relationship_type(npc_name: String) -> RelationshipType:
	if not relationships.has(npc_name):
		return RelationshipType.NEUTRAL
	return relationships[npc_name].relationship_type

func add_like(npc_name: String, item: String) -> void:
	if not relationships.has(npc_name):
		initialize_relationship(npc_name)

	var rel = relationships[npc_name]
	if item not in rel.likes:
		rel.likes.append(item)

func add_dislike(npc_name: String, item: String) -> void:
	if not relationships.has(npc_name):
		initialize_relationship(npc_name)

	var rel = relationships[npc_name]
	if item not in rel.dislikes:
		rel.dislikes.append(item)

func give_gift(npc_name: String, item: String) -> int:
	if not relationships.has(npc_name):
		initialize_relationship(npc_name)

	var rel = relationships[npc_name]
	var reputation_gain = 10

	if item in rel.likes:
		reputation_gain = 25
	elif item in rel.dislikes:
		reputation_gain = -20

	add_reputation(npc_name, reputation_gain)
	return reputation_gain

func _update_relationship_type(npc_name: String) -> void:
	if not relationships.has(npc_name):
		return

	var rel = relationships[npc_name]
	var old_type = rel.relationship_type

	if rel.reputation < -50:
		rel.relationship_type = RelationshipType.HOSTILE
	elif rel.reputation < 0:
		rel.relationship_type = RelationshipType.NEUTRAL
	elif rel.reputation < 50:
		rel.relationship_type = RelationshipType.FRIENDLY
	else:
		rel.relationship_type = RelationshipType.ALLIED

	if rel.relationship_type != old_type:
		relationship_changed.emit(npc_name, rel.relationship_type)

func get_relationship_status(npc_name: String) -> String:
	if not relationships.has(npc_name):
		return "Unknown"

	var rel = relationships[npc_name]

	match rel.relationship_type:
		RelationshipType.HOSTILE:
			return "Hostile"
		RelationshipType.NEUTRAL:
			return "Neutral"
		RelationshipType.FRIENDLY:
			return "Friendly"
		RelationshipType.ALLIED:
			return "Allied"
		_:
			return "Unknown"

func get_all_relationships() -> Dictionary:
	return relationships.duplicate()
