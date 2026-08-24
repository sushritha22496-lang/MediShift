extends Node

class_name QuestSimple

class Quest:
	var id: String
	var title: String
	var description: String
	var completed: bool = false
	var rewards: Dictionary = {}

	func _init(p_id: String, p_title: String, p_description: String) -> void:
		id = p_id
		title = p_title
		description = p_description

var active_quests: Array[Quest] = []
var completed_quests: Array[Quest] = []

signal quest_added(quest: Quest)
signal quest_completed(quest: Quest)
signal quest_updated

func _ready() -> void:
	_initialize_quests()

func _initialize_quests() -> void:
	var quest1 = Quest.new("find_hanuman", "Find Hanuman", "Search for Hanuman in the forest")
	quest1.rewards = {"experience": 100, "gold": 50}
	add_quest(quest1)

	var quest2 = Quest.new("gather_fruits", "Gather Fruits", "Collect 5 mangoes for the village")
	quest2.rewards = {"experience": 50, "gold": 25}
	add_quest(quest2)

	var quest3 = Quest.new("meet_merchant", "Meet the Merchant", "Find and speak with the merchant")
	quest3.rewards = {"experience": 75, "gold": 100}
	add_quest(quest3)

func add_quest(quest: Quest) -> void:
	active_quests.append(quest)
	quest_added.emit(quest)

func complete_quest(quest_id: String) -> bool:
	for i in range(active_quests.size()):
		if active_quests[i].id == quest_id:
			var quest = active_quests[i]
			quest.completed = true
			completed_quests.append(quest)
			active_quests.remove_at(i)
			quest_completed.emit(quest)
			return true
	return false

func get_quest(quest_id: String) -> Quest:
	for quest in active_quests:
		if quest.id == quest_id:
			return quest
	for quest in completed_quests:
		if quest.id == quest_id:
			return quest
	return null

func get_active_quests() -> Array[Quest]:
	return active_quests

func get_completed_quests() -> Array[Quest]:
	return completed_quests

func get_quest_list_text() -> String:
	var text = "Active Quests:\n"
	for quest in active_quests:
		text += "• %s - %s\n" % [quest.title, quest.description]
	if active_quests.is_empty():
		text = "Active Quests: None"
	return text
