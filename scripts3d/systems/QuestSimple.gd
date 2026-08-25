extends TrackableSimple

class_name QuestSimple

signal quest_added(track: Track)
signal quest_completed(track: Track)
signal quest_abandoned(quest_id: String)
signal quest_progress_updated(quest_id: String, progress: int)

func _ready() -> void:
	set_state("quest_markers", {})
	set_state("quest_branches", {})
	set_state("quest_history", [])
	_initialize_quests()

func _initialize_quests() -> void:
	var quest1 = start("find_hanuman", "Find Hanuman", 1, "quest")
	quest1.rewards = {"experience": 100, "gold": 50}
	quest1.metadata = {"difficulty": 2, "type": "main", "chain": "hanuman_arc"}

	var quest2 = start("gather_fruits", "Gather Fruits", 5, "quest")
	quest2.rewards = {"experience": 50, "gold": 25}
	quest2.metadata = {"difficulty": 1, "type": "side", "optional_target": 10, "bonus_reward": {"gold": 50}}

	var quest3 = start("meet_merchant", "Meet the Merchant", 1, "quest")
	quest3.rewards = {"experience": 75, "gold": 100}
	quest3.metadata = {"difficulty": 1, "type": "main", "branching": true}

func add_quest(title: String, description: String = "", quest_id: String = "") -> Track:
	var id = quest_id if quest_id else title.to_lower().replace(" ", "_")
	var track = start(id, title, 1, "quest")
	track.progress += 0
	return track

func _record_quest_event(quest_id: String, event: String) -> void:
	var history = get_state("quest_history", [])
	history.append({"quest": quest_id, "event": event, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("quest_history", history)

func complete_quest(quest_id: String) -> bool:
	var result = complete(quest_id)
	if result:
		_record_quest_event(quest_id, "completed")
	return result

func get_quest(quest_id: String) -> Track:
	for track in active:
		if track.id == quest_id:
			return track
	for track in completed:
		if track.id == quest_id:
			return track
	return null

func get_active_quests() -> Array[Track]:
	return active

func get_completed_quests() -> Array[Track]:
	return completed

func get_quest_list_text() -> String:
	var text = "Active Quests:\n"
	for quest in active:
		var pct = (quest.progress / float(quest.target)) * 100.0
		text += "• %s (%d/%d) [%d%%]\n" % [quest.title, quest.progress, quest.target, int(pct)]
	return text if not active.is_empty() else "Active Quests: None"

func check_optional_objective(quest_id: String) -> bool:
	var quest = get_quest(quest_id)
	if quest and "optional_target" in quest.metadata:
		var optional = quest.metadata.get("optional_target", 0)
		if quest.progress >= optional:
			var bonus = quest.metadata.get("bonus_reward", {})
			for key in bonus:
				var current = quest.rewards.get(key, 0)
				quest.rewards[key] = current + bonus[key]
			emit_event("optional_completed", quest_id)
			return true
	return false

func get_quest_difficulty(quest_id: String) -> int:
	var quest = get_quest(quest_id)
	if quest and "difficulty" in quest.metadata:
		return quest.metadata.get("difficulty", 1)
	return 1

func get_next_in_chain(quest_id: String) -> String:
	var quest = get_quest(quest_id)
	if quest and "chain" in quest.metadata:
		var chain = quest.metadata.get("chain", "")
		var difficulty = get_quest_difficulty(quest_id)
		return "%s_part_%d" % [chain, difficulty + 1]
	return ""

func scale_rewards(quest_id: String, player_level: int) -> void:
	var quest = get_quest(quest_id)
	if quest:
		var diff_mult = 1.0 + (get_quest_difficulty(quest_id) * 0.25)
		quest.rewards["experience"] = int(quest.rewards.get("experience", 0) * diff_mult * (player_level * 0.1 + 1.0))
		quest.rewards["gold"] = int(quest.rewards.get("gold", 0) * diff_mult)

func set_quest_marker(quest_id: String, location: Vector3) -> void:
	var markers = get_state("quest_markers", {})
	markers[quest_id] = location
	set_state("quest_markers", markers)
	emit_event("marker_set", quest_id)

func get_quest_marker(quest_id: String) -> Vector3:
	var markers = get_state("quest_markers", {})
	return markers.get(quest_id, Vector3.ZERO)

func update_quest_progress(quest_id: String, amount: int = 1) -> void:
	var quest = get_quest(quest_id)
	if quest and quest in active:
		quest.progress += amount
		quest_progress_updated.emit(quest_id, quest.progress)
		emit_event("progress_updated", {"quest": quest_id, "progress": quest.progress})
		if quest.progress >= quest.target:
			complete_quest(quest_id)

func track_quest_branch(quest_id: String, branch_id: String) -> void:
	var branches = get_state("quest_branches", {})
	if quest_id not in branches:
		branches[quest_id] = []
	branches[quest_id].append(branch_id)
	set_state("quest_branches", branches)

func abandon_quest(quest_id: String) -> bool:
	var quest = get_quest(quest_id)
	if quest and quest in active:
		active.erase(quest)
		_record_quest_event(quest_id, "abandoned")
		quest_abandoned.emit(quest_id)
		emit_event("quest_abandoned", quest_id)
		return true
	return false

func get_quest_branches(quest_id: String) -> Array:
	var branches = get_state("quest_branches", {})
	return branches.get(quest_id, [])

func get_quest_statistics() -> Dictionary:
	var history = get_state("quest_history", [])
	var abandoned_count = 0
	for entry in history:
		if entry["event"] == "abandoned":
			abandoned_count += 1
	return {
		"active_quests": active.size(),
		"completed_quests": completed.size(),
		"abandoned_quests": abandoned_count,
		"quest_events_logged": history.size(),
		"markers_set": get_state("quest_markers", {}).size(),
		"branches_tracked": get_state("quest_branches", {}).size()
	}
