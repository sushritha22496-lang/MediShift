extends BaseSystemSimple

class_name RelationshipSimple

class Relationship:
	var npc_name: String
	var affection: float = 0.0
	var reputation: float = 0.0
	var interactions: int = 0
	var is_friend: bool = false
	var is_lover: bool = false
	func _init(p_name: String) -> void:
		npc_name = p_name

signal affection_changed(npc: String, new_value: float)
signal friendship_formed(npc: String)
signal romance_started(npc: String)

func _ready() -> void:
	var relationships = {}
	relationships["Hanuman"] = Relationship.new("Hanuman")
	relationships["Sita"] = Relationship.new("Sita")
	relationships["Monk Scout"] = Relationship.new("Monk Scout")
	set_state("relationships", relationships)

func add_affection(npc_name: String, amount: float) -> void:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		relationships[npc_name].affection = clamp(relationships[npc_name].affection + amount, -100.0, 100.0)
		relationships[npc_name].interactions += 1
		affection_changed.emit(npc_name, relationships[npc_name].affection)
		if relationships[npc_name].affection >= 50 and not relationships[npc_name].is_friend:
			_form_friendship(npc_name)
		elif relationships[npc_name].affection >= 80 and not relationships[npc_name].is_lover:
			_start_romance(npc_name)

func add_reputation(npc_name: String, amount: float) -> void:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		relationships[npc_name].reputation = clamp(relationships[npc_name].reputation + amount, -100.0, 100.0)

func _form_friendship(npc_name: String) -> void:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		relationships[npc_name].is_friend = true
		friendship_formed.emit(npc_name)
		emit_event("friendship_formed", npc_name)

func _start_romance(npc_name: String) -> void:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		relationships[npc_name].is_lover = true
		romance_started.emit(npc_name)
		emit_event("romance_started", npc_name)

func get_affection(npc_name: String) -> float:
	var relationships = get_state("relationships", {})
	return relationships[npc_name].affection if npc_name in relationships else 0.0

func get_reputation(npc_name: String) -> float:
	var relationships = get_state("relationships", {})
	return relationships[npc_name].reputation if npc_name in relationships else 0.0

func is_friend(npc_name: String) -> bool:
	var relationships = get_state("relationships", {})
	return relationships[npc_name].is_friend if npc_name in relationships else false

func is_lover(npc_name: String) -> bool:
	var relationships = get_state("relationships", {})
	return relationships[npc_name].is_lover if npc_name in relationships else false

func get_relationships_text() -> String:
	var relationships = get_state("relationships", {})
	var text = "Relationships:\n"
	for npc_name in relationships:
		var rel = relationships[npc_name]
		var status = "💕" if rel.is_lover else ("💚" if rel.is_friend else "  ")
		text += "%s %s (Aff: %.0f)\n" % [status, npc_name, rel.affection]
	return text
