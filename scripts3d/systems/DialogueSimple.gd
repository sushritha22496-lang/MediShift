extends BaseSystemSimple

class_name DialogueSimple

signal dialogue_started(speaker: String, text: String)
signal dialogue_ended

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

func get_dialogue(speaker: String, index: int = 0) -> String:
	var dialogues = get_state("dialogues", {})
	if speaker in dialogues:
		if index < dialogues[speaker].size():
			return dialogues[speaker][index]
	return "..."

func get_all_dialogues(speaker: String) -> Array:
	var dialogues = get_state("dialogues", {})
	return dialogues.get(speaker, [])

func play_dialogue_sequence(speaker: String, label: Label) -> void:
	var dialogue_list = get_all_dialogues(speaker)
	if dialogue_list.is_empty():
		return
	for dialogue_text in dialogue_list:
		dialogue_started.emit(speaker, dialogue_text)
		if label:
			label.text = dialogue_text
		await get_tree().create_timer(2.0).timeout
	dialogue_ended.emit()
	emit_event("sequence_complete", speaker)

func add_dialogue(speaker: String, text: String) -> void:
	var dialogues = get_state("dialogues", {})
	if not speaker in dialogues:
		dialogues[speaker] = []
	dialogues[speaker].append(text)
	emit_event("dialogue_added", speaker)
