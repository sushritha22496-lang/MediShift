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
var choice_tracking: Dictionary = {}
var choice_influence_totals: Dictionary = {}
var dialogue_statistics: Dictionary = {}
var player_choice_preferences: Dictionary = {}
var consequence_tracking: Array = []
var dialogue_path_tracking: Array = []
var sequence_completion: Dictionary = {}

signal dialogue_started(speaker: String, text: String)
signal choice_presented(choices: Array[Choice])
signal dialogue_ended
signal choice_tracked(choice_id: String)
signal path_completed(path_id: String)

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
			track_choice_selection(choice_id)
			for influence_type in choice.influence:
				record_choice_influence(choice_id, influence_type, choice.influence[influence_type])
			record_player_choice_preference(choice.text, get_choice_selection_count(choice_id))
			start_dialogue(choice.next_dialogue_id)
			return

func end_dialogue() -> void:
	record_dialogue_path(dialogue_history.duplicate())
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

func track_choice_selection(choice_id: String) -> void:
	if choice_id not in choice_tracking:
		choice_tracking[choice_id] = 0
	choice_tracking[choice_id] += 1
	choice_tracked.emit(choice_id)

func record_choice_influence(choice_id: String, influence_type: String, value: float) -> void:
	var key = "%s_%s" % [choice_id, influence_type]
	if key not in choice_influence_totals:
		choice_influence_totals[key] = 0.0
	choice_influence_totals[key] += value

func update_dialogue_statistics() -> void:
	dialogue_statistics["total_dialogues"] = dialogue_nodes.size()
	dialogue_statistics["total_choices_made"] = choice_tracking.values().reduce(func(a, b): return a + b, 0)
	dialogue_statistics["dialogue_history_size"] = dialogue_history.size()
	dialogue_statistics["consequence_count"] = consequence_tracking.size()
	dialogue_statistics["paths_recorded"] = dialogue_path_tracking.size()
	dialogue_statistics["sequences_completed"] = sequence_completion.size()
	dialogue_statistics["most_popular_choice"] = get_most_popular_choice()

func get_dialogue_statistics() -> Dictionary:
	update_dialogue_statistics()
	return dialogue_statistics

func record_player_choice_preference(choice_text: String, times_selected: int) -> void:
	player_choice_preferences[choice_text] = times_selected

func get_choice_popularity() -> Dictionary:
	return player_choice_preferences

func record_consequence(consequence_type: String, consequence_data: Dictionary) -> void:
	consequence_tracking.append({"type": consequence_type, "data": consequence_data, "time": Time.get_ticks_msec()})
	if consequence_tracking.size() > 50:
		consequence_tracking.pop_front()

func record_dialogue_path(dialogue_sequence: Array) -> void:
	dialogue_path_tracking.append({"path": dialogue_sequence, "time": Time.get_ticks_msec()})
	if dialogue_path_tracking.size() > 30:
		dialogue_path_tracking.pop_front()

func rate_choice_effectiveness(choice_id: String) -> float:
	var tracking = choice_tracking.get(choice_id, 0)
	var influence = 0.0
	for key in choice_influence_totals:
		if key.begins_with(choice_id):
			influence += choice_influence_totals[key]
	return influence / maxf(1.0, float(tracking))

func mark_sequence_completed(sequence_id: String) -> void:
	sequence_completion[sequence_id] = {"completed": true, "time": Time.get_ticks_msec()}
	path_completed.emit(sequence_id)

func get_choice_selection_count(choice_id: String) -> int:
	return choice_tracking.get(choice_id, 0)

func get_most_popular_choice() -> String:
	var max_choice = ""
	var max_count = 0
	for choice_id in choice_tracking:
		if choice_tracking[choice_id] > max_count:
			max_count = choice_tracking[choice_id]
			max_choice = choice_id
	return max_choice

func get_dialogue_paths() -> Array:
	return dialogue_path_tracking
