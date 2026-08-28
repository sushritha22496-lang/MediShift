extends Node3D

class_name RiggedCharacterLoader

# Character model paths (from Mixamo FBX imports)
const MODEL_PATHS = {
	"rama": "res://assets/characters/rama_rigged.fbx",
	"hanuman": "res://assets/characters/hanuman_rigged.fbx",
	"monkey": "res://assets/characters/monkey_warrior_rigged.fbx"
}

# Core animation aliases (map common names to Mixamo animations)
# These are fallbacks when exact names don't exist
const ANIMATION_ALIASES = {
	"idle": ["Idle", "Armature|Idle", "idle"],
	"walk": ["Walking", "Walk", "walking", "walk"],
	"run": ["Running", "Run", "running", "run"],
	"jump": ["Jump", "Jumping", "jump"],
	"fall": ["Falling", "Fall", "falling", "fall"],
	"climb": ["Climbing", "Climb", "climbing", "climb"],
	"swim": ["Swimming", "Swim", "swimming", "swim"],
	"fight": ["Fighting", "Attacking", "Attack", "fight", "attack"],
	"dance": ["Dancing", "Dance", "dance"],
	"sing": ["Singing", "Sing", "sing"],
	"chant": ["Chanting", "Chant", "chant"],
	"die": ["Dying", "Death", "Die", "death"],
	"hit": ["Hit", "Getting Hit", "Damage", "hit"],
	"call": ["Shouting", "Calling", "Call", "Shout", "call"]
}

static func load_character(character: Node3D, character_type: String) -> bool:
	var model_path = MODEL_PATHS.get(character_type.to_lower())
	if not model_path:
		push_error("Unknown character type: %s" % character_type)
		return false

	# Check if model exists
	if not ResourceLoader.exists(model_path):
		push_error("Model not found: %s. Download from Mixamo and place in assets/characters/" % model_path)
		return false

	# Load and instantiate model
	var scene = load(model_path)
	if not scene:
		push_error("Failed to load model: %s" % model_path)
		return false

	var model_instance = scene.instantiate()

	# Replace or create Model node
	var existing_model = character.get_node_or_null("Model")
	if existing_model:
		existing_model.queue_free()

	model_instance.name = "Model"
	character.add_child(model_instance)

	# Setup animator if present
	_setup_animator(character)

	return true

static func _setup_animator(character: Node3D) -> void:
	var model = character.get_node_or_null("Model")
	if not model:
		return

	# Find AnimationPlayer in loaded model
	var anim_player = _find_animation_player(model)
	if not anim_player:
		push_warning("No AnimationPlayer found in rigged model")
		return

	# Store available animations on character for later access
	var available_anims = anim_player.get_animation_list()
	character.set_meta("available_animations", available_anims)

	# Log all available animations for developer reference
	print("Character loaded with %d animations: %s" % [available_anims.size(), str(available_anims)])

static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node

	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result

	return null

static func get_animation_name(character: Node3D, requested_state: String) -> String:
	var anim_player = _find_animation_player(character.get_node_or_null("Model"))
	if not anim_player:
		return requested_state

	var available = anim_player.get_animation_list()

	# Direct match first
	if requested_state in available:
		return requested_state

	# Try case-insensitive match
	var lower_req = requested_state.to_lower()
	for anim in available:
		if anim.to_lower() == lower_req:
			return anim

	# Try aliases (core animations like idle, walk, run, fight, dance, sing, chant, etc.)
	if requested_state in ANIMATION_ALIASES:
		for alias in ANIMATION_ALIASES[requested_state]:
			for anim in available:
				if anim.to_lower() == alias.to_lower():
					return anim

	# Partial match as last resort
	for anim in available:
		if lower_req in anim.to_lower():
			return anim

	return requested_state  # Return original, will fail gracefully

static func play_animation(character: Node3D, requested_state: String) -> bool:
	var model = character.get_node_or_null("Model")
	if not model:
		return false

	var anim_player = _find_animation_player(model)
	if not anim_player:
		return false

	var anim_name = get_animation_name(character, requested_state)

	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		return true
	else:
		var available = anim_player.get_animation_list()
		push_warning("Animation '%s' (requested: '%s') not found. Available: %s" % [anim_name, requested_state, str(available)])
		return false

static func get_all_animations(character: Node3D) -> PackedStringArray:
	var model = character.get_node_or_null("Model")
	if not model:
		return PackedStringArray()

	var anim_player = _find_animation_player(model)
	if not anim_player:
		return PackedStringArray()

	return anim_player.get_animation_list()

static func random_animation(character: Node3D, filter: String = "") -> String:
	var all_anims = get_all_animations(character)
	if all_anims.is_empty():
		return "idle"

	var filtered = PackedStringArray()
	for anim in all_anims:
		if filter == "" or filter.to_lower() in anim.to_lower():
			filtered.append(anim)

	if filtered.is_empty():
		filtered = all_anims

	return filtered[randi() % filtered.size()]
