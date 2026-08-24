extends TrackableSimple

class_name QuestSimple

signal quest_added(track: Track)
signal quest_completed(track: Track)

func _ready() -> void:
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

func complete_quest(quest_id: String) -> bool:
	return complete(quest_id)

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
