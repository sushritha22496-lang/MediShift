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
signal dialogue_branch_triggered(branch_id: String)
signal emotion_changed(speaker: String, emotion: String)

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
	set_state("speaker_emotions", {})
	set_state("dialogue_branches", {})
	set_state("dialogue_outcomes", [])
	set_state("choice_history", [])
	set_state("branch_history", [])
	set_state("dialogue_statistics", {})
	set_state("dialogue_choice_record", [])
	set_state("dialogue_branch_record", [])
	set_state("speaker_interaction_history", [])

func _record_dialogue_choice(choice_id: String, choice_text: String, speaker: String) -> void:
	var history = get_state("dialogue_choice_record", [])
	history.append({"choice_id": choice_id, "text": choice_text, "speaker": speaker, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("dialogue_choice_record", history)

func _record_dialogue_branch(branch_id: String, conditions_met: Dictionary) -> void:
	var history = get_state("dialogue_branch_record", [])
	history.append({"branch_id": branch_id, "conditions_met": conditions_met, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("dialogue_branch_record", history)

func _record_speaker_interaction(speaker: String, tone: String) -> void:
	var history = get_state("speaker_interaction_history", [])
	history.append({"speaker": speaker, "tone": tone, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("speaker_interaction_history", history)

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
	_record_speaker_interaction(speaker, tone)
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
			_record_dialogue_choice(choice_id, choice.get("text", ""), "player")
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

func set_speaker_emotion(speaker: String, emotion: String) -> void:
	var emotions = get_state("speaker_emotions", {})
	emotions[speaker] = emotion
	set_state("speaker_emotions", emotions)
	emotion_changed.emit(speaker, emotion)
	emit_event("emotion_changed", {"speaker": speaker, "emotion": emotion})

func get_speaker_emotion(speaker: String) -> String:
	var emotions = get_state("speaker_emotions", {})
	return emotions.get(speaker, "neutral")

func trigger_dialogue_branch(branch_id: String, conditions: Dictionary = {}) -> bool:
	var branches = get_state("dialogue_branches", {})
	if branch_id not in branches:
		branches[branch_id] = {"triggered": true, "conditions_met": conditions}
		set_state("dialogue_branches", branches)
		_record_dialogue_branch(branch_id, conditions)
		dialogue_branch_triggered.emit(branch_id)
		emit_event("branch_triggered", branch_id)
		return true
	return false

func record_dialogue_outcome(outcome_id: String, success: bool, impact: float = 0.0) -> void:
	var outcomes = get_state("dialogue_outcomes", [])
	outcomes.append({"id": outcome_id, "success": success, "impact": impact, "timestamp": Time.get_ticks_msec()})
	if outcomes.size() > 100:
		outcomes.pop_front()
	set_state("dialogue_outcomes", outcomes)
	emit_event("outcome_recorded", outcome_id)

func get_dialogue_branches_triggered() -> Array:
	var branches = get_state("dialogue_branches", {})
	return branches.keys()

func get_dialogue_outcomes() -> Array:
	return get_state("dialogue_outcomes", [])

func update_dialogue_statistics() -> void:
	var stats = get_state("dialogue_statistics", {})
	var choice_rec = get_state("dialogue_choice_record", [])
	var branch_rec = get_state("dialogue_branch_record", [])
	var speaker_hist = get_state("speaker_interaction_history", [])
	var hist = get_state("dialogue_history", [])
	stats["total_dialogue_nodes"] = hist.size()
	stats["total_choices_made"] = choice_rec.size()
	stats["total_branches_triggered"] = branch_rec.size()
	stats["total_speaker_interactions"] = speaker_hist.size()
	var unique_speakers = {}
	for entry in speaker_hist:
		unique_speakers[entry["speaker"]] = true
	stats["unique_speakers"] = unique_speakers.size()
	var outcomes = get_state("dialogue_outcomes", [])
	stats["total_outcomes_recorded"] = outcomes.size()
	set_state("dialogue_statistics", stats)

func get_dialogue_statistics() -> Dictionary:
	update_dialogue_statistics()
	return get_state("dialogue_statistics", {})
