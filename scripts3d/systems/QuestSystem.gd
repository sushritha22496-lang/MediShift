extends Node3D

class_name QuestSystem

enum QuestType { EXPLORATION, COLLECTION, NPC_MEETING, COMBAT }
enum QuestStatus { INACTIVE, ACTIVE, COMPLETED, FAILED }

class Quest:
	var id: String
	var title: String
	var description: String
	var quest_type: QuestType
	var status: QuestStatus = QuestStatus.INACTIVE
	var progress: int = 0
	var target_count: int = 1
	var reward_items: Array[String]
	var reward_xp: int = 100

var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var current_objective: String = ""

signal quest_started(quest: Quest)
signal quest_progressed(quest: Quest)
signal quest_completed(quest: Quest)
signal objective_updated(objective: String)

func _ready() -> void:
	pass

func create_quest(quest_id: String, title: String, description: String, quest_type: QuestType, target: int = 1) -> Quest:
	var quest = Quest.new()
	quest.id = quest_id
	quest.title = title
	quest.description = description
	quest.quest_type = quest_type
	quest.target_count = target
	return quest

func start_quest(quest: Quest) -> void:
	if active_quests.has(quest.id):
		return

	quest.status = QuestStatus.ACTIVE
	active_quests[quest.id] = quest
	quest_started.emit(quest)
	update_objective()

func progress_quest(quest_id: String, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return

	var quest = active_quests[quest_id]
	quest.progress += amount

	if quest.progress >= quest.target_count:
		complete_quest(quest_id)
	else:
		quest_progressed.emit(quest)
		update_objective()

func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return

	var quest = active_quests[quest_id]
	quest.status = QuestStatus.COMPLETED
	completed_quests.append(quest_id)
	active_quests.erase(quest_id)
	quest_completed.emit(quest)
	update_objective()

func update_objective() -> void:
	if active_quests.is_empty():
		current_objective = "Find Hanuman"
		objective_updated.emit(current_objective)
		return

	var first_quest = active_quests.values()[0]
	current_objective = "%s: %d/%d" % [first_quest.title, first_quest.progress, first_quest.target_count]
	objective_updated.emit(current_objective)

func get_active_quests() -> Array:
	return active_quests.values()

func get_quest(quest_id: String) -> Quest:
	return active_quests.get(quest_id, null)

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests
