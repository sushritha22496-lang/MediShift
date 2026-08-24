extends BaseSystemSimple

class_name RelationshipSimple

class Relationship:
	var npc_name: String
	var affection: float = 0.0
	var reputation: float = 0.0
	var interactions: int = 0
	var is_friend: bool = false
	var is_lover: bool = false
	var relationship_tier: int = 0
	var memory: Array = []
	var gifts_given: int = 0
	var romance_level: int = 0
	var rival: String = ""
	var opinion_modifiers: Dictionary = {}
	var last_interaction_time: float = 0.0
	func _init(p_name: String) -> void:
		npc_name = p_name
		relationship_tier = 0
		romance_level = 0

signal affection_changed(npc: String, new_value: float)
signal friendship_formed(npc: String)
signal romance_started(npc: String)

func _ready() -> void:
	var relationships = {}
	relationships["Hanuman"] = Relationship.new("Hanuman")
	relationships["Sita"] = Relationship.new("Sita")
	relationships["Monk Scout"] = Relationship.new("Monk Scout")
	set_state("relationships", relationships)
	set_state("affection_history", {})
	set_state("gift_history", {})
	set_state("romance_advancement_history", [])
	set_state("opinion_modifier_history", [])
	set_state("interaction_statistics", {})
	set_state("relationship_statistics", {})

func add_affection(npc_name: String, amount: float, event: String = "") -> void:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		var rel = relationships[npc_name]
		var modifier = _calculate_affection_modifier(rel)
		var adjusted_amount = amount * modifier
		rel.affection = clamp(rel.affection + adjusted_amount, -100.0, 100.0)
		rel.interactions += 1
		rel.last_interaction_time = Time.get_ticks_msec()
		if event != "":
			rel.memory.append({"event": event, "time": Time.get_ticks_msec()})
		_record_affection_change(npc_name, rel.affection, adjusted_amount)
		affection_changed.emit(npc_name, rel.affection)
		_update_relationship_tier(npc_name)
		if rel.affection >= 50 and not rel.is_friend:
			_form_friendship(npc_name)
		elif rel.affection >= 80 and rel.romance_level >= 2:
			_start_romance(npc_name)

func _calculate_affection_modifier(rel: Relationship) -> float:
	var modifier = 1.0
	for opinion_key in rel.opinion_modifiers:
		modifier += rel.opinion_modifiers[opinion_key] * 0.1
	if rel.gifts_given > 5:
		modifier *= 1.1
	return modifier

func _update_relationship_tier(npc_name: String) -> void:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		var rel = relationships[npc_name]
		var new_tier = 0
		if rel.affection >= 20:
			new_tier = 1
		if rel.affection >= 50:
			new_tier = 2
		if rel.affection >= 75:
			new_tier = 3
		if rel.affection >= 90:
			new_tier = 4
		if new_tier > rel.relationship_tier:
			rel.relationship_tier = new_tier
			emit_event("relationship_tier_increased", {"npc": npc_name, "tier": new_tier})

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

func give_gift(npc_name: String, gift_quality: float = 1.0) -> bool:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		var rel = relationships[npc_name]
		var affection_gain = (10.0 + (rel.relationship_tier * 5.0)) * gift_quality
		add_affection(npc_name, affection_gain, "gift_received")
		rel.gifts_given += 1
		_record_gift_given(npc_name, gift_quality)
		emit_event("gift_given", {"npc": npc_name, "quality": gift_quality})
		return true
	return false

func advance_romance(npc_name: String) -> bool:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		var rel = relationships[npc_name]
		if rel.affection >= (50 + rel.romance_level * 15):
			rel.romance_level += 1
			_record_romance_advancement(npc_name, rel.romance_level)
			emit_event("romance_advanced", {"npc": npc_name, "level": rel.romance_level})
			return true
	return false

func add_opinion_modifier(npc_name: String, opinion_key: String, value: float) -> void:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		var rel = relationships[npc_name]
		rel.opinion_modifiers[opinion_key] = value
		_record_opinion_modifier(npc_name, opinion_key, value)
		emit_event("opinion_modified", {"npc": npc_name, "key": opinion_key, "value": value})

func get_memory_events(npc_name: String) -> Array:
	var relationships = get_state("relationships", {})
	if npc_name in relationships:
		return relationships[npc_name].memory
	return []

func get_romance_level(npc_name: String) -> int:
	var relationships = get_state("relationships", {})
	return relationships[npc_name].romance_level if npc_name in relationships else 0

func _record_affection_change(npc_name: String, affection: float, delta: float) -> void:
	var history = get_state("affection_history", {})
	if npc_name not in history:
		history[npc_name] = []
	history[npc_name].append({"value": affection, "delta": delta, "time": Time.get_ticks_msec()})
	if history[npc_name].size() > 50:
		history[npc_name].pop_front()
	set_state("affection_history", history)
	_update_interaction_statistics(npc_name)

func _record_gift_given(npc_name: String, quality: float) -> void:
	var history = get_state("gift_history", {})
	if npc_name not in history:
		history[npc_name] = []
	history[npc_name].append({"quality": quality, "time": Time.get_ticks_msec()})
	if history[npc_name].size() > 50:
		history[npc_name].pop_front()
	set_state("gift_history", history)

func _record_romance_advancement(npc_name: String, level: int) -> void:
	var history = get_state("romance_advancement_history", [])
	history.append({"npc": npc_name, "level": level, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("romance_advancement_history", history)

func _record_opinion_modifier(npc_name: String, opinion_key: String, value: float) -> void:
	var history = get_state("opinion_modifier_history", [])
	history.append({"npc": npc_name, "key": opinion_key, "value": value, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("opinion_modifier_history", history)

func _update_interaction_statistics(npc_name: String) -> void:
	var stats = get_state("interaction_statistics", {})
	if npc_name not in stats:
		stats[npc_name] = {"total_interactions": 0, "affection_changes": 0}
	stats[npc_name]["total_interactions"] += 1
	stats[npc_name]["affection_changes"] += 1
	set_state("interaction_statistics", stats)

func update_relationship_statistics() -> void:
	var stats = get_state("relationship_statistics", {})
	var relationships = get_state("relationships", {})
	var friends = 0
	var lovers = 0
	for npc_name in relationships:
		if relationships[npc_name].is_friend:
			friends += 1
		if relationships[npc_name].is_lover:
			lovers += 1
	stats["total_friends"] = friends
	stats["total_lovers"] = lovers
	stats["affection_history_size"] = get_state("affection_history", {}).size()
	stats["romance_advancements"] = get_state("romance_advancement_history", []).size()
	set_state("relationship_statistics", stats)

func get_relationship_statistics() -> Dictionary:
	update_relationship_statistics()
	return get_state("relationship_statistics", {})

func get_relationships_text() -> String:
	var relationships = get_state("relationships", {})
	var text = "Relationships:\n"
	for npc_name in relationships:
		var rel = relationships[npc_name]
		var status = "💕" if rel.is_lover else ("💚" if rel.is_friend else "  ")
		var tier = "T%d" % rel.relationship_tier
		text += "%s %s [%s] (Aff: %.0f)\n" % [status, npc_name, tier, rel.affection]
	return text
