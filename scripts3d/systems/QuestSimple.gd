extends TrackableSimple

class_name QuestSimple

signal quest_added(track: Track)
signal quest_completed(track: Track)

func _ready() -> void:
	_initialize_quests()

func _initialize_quests() -> void:
	var quest1 = start("find_hanuman", "Find Hanuman", 1, "quest")
	quest1.rewards = {"experience": 100, "gold": 50}

	var quest2 = start("gather_fruits", "Gather Fruits", 5, "quest")
	quest2.rewards = {"experience": 50, "gold": 25}

	var quest3 = start("meet_merchant", "Meet the Merchant", 1, "quest")
	quest3.rewards = {"experience": 75, "gold": 100}

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
		text += "• %s (%d/%d)\n" % [quest.title, quest.progress, quest.target]
	return text if not active.is_empty() else "Active Quests: None"
