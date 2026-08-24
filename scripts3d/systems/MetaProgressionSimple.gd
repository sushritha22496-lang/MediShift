extends BaseSystemSimple

class_name MetaProgressionSimple

signal new_game_plus(level: int)
signal unlock_acquired(unlock_id: String)
signal meta_stat_increased(stat: String)

func _ready() -> void:
	set_state("playthrough_count", 0)
	set_state("unlocked_features", [])
	set_state("meta_stats", {
		"total_playtime": 0.0,
		"total_enemies_defeated": 0,
		"total_bosses_defeated": 0,
		"unique_items_found": 0,
		"new_game_plus_level": 0
	})

func complete_playthrough() -> void:
	var count = get_state("playthrough_count", 0)
	count += 1
	set_state("playthrough_count", count)
	
	var meta = get_state("meta_stats", {})
	meta["new_game_plus_level"] = count
	set_state("meta_stats", meta)
	
	new_game_plus.emit(count)
	emit_event("playthrough_completed", count)

func unlock_feature(unlock_id: String, feature_name: String) -> void:
	var unlocks = get_state("unlocked_features", [])
	if unlock_id not in unlocks:
		unlocks.append(unlock_id)
		set_state("unlocked_features", unlocks)
		unlock_acquired.emit(unlock_id)
		emit_event("feature_unlocked", unlock_id)

func is_feature_unlocked(unlock_id: String) -> bool:
	var unlocks = get_state("unlocked_features", [])
	return unlock_id in unlocks

func add_meta_stat(stat: String, amount: float) -> void:
	var meta = get_state("meta_stats", {})
	if stat in meta:
		meta[stat] = meta[stat] + amount
		set_state("meta_stats", meta)
		meta_stat_increased.emit(stat)
		emit_event("meta_stat_increased", stat)

func get_meta_stat(stat: String) -> float:
	var meta = get_state("meta_stats", {})
	return meta.get(stat, 0.0)

func get_playthrough_count() -> int:
	return get_state("playthrough_count", 0)

func get_new_game_plus_level() -> int:
	return get_meta_stat("new_game_plus_level") as int

func get_meta_text() -> String:
	var text = "Meta Progression\n"
	text += "Playthroughs: %d\n" % get_playthrough_count()
	text += "Total Playtime: %.1f hours\n" % get_meta_stat("total_playtime")
	text += "Enemies Defeated: %.0f\n" % get_meta_stat("total_enemies_defeated")
	text += "Features Unlocked: %d\n" % get_state("unlocked_features", []).size()
	return text
