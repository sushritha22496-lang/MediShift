extends BaseSystemSimple

class_name ConversationSimple

class DialogueNode:
	var id: String
	var text: String
	var choices: Array[String]
	var next_nodes: Dictionary
	var speaker: String
	func _init(p_id: String, p_text: String, p_speaker: String) -> void:
		id = p_id
		text = p_text
		speaker = p_speaker
		choices = []
		next_nodes = {}

var dialogue_trees: Dictionary = {}

signal conversation_started(npc: String)
signal dialogue_option_selected(option_index: int)
signal conversation_ended
signal dialogue_tree_loaded(tree_id: String)

func _ready() -> void:
	set_state("current_conversation", "")
	set_state("current_node", "")
	set_state("conversation_history", [])
	_initialize_dialogue_trees()

func _initialize_dialogue_trees() -> void:
	var hanuman_tree = {}
	var start = DialogueNode.new("h_start", "Greetings, Rama! I am ready to help.", "Hanuman")
	start.choices = ["Tell me about Sita", "Join my quest", "Goodbye"]
	start.next_nodes = {"0": "h_sita", "1": "h_join", "2": "h_end"}
	hanuman_tree["h_start"] = start

	var sita_node = DialogueNode.new("h_sita", "Sita is being held by Ravana to the east...", "Hanuman")
	sita_node.choices = ["I will rescue her", "Go back"]
	sita_node.next_nodes = {"0": "h_join", "1": "h_start"}
	hanuman_tree["h_sita"] = sita_node

	var join_node = DialogueNode.new("h_join", "Excellent! Together we cannot fail!", "Hanuman")
	join_node.choices = ["Let's go", "Goodbye"]
	join_node.next_nodes = {"0": "h_end", "1": "h_end"}
	hanuman_tree["h_join"] = join_node

	var end_node = DialogueNode.new("h_end", "May fortune favor us.", "Hanuman")
	end_node.choices = []
	hanuman_tree["h_end"] = end_node

	dialogue_trees["hanuman"] = hanuman_tree

func start_conversation(npc_id: String) -> bool:
	if npc_id in dialogue_trees:
		set_state("current_conversation", npc_id)
		set_state("current_node", "%s_start" % npc_id)
		conversation_started.emit(npc_id)
		emit_event("conversation_started", npc_id)
		return true
	return false

func get_current_dialogue() -> DialogueNode:
	var conv = get_state("current_conversation", "")
	var node = get_state("current_node", "")
	if conv == "" or node == "":
		return null
	var tree = dialogue_trees.get(conv, {})
	return tree.get(node, null)

func select_choice(choice_index: int) -> bool:
	var dialogue = get_current_dialogue()
	if not dialogue or choice_index >= dialogue.choices.size():
		return false

	var conv = get_state("current_conversation", "")
	var current_id = get_state("current_node", "")
	var history = get_state("conversation_history", [])
	history.append({
		"node": current_id,
		"choice": choice_index,
		"text": dialogue.choices[choice_index]
	})
	set_state("conversation_history", history)

	if choice_index in dialogue.next_nodes:
		var next_node = dialogue.next_nodes[str(choice_index)]
		set_state("current_node", next_node)
		dialogue_option_selected.emit(choice_index)
		emit_event("choice_selected", str(choice_index))
		
		if next_node.ends_with("_end"):
			end_conversation()
		return true
	return false

func end_conversation() -> void:
	set_state("current_conversation", "")
	set_state("current_node", "")
	conversation_ended.emit()
	emit_event("conversation_ended", "")

func add_dialogue_tree(tree_id: String, tree: Dictionary) -> void:
	dialogue_trees[tree_id] = tree
	dialogue_tree_loaded.emit(tree_id)
	emit_event("tree_loaded", tree_id)

func get_conversation_text() -> String:
	var dialogue = get_current_dialogue()
	if not dialogue:
		return "No conversation"
	var text = "%s: %s\n" % [dialogue.speaker, dialogue.text]
	for i in range(dialogue.choices.size()):
		text += "[%d] %s\n" % [i, dialogue.choices[i]]
	return text

func get_conversation_history() -> Array:
	return get_state("conversation_history", [])
