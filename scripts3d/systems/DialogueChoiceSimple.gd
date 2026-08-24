extends Node

class_name DialogueChoiceSimple

class Choice:
	var id: String
	var text: String
	var next_dialogue_id: String
	var influence: Dictionary = {}

class DialogueNode:
	var id: String
	var speaker: String
	var text: String
	var choices: Array[Choice] = []

var dialogue_nodes: Dictionary = {}
var current_dialogue: DialogueNode = null
var dialogue_history: Array[String] = []

signal dialogue_started(speaker: String, text: String)
signal choice_presented(choices: Array[Choice])
signal dialogue_ended

func _ready() -> void:
	_initialize_dialogues()

func _initialize_dialogues() -> void:
	var hanuman_intro = DialogueNode.new()
	hanuman_intro.id = "hanuman_intro"
	hanuman_intro.speaker = "Hanuman"
	hanuman_intro.text = "Greetings, Rama! I have been awaiting your call."

	var choice1 = Choice.new()
	choice1.id = "choice_1"
	choice1.text = "Will you help me find Sita?"
	choice1.next_dialogue_id = "hanuman_agrees"
	choice1.influence = {"hanuman": 10}
	hanuman_intro.choices.append(choice1)

	dialogue_nodes["hanuman_intro"] = hanuman_intro

func start_dialogue(dialogue_id: String) -> void:
	if dialogue_id in dialogue_nodes:
		current_dialogue = dialogue_nodes[dialogue_id]
		dialogue_history.append(dialogue_id)
		dialogue_started.emit(current_dialogue.speaker, current_dialogue.text)

		if current_dialogue.choices.size() > 0:
			choice_presented.emit(current_dialogue.choices)
		else:
			await get_tree().create_timer(2.0).timeout
			end_dialogue()

func select_choice(choice_id: String) -> void:
	for choice in current_dialogue.choices:
		if choice.id == choice_id:
			start_dialogue(choice.next_dialogue_id)
			return

func end_dialogue() -> void:
	current_dialogue = null
	dialogue_ended.emit()

func get_dialogue_history() -> Array[String]:
	return dialogue_history

func add_dialogue_node(node: DialogueNode) -> void:
	dialogue_nodes[node.id] = node

func get_dialogue_text() -> String:
	if current_dialogue:
		return "%s: %s" % [current_dialogue.speaker, current_dialogue.text]
	return ""
