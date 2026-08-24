extends BaseSystemSimple

class_name FameSimple

signal fame_changed(faction: String, amount: float)
signal new_rank_achieved(faction: String, rank: String)

var factions = ["warriors", "mages", "rangers", "merchants", "monks"]
var ranks = ["outcast", "unknown", "known", "respected", "legendary"]

func _ready() -> void:
	set_state("fame", {})
	set_state("ranks", {})
	for faction in factions:
		var fame_state = get_state("fame", {})
		fame_state[faction] = 0.0
		set_state("fame", fame_state)
		var ranks_state = get_state("ranks", {})
		ranks_state[faction] = "unknown"
		set_state("ranks", ranks_state)

func add_fame(faction: String, amount: float) -> void:
	if faction not in factions:
		return
	var fame = get_state("fame", {})
	fame[faction] = fame.get(faction, 0.0) + amount
	set_state("fame", fame)
	_update_rank(faction)
	fame_changed.emit(faction, amount)
	emit_event("fame_added", faction)

func remove_fame(faction: String, amount: float) -> void:
	if faction not in factions:
		return
	var fame = get_state("fame", {})
	fame[faction] = fame.get(faction, 0.0) - amount
	set_state("fame", fame)
	_update_rank(faction)
	fame_changed.emit(faction, -amount)
	emit_event("fame_removed", faction)

func get_fame(faction: String) -> float:
	var fame = get_state("fame", {})
	return fame.get(faction, 0.0)

func get_rank(faction: String) -> String:
	var ranks_state = get_state("ranks", {})
	return ranks_state.get(faction, "unknown")

func get_all_fame() -> Dictionary:
	return get_state("fame", {})

func get_all_ranks() -> Dictionary:
	return get_state("ranks", {})

func _update_rank(faction: String) -> void:
	var fame = get_fame(faction)
	var old_rank = get_rank(faction)
	var new_rank = "unknown"

	if fame >= 500:
		new_rank = "legendary"
	elif fame >= 300:
		new_rank = "respected"
	elif fame >= 100:
		new_rank = "known"
	elif fame >= -100:
		new_rank = "unknown"
	else:
		new_rank = "outcast"

	if old_rank != new_rank:
		var ranks_state = get_state("ranks", {})
		ranks_state[faction] = new_rank
		set_state("ranks", ranks_state)
		new_rank_achieved.emit(faction, new_rank)
		emit_event("rank_achieved", faction)

func get_fame_text() -> String:
	var text = "Faction Reputation:\n"
	for faction in factions:
		var rank = get_rank(faction)
		var fame = get_fame(faction)
		text += "%s (%s) - %.0f\n" % [faction.capitalize(), rank.capitalize(), fame]
	return text
