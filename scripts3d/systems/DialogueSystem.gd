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

signal dialogue_started(npc_name: String)
signal dialogue_text_displayed(text: String, speaker: String)
signal dialogue_ended

func _ready() -> void:
	_load_all_dialogues()

func _load_all_dialogues() -> void:
	_load_hanuman_dialogues()
	_load_scout_dialogues()

func _load_hanuman_dialogues() -> void:
	var d1 = DialogueNode.new()
	d1.id = "hanuman_meet_1"
	d1.speaker = "Hanuman"
	d1.text = "Who are you? Why do you call with such sorrow?"
	d1.next_id = "rama_answer_1"

	var d2 = DialogueNode.new()
	d2.id = "rama_answer_1"
	d2.speaker = "Rama"
	d2.text = "I am Rama, son of Dasharatha. My beloved Sita has been taken by the demon Ravana."
	d2.next_id = "hanuman_react_1"

	var d3 = DialogueNode.new()
	d3.id = "hanuman_react_1"
	d3.speaker = "Hanuman"
	d3.text = "Ravana! I know of him and his island Lanka. I will help you find Sita!"
	d3.next_id = ""

	dialogues[d1.id] = d1
	dialogues[d2.id] = d2
	dialogues[d3.id] = d3

func _load_scout_dialogues() -> void:
	var d1 = DialogueNode.new()
	d1.id = "scout_meet_1"
	d1.speaker = "Scout"
	d1.text = "Greetings traveler. You search for something?"
	d1.next_id = ""

	dialogues[d1.id] = d1

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
