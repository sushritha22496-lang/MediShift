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
	set_state("playthrough_history", [])
	set_state("unlock_history", [])
	set_state("meta_stat_history", [])
	set_state("achievement_tracking", {})
	set_state("unlock_requirements", {})
	set_state("progression_milestones", [])
	set_state("meta_progression_statistics", {})

func complete_playthrough() -> void:
	var count = get_state("playthrough_count", 0)
	count += 1
	set_state("playthrough_count", count)

	var meta = get_state("meta_stats", {})
	meta["new_game_plus_level"] = count
	set_state("meta_stats", meta)

	_record_playthrough_history(count)
	new_game_plus.emit(count)
	emit_event("playthrough_completed", count)

func unlock_feature(unlock_id: String, feature_name: String) -> void:
	var unlocks = get_state("unlocked_features", [])
	if unlock_id not in unlocks:
		unlocks.append(unlock_id)
		set_state("unlocked_features", unlocks)
		_record_unlock_history(unlock_id, feature_name)
		unlock_acquired.emit(unlock_id)
		emit_event("feature_unlocked", unlock_id)

func is_feature_unlocked(unlock_id: String) -> bool:
	var unlocks = get_state("unlocked_features", [])
	return unlock_id in unlocks

func add_meta_stat(stat: String, amount: float) -> void:
	var meta = get_state("meta_stats", {})
	if stat in meta:
		var old_value = meta[stat]
		meta[stat] = meta[stat] + amount
		set_state("meta_stats", meta)
		_record_meta_stat_change(stat, old_value, meta[stat])
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

func _record_playthrough_history(playthrough_number: int) -> void:
	var history = get_state("playthrough_history", [])
	history.append({"playthrough": playthrough_number, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("playthrough_history", history)

func _record_unlock_history(unlock_id: String, feature_name: String) -> void:
	var history = get_state("unlock_history", [])
	history.append({"unlock": unlock_id, "feature": feature_name, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("unlock_history", history)

func _record_meta_stat_change(stat: String, old_value: float, new_value: float) -> void:
	var history = get_state("meta_stat_history", [])
	history.append({"stat": stat, "old": old_value, "new": new_value, "time": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("meta_stat_history", history)

func track_achievement(achievement_id: String, progress: float) -> void:
	var achievements = get_state("achievement_tracking", {})
	achievements[achievement_id] = {"progress": progress, "unlocked": progress >= 1.0, "time": Time.get_ticks_msec()}
	set_state("achievement_tracking", achievements)

func get_achievement_progress(achievement_id: String) -> float:
	var achievements = get_state("achievement_tracking", {})
	if achievement_id in achievements:
		return achievements[achievement_id]["progress"]
	return 0.0

func set_unlock_requirement(unlock_id: String, requirement: Dictionary) -> void:
	var reqs = get_state("unlock_requirements", {})
	reqs[unlock_id] = requirement
	set_state("unlock_requirements", reqs)

func check_unlock_requirements(unlock_id: String) -> bool:
	var reqs = get_state("unlock_requirements", {})
	if unlock_id not in reqs:
		return true
	var req = reqs[unlock_id]
	var meta = get_state("meta_stats", {})
	for key in req:
		if key not in meta or meta[key] < req[key]:
			return false
	return true

func record_milestone(milestone_name: String, description: String) -> void:
	var milestones = get_state("progression_milestones", [])
	milestones.append({"name": milestone_name, "description": description, "time": Time.get_ticks_msec()})
	set_state("progression_milestones", milestones)
	emit_event("milestone_reached", milestone_name)

func get_playthrough_history() -> Array:
	return get_state("playthrough_history", [])

func get_unlock_history() -> Array:
	return get_state("unlock_history", [])

func update_meta_progression_statistics() -> void:
	var stats = get_state("meta_progression_statistics", {})
	stats["playthroughs"] = get_playthrough_count()
	stats["unlocks"] = get_state("unlocked_features", []).size()
	stats["achievements"] = get_state("achievement_tracking", {}).size()
	stats["milestones"] = get_state("progression_milestones", []).size()
	set_state("meta_progression_statistics", stats)

func get_meta_progression_statistics() -> Dictionary:
	update_meta_progression_statistics()
	return get_state("meta_progression_statistics", {})
