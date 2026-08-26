extends Node

class_name SimpleQuestSystem

class Quest:
	var id: String
	var title: String
	var description: String
	var objectives: Array[String] = []
	var completed: bool = false
	var reward: int = 0

	func _init(i: String, t: String, d: String, o: Array[String] = []) -> void:
		id = i
		title = t
		description = d
		objectives = o

var quests: Dictionary = {}
var active_quests: Array[String] = []

signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal objective_completed(quest_id: String, objective_index: int)

func _ready() -> void:
	_create_default_quests()

func _create_default_quests() -> void:
	var q1 = Quest.new(
		"meet_hanuman",
		"Meet Hanuman",
		"Find and convince Hanuman to help search for Sita",
		["Call for help", "Get Hanuman's attention", "Convince him to join"]
	)
	q1.reward = 100
	quests["meet_hanuman"] = q1

	var q2 = Quest.new(
		"gather_monkeys",
		"Gather Monkey Army",
		"Recruit monkey warriors for the quest",
		["Recruit 3 monkeys", "Recruit 5 monkeys", "Form team of 7"]
	)
	q2.reward = 250
	quests["gather_monkeys"] = q2

func start_quest(quest_id: String) -> bool:
	if quest_id in quests and quest_id not in active_quests:
		active_quests.append(quest_id)
		quest_started.emit(quest_id)
		return true
	return false

func complete_quest(quest_id: String) -> bool:
	if quest_id in quests:
		quests[quest_id].completed = true
		quest_completed.emit(quest_id)
		if quest_id in active_quests:
			active_quests.erase(quest_id)
		return true
	return false

func mark_objective_complete(quest_id: String, objective_index: int) -> void:
	if quest_id in quests and objective_index < quests[quest_id].objectives.size():
		objective_completed.emit(quest_id, objective_index)

func get_active_quests() -> Array[String]:
	return active_quests

func get_quest(quest_id: String) -> Quest:
	return quests.get(quest_id)
