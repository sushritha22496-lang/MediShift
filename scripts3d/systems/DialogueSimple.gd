extends BaseSystemSimple

class_name DialogueSimple

class DialogueNode:
	var id: String
	var text: String
	var speaker: String
	var tone: String
	var choices: Array = []
	var conditions: Dictionary = {}
	var consequences: Dictionary = {}
	var relationship_variant: String = ""
	func _init(p_id: String, p_text: String, p_speaker: String, p_tone: String = "neutral") -> void:
		id = p_id
		text = p_text
		speaker = p_speaker
		tone = p_tone

signal dialogue_started(speaker: String, text: String)
signal dialogue_ended
signal choice_made(choice_id: String)

func _ready() -> void:
	var dialogues = {
		"hanuman": [
			"🐵 Hanuman: Who calls with such sorrow?",
			"🐵 Hanuman: I will help you find Sita!",
			"🐵 Hanuman: You have a loyal friend now, Rama."
		],
		"monkey_scout": [
			"🐒 Scout: Welcome, brother!",
			"🐒 Scout: We have heard of your quest.",
			"🐒 Scout: The forest is safer with allies!"
		],
		"merchant": [
			"🏪 Merchant: Greetings, traveler!",
			"🏪 Merchant: I have goods to trade.",
			"🏪 Merchant: Show me your inventory."
		],
		"sage": [
			"🧙 Sage: Blessings upon you, Rama.",
			"🧙 Sage: Wisdom is found in these woods.",
			"🧙 Sage: Meditate to restore your strength."
		]
	}
	set_state("dialogues", dialogues)
	set_state("dialogue_history", [])
	set_state("current_dialogue_node", "")
	set_state("dialogue_choices", [])

func get_dialogue(speaker: String, index: int = 0) -> String:
	var dialogues = get_state("dialogues", {})
	if speaker in dialogues:
		if index < dialogues[speaker].size():
			return dialogues[speaker][index]
	return "..."

func get_all_dialogues(speaker: String) -> Array:
	var dialogues = get_state("dialogues", {})
	return dialogues.get(speaker, [])

func start_dialogue_node(node_id: String, speaker: String, text: String, tone: String = "neutral") -> void:
	var node = DialogueNode.new(node_id, text, speaker, tone)
	set_state("current_dialogue_node", node_id)
	var history = get_state("dialogue_history", [])
	history.append({"speaker": speaker, "text": text, "tone": tone, "time": Time.get_ticks_msec()})
	set_state("dialogue_history", history)
	dialogue_started.emit(speaker, text)
	emit_event("dialogue_started", {"speaker": speaker, "node": node_id})

func add_dialogue_choice(choice_id: String, choice_text: String, next_node: String, condition: Dictionary = {}) -> void:
	var choices = get_state("dialogue_choices", [])
	choices.append({
		"id": choice_id,
		"text": choice_text,
		"next_node": next_node,
		"condition": condition,
		"available": true
	})
	set_state("dialogue_choices", choices)

func get_available_choices() -> Array:
	var choices = get_state("dialogue_choices", [])
	var available = []
	for choice in choices:
		if choice.get("available", true):
			available.append(choice)
	return available

func make_dialogue_choice(choice_id: String) -> String:
	var choices = get_state("dialogue_choices", [])
	for choice in choices:
		if choice["id"] == choice_id:
			choice_made.emit(choice_id)
			emit_event("choice_made", choice_id)
			set_state("dialogue_choices", [])
			return choice.get("next_node", "")
	return ""

func get_dialogue_history() -> Array:
	return get_state("dialogue_history", [])

func can_access_dialogue_branch(condition: Dictionary) -> bool:
	for key in condition:
		if key == "level_required":
			if 1 < condition[key]:
				return false
		elif key == "item_required":
			if not true:
				return false
		elif key == "has_met":
			if key not in get_dialogue_history():
				return false
	return true

func add_dialogue(speaker: String, text: String) -> void:
	var dialogues = get_state("dialogues", {})
	if not speaker in dialogues:
		dialogues[speaker] = []
	dialogues[speaker].append(text)
	emit_event("dialogue_added", speaker)
