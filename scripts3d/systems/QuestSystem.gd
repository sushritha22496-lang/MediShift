extends Node3D

class_name QuestSystem

enum QuestType { EXPLORATION, COLLECTION, NPC_MEETING, COMBAT }
enum QuestStatus { INACTIVE, ACTIVE, COMPLETED, FAILED }

class Quest:
	var id: String
	var title: String
	var description: String
	var objectives: Array[String]
	var quest_type: QuestType
	var status: QuestStatus = QuestStatus.INACTIVE
	var progress: int = 0
	var target_count: int = 1
	var reward_items: Array[String]
	var reward_xp: int = 100
	var required_level: int = 1
	var prerequisites: Array[String] = []
	var story_milestone: bool = false
	var location_hint: String = ""
	var npc_giver: String = ""
	var completed_at: float = 0.0

var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var current_objective: String = ""
var quest_history: Array[Dictionary] = []

signal quest_started(quest: Quest)
signal quest_progressed(quest: Quest)
signal quest_completed(quest: Quest)
signal objective_updated(objective: String)
signal milestone_reached(quest_id: String)
signal reward_earned(quest_id: String, xp: int, items: Array[String])

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

func start_quest(quest: Quest) -> bool:
	if active_quests.has(quest.id):
		return false

	# Check prerequisites
	for prereq in quest.prerequisites:
		if not is_quest_completed(prereq):
			print("Quest %s requires completed quest %s" % [quest.id, prereq])
			return false

	quest.status = QuestStatus.ACTIVE
	active_quests[quest.id] = quest
	quest_started.emit(quest)
	update_objective()
	return true

func progress_quest(quest_id: String, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return

	var quest = active_quests[quest_id]
	quest.progress += amount

	if quest.progress >= quest.target_count:
		complete_quest(quest_id)
	else:
		quest_progressed.emit(quest)

		# Check milestone (halfway)
		if quest.progress == quest.target_count / 2:
			milestone_reached.emit(quest_id)

		update_objective()

func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return

	var quest = active_quests[quest_id]
	quest.status = QuestStatus.COMPLETED
	quest.completed_at = Time.get_ticks_msec()
	completed_quests.append(quest_id)
	active_quests.erase(quest_id)

	# Record in history
	var history_entry = {
		"quest_id": quest_id,
		"title": quest.title,
		"completed_time": quest.completed_at,
		"reward_xp": quest.reward_xp
	}
	quest_history.append(history_entry)

	quest_completed.emit(quest)
	reward_earned.emit(quest_id, quest.reward_xp, quest.reward_items)

	if quest.story_milestone:
		print("Major story milestone reached: %s" % quest.title)

	update_objective()

func update_objective() -> void:
	if active_quests.is_empty():
		current_objective = "Find Hanuman"
		objective_updated.emit(current_objective)
		return

	var first_quest = active_quests.values()[0]
	if not first_quest.objectives.is_empty():
		current_objective = first_quest.objectives[0]
	else:
		current_objective = "%s: %d/%d" % [first_quest.title, first_quest.progress, first_quest.target_count]

	objective_updated.emit(current_objective)

func get_active_quests() -> Array:
	return active_quests.values()

func get_quest(quest_id: String) -> Quest:
	if active_quests.has(quest_id):
		return active_quests[quest_id]
	return null

func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests

func is_quest_active(quest_id: String) -> bool:
	return active_quests.has(quest_id)

func get_quest_history() -> Array[Dictionary]:
	return quest_history

func get_total_xp_earned() -> int:
	var total = 0
	for entry in quest_history:
		total += entry.reward_xp
	return total

func can_start_quest(quest_id: String, check_quest: Quest) -> bool:
	# Check if all prerequisites are completed
	for prereq in check_quest.prerequisites:
		if not is_quest_completed(prereq):
			return false
	return true
