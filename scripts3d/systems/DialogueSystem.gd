extends Node3D

class_name DialogueSystem

class DialogueNode:
	var id: String
	var speaker: String
	var text: String
	var next_id: String
	var choices: Array[Dictionary] = []

var dialogues: Dictionary = {}
var current_dialogue: DialogueNode = null
var dialogue_stack: Array[String] = []
var completed_dialogues: Array[String] = []
var dialogue_variables: Dictionary = {}

signal dialogue_started(npc_name: String)
signal dialogue_text_displayed(text: String, speaker: String)
signal dialogue_ended
signal dialogue_completed(dialogue_id: String)

func _ready() -> void:
	_load_all_dialogues()

func _load_all_dialogues() -> void:
	_load_rama_dialogues()
	_load_hanuman_dialogues()
	_load_sita_dialogues()
	_load_scout_dialogues()
	_load_monkey_dialogues()

func _load_rama_dialogues() -> void:
	# Rama's initial monologue
	var r1 = DialogueNode.new()
	r1.id = "rama_intro"
	r1.speaker = "Rama"
	r1.text = "Sita... where are you? I must find you. Perhaps the forest creatures can help."
	r1.next_id = ""
	dialogues[r1.id] = r1

	# Rama meeting Hanuman
	var r2 = DialogueNode.new()
	r2.id = "rama_answer_1"
	r2.speaker = "Rama"
	r2.text = "I am Rama, son of Dasharatha. My beloved Sita has been taken by the demon Ravana."
	r2.next_id = "hanuman_react_1"
	dialogues[r2.id] = r2

	# Rama's gratitude
	var r3 = DialogueNode.new()
	r3.id = "rama_thank_hanuman"
	r3.speaker = "Rama"
	r3.text = "Thank you, noble Hanuman. Your loyalty is unmatched. Please, search the skies for Sita."
	r3.next_id = ""
	dialogues[r3.id] = r3

func _load_hanuman_dialogues() -> void:
	var d1 = DialogueNode.new()
	d1.id = "hanuman_meet_1"
	d1.speaker = "Hanuman"
	d1.text = "Who are you? Why do you call with such sorrow?"
	d1.next_id = "rama_answer_1"
	dialogues[d1.id] = d1

	var d2 = DialogueNode.new()
	d2.id = "hanuman_react_1"
	d2.speaker = "Hanuman"
	d2.text = "Ravana! I know of him and his island Lanka. I will help you find Sita!"
	d2.next_id = "rama_thank_hanuman"
	dialogues[d2.id] = d2

	# Hanuman during quest
	var d3 = DialogueNode.new()
	d3.id = "hanuman_quest"
	d3.speaker = "Hanuman"
	d3.text = "I will cross the ocean and search Lanka. No obstacle shall stop me!"
	d3.next_id = ""
	dialogues[d3.id] = d3

func _load_sita_dialogues() -> void:
	var s1 = DialogueNode.new()
	s1.id = "sita_despair"
	s1.speaker = "Sita"
	s1.text = "Rama... my beloved... I wait in this dark palace. Will you come for me?"
	s1.next_id = ""
	dialogues[s1.id] = s1

	var s2 = DialogueNode.new()
	s2.id = "sita_hope"
	s2.speaker = "Sita"
	s2.text = "I sense Rama's love even across the distance. My faith remains strong."
	s2.next_id = ""
	dialogues[s2.id] = s2

func _load_scout_dialogues() -> void:
	var d1 = DialogueNode.new()
	d1.id = "scout_meet_1"
	d1.speaker = "Scout"
	d1.text = "Greetings traveler. You search for something?"
	d1.next_id = "scout_follow"
	dialogues[d1.id] = d1

	var d2 = DialogueNode.new()
	d2.id = "scout_follow"
	d2.speaker = "Scout"
	d2.text = "If you seek passage, we monkeys can aid you. Together we are strong!"
	d2.next_id = ""
	dialogues[d2.id] = d2

func _load_monkey_dialogues() -> void:
	var m1 = DialogueNode.new()
	m1.id = "monkey_greeting"
	m1.speaker = "Monkey"
	m1.text = "Welcome to our forest realm! What brings you here?"
	m1.next_id = ""
	dialogues[m1.id] = m1

	var m2 = DialogueNode.new()
	m2.id = "monkey_help"
	m2.speaker = "Monkey"
	m2.text = "We have heard of your plight. The monkey king's blessing goes with you."
	m2.next_id = ""
	dialogues[m2.id] = m2

func start_dialogue(dialogue_id: String) -> void:
	if not dialogues.has(dialogue_id):
		return

	dialogue_started.emit(dialogues[dialogue_id].speaker)
	current_dialogue = dialogues[dialogue_id]
	dialogue_stack = []
	display_current_dialogue()

func display_current_dialogue() -> void:
	if not current_dialogue:
		return

	dialogue_text_displayed.emit(current_dialogue.text, current_dialogue.speaker)

func advance_dialogue() -> void:
	if not current_dialogue or current_dialogue.next_id == "":
		end_dialogue()
		return

	if dialogues.has(current_dialogue.next_id):
		current_dialogue = dialogues[current_dialogue.next_id]
		display_current_dialogue()
	else:
		end_dialogue()

func end_dialogue() -> void:
	if current_dialogue:
		var dialogue_id = current_dialogue.id
		if not dialogue_id in completed_dialogues:
			completed_dialogues.append(dialogue_id)
			dialogue_completed.emit(dialogue_id)

	current_dialogue = null
	dialogue_ended.emit()

func get_current_speaker() -> String:
	if current_dialogue:
		return current_dialogue.speaker
	return ""

func get_current_text() -> String:
	if current_dialogue:
		return current_dialogue.text
	return ""

func is_dialogue_active() -> bool:
	return current_dialogue != null

func is_dialogue_completed(dialogue_id: String) -> bool:
	return dialogue_id in completed_dialogues

func set_dialogue_variable(key: String, value: Variant) -> void:
	dialogue_variables[key] = value

func get_dialogue_variable(key: String, default_value: Variant = null) -> Variant:
	if dialogue_variables.has(key):
		return dialogue_variables[key]
	return default_value

func get_completed_dialogues() -> Array[String]:
	return completed_dialogues

func has_npc_dialogue(npc_name: String) -> bool:
	for dialogue_id in dialogues.keys():
		if dialogues[dialogue_id].speaker == npc_name:
			return true
	return false

func get_npc_dialogues(npc_name: String) -> Array[String]:
	var npc_dialogues: Array[String] = []
	for dialogue_id in dialogues.keys():
		if dialogues[dialogue_id].speaker == npc_name:
			npc_dialogues.append(dialogue_id)
	return npc_dialogues
