extends Node

class_name EncounterSimple

class Encounter:
	var id: String
	var title: String
	var description: String
	var location: String
	var difficulty: String
	var reward_gold: float
	var encountered: bool = false

	func _init(p_id: String, p_title: String, p_desc: String, p_loc: String, p_diff: String) -> void:
		id = p_id
		title = p_title
		description = p_desc
		location = p_loc
		difficulty = p_diff

var encounters: Array[Encounter] = []
var active_encounter: Encounter = null

signal encounter_started(encounter: Encounter)
signal encounter_completed(encounter: Encounter)

func _ready() -> void:
	_initialize_encounters()

func _initialize_encounters() -> void:
	var enc1 = Encounter.new("bandit_ambush", "Bandit Ambush", "You're surrounded by bandits", "Forest", "Hard")
	enc1.reward_gold = 200

	var enc2 = Encounter.new("wild_beast", "Wild Beast", "A fierce beast attacks", "Mountains", "Very Hard")
	enc2.reward_gold = 300

	var enc3 = Encounter.new("merchant_meeting", "Merchant Meeting", "Meet a traveling merchant", "Road", "Easy")
	enc3.reward_gold = 50

	var enc4 = Encounter.new("lost_child", "Lost Child", "Find and help a lost child", "Village", "Easy")
	enc4.reward_gold = 100

	var enc5 = Encounter.new("sacred_ritual", "Sacred Ritual", "Witness an ancient ritual", "Temple", "Medium")
	enc5.reward_gold = 150

	encounters = [enc1, enc2, enc3, enc4, enc5]

func start_random_encounter() -> Encounter:
	var available = encounters.filter(func(e): return not e.encountered)
	if available.is_empty():
		return null

	var encounter = available[randi() % available.size()]
	encounter.encountered = true
	active_encounter = encounter
	encounter_started.emit(encounter)
	print("⚔️ Encounter: %s" % encounter.title)
	return encounter

func start_encounter(encounter_id: String) -> bool:
	for encounter in encounters:
		if encounter.id == encounter_id:
			encounter.encountered = true
			active_encounter = encounter
			encounter_started.emit(encounter)
			return true
	return false

func complete_encounter() -> void:
	if active_encounter:
		encounter_completed.emit(active_encounter)
		active_encounter = null

func get_encounter(encounter_id: String) -> Encounter:
	for encounter in encounters:
		if encounter.id == encounter_id:
			return encounter
	return null

func get_encounters_text() -> String:
	var text = "Encounters:\n"
	for encounter in encounters:
		var status = "✓" if encounter.encountered else "?"
		text += "%s %s (%s)\n" % [status, encounter.title, encounter.difficulty]
	return text

func get_total_encounters() -> int:
	return encounters.size()

func get_completed_encounters() -> int:
	return encounters.filter(func(e): return e.encountered).size()
