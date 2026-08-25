extends BaseSystemSimple

class_name FameSimple

signal fame_changed(faction: String, amount: float)
signal new_rank_achieved(faction: String, rank: String)
signal rank_lost(faction: String, old_rank: String)

var factions = ["warriors", "mages", "rangers", "merchants", "monks"]
var ranks = ["outcast", "unknown", "known", "respected", "legendary"]
var faction_multipliers = {"warriors": 1.0, "mages": 1.1, "rangers": 1.05, "merchants": 1.2, "monks": 1.0}
var faction_rivals = {"warriors": "merchants", "mages": "monks", "rangers": "mages", "merchants": "rangers", "monks": "warriors"}

func _ready() -> void:
	set_state("fame", {})
	set_state("ranks", {})
	set_state("completed_quests", {})
	set_state("faction_perks", {})
	set_state("last_decay_time", Time.get_ticks_msec())
	set_state("fame_history", [])
	set_state("rank_change_history", [])
	set_state("perk_grant_history", [])
	set_state("faction_statistics", {})
	for faction in factions:
		var fame_state = get_state("fame", {})
		fame_state[faction] = 0.0
		set_state("fame", fame_state)
		var ranks_state = get_state("ranks", {})
		ranks_state[faction] = "unknown"
		set_state("ranks", ranks_state)

func _record_fame_change(faction: String, amount: float, action_type: String) -> void:
	var history = get_state("fame_history", [])
	history.append({"faction": faction, "amount": amount, "action": action_type, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("fame_history", history)

func _record_rank_change(faction: String, old_rank: String, new_rank: String) -> void:
	var history = get_state("rank_change_history", [])
	history.append({"faction": faction, "old_rank": old_rank, "new_rank": new_rank, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("rank_change_history", history)

func _record_perk_grant(faction: String, perk: String) -> void:
	var history = get_state("perk_grant_history", [])
	history.append({"faction": faction, "perk": perk, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("perk_grant_history", history)

func add_fame(faction: String, amount: float, action_type: String = "quest") -> void:
	if faction not in factions:
		return
	var multiplier = faction_multipliers.get(faction, 1.0)
	var adjusted_amount = amount * multiplier * get_action_multiplier(action_type)
	var fame = get_state("fame", {})
	fame[faction] = fame.get(faction, 0.0) + adjusted_amount
	set_state("fame", fame)
	var rival = faction_rivals.get(faction, "")
	if rival:
		fame[rival] = fame.get(rival, 0.0) - (adjusted_amount * 0.3)
	_record_fame_change(faction, adjusted_amount, action_type)
	_update_rank(faction)
	fame_changed.emit(faction, adjusted_amount)
	emit_event("fame_added", {"faction": faction, "amount": adjusted_amount})

func get_action_multiplier(action_type: String) -> float:
	match action_type:
		"quest":
			return 1.0
		"combat":
			return 0.8
		"trade":
			return 1.2
		"exploration":
			return 0.6
		"event":
			return 1.5
	return 1.0

func remove_fame(faction: String, amount: float) -> void:
	if faction not in factions:
		return
	var fame = get_state("fame", {})
	fame[faction] = fame.get(faction, 0.0) - amount
	set_state("fame", fame)
	_record_fame_change(faction, -amount, "penalty")
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
		_record_rank_change(faction, old_rank, new_rank)
		if ranks.find(new_rank) > ranks.find(old_rank):
			new_rank_achieved.emit(faction, new_rank)
			_grant_faction_perk(faction, new_rank)
			emit_event("rank_achieved", faction)
		else:
			rank_lost.emit(faction, old_rank)
			emit_event("rank_lost", faction)

func _grant_faction_perk(faction: String, rank: String) -> void:
	var perks = get_state("faction_perks", {})
	if faction not in perks:
		perks[faction] = []
	var perk_map = {"known": "discount_5%", "respected": "discount_10%", "legendary": "unique_items_access"}
	if rank in perk_map:
		var perk = perk_map[rank]
		perks[faction].append(perk)
		set_state("faction_perks", perks)
		_record_perk_grant(faction, perk)
		emit_event("perk_granted", {"faction": faction, "perk": perk})

func can_access_faction_content(faction: String, required_rank: String) -> bool:
	var current_rank = get_rank(faction)
	return ranks.find(current_rank) >= ranks.find(required_rank)

func get_faction_discount(faction: String) -> float:
	var rank = get_rank(faction)
	match rank:
		"known":
			return 0.05
		"respected":
			return 0.10
		"legendary":
			return 0.20
	return 0.0

func get_fame_text() -> String:
	var text = "Faction Reputation:\n"
	for faction in factions:
		var rank = get_rank(faction)
		var fame = get_fame(faction)
		text += "%s (%s) - %.0f\n" % [faction.capitalize(), rank.capitalize(), fame]
	return text

func update_faction_statistics() -> void:
	var stats = get_state("faction_statistics", {})
	var all_fame = get_all_fame()
	var all_ranks = get_all_ranks()
	stats["total_fame_changes"] = get_state("fame_history", []).size()
	stats["total_rank_changes"] = get_state("rank_change_history", []).size()
	stats["total_perks_granted"] = get_state("perk_grant_history", []).size()
	var total_fame = 0.0
	for fame in all_fame.values():
		total_fame += fame
	stats["total_combined_fame"] = total_fame
	var legendary_count = 0
	for rank in all_ranks.values():
		if rank == "legendary":
			legendary_count += 1
	stats["legendary_factions"] = legendary_count
	var outcast_count = 0
	for rank in all_ranks.values():
		if rank == "outcast":
			outcast_count += 1
	stats["outcast_factions"] = outcast_count
	stats["average_fame"] = total_fame / float(factions.size()) if factions.size() > 0 else 0.0
	set_state("faction_statistics", stats)

func get_faction_statistics() -> Dictionary:
	update_faction_statistics()
	return get_state("faction_statistics", {})
