extends Node3D

class_name RiggedCharacterLoader

# Character model paths (from Mixamo FBX imports)
const MODEL_PATHS = {
	"rama": "res://assets/characters/rama_rigged.fbx",
	"hanuman": "res://assets/characters/hanuman_rigged.fbx",
	"monkey": "res://assets/characters/monkey_warrior_rigged.fbx"
}

# Animation states mapping for Mixamo animations
const ANIMATION_MAP = {
	"idle": "Idle",
	"walk": "Walking",
	"run": "Running",
	"jump": "Jump",
	"fall": "Falling",
	"climb": "Climbing",
	"swim": "Swimming",
	"fight": "Fighting",
	"attack": "Attacking",
	"hit": "Hit",
	"die": "Dying",
	"call": "Shouting"
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

	# Map available animations
	var available_anims = anim_player.get_animation_list()
	for state in ANIMATION_MAP.keys():
		var mixamo_name = ANIMATION_MAP[state]
		if mixamo_name not in available_anims:
			push_warning("Animation '%s' not found in model. Available: %s" % [mixamo_name, str(available_anims)])

static func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node

	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result

	return null

static func get_animation_name(state: String) -> String:
	return ANIMATION_MAP.get(state, state)

static func play_animation(character: Node3D, state: String) -> void:
	var model = character.get_node_or_null("Model")
	if not model:
		return

	var anim_player = _find_animation_player(model)
	if not anim_player:
		return

	var anim_name = get_animation_name(state)
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
	else:
		push_warning("Animation '%s' not available for state '%s'" % [anim_name, state])
