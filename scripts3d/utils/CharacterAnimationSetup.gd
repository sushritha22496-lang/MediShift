extends Node

class_name CharacterAnimationSetup

static var _animation_cache: Dictionary = {}

const ANIMATION_PATHS = {
	"hanuman_final": "res://assets/animations/humanoid/hanuman_final_animations.glb",
	"demon_demon_blue": "res://assets/animations/humanoid/demon_demon_blue_animations.glb",
	"demon_demon_green": "res://assets/animations/humanoid/demon_demon_green_animations.glb",
	"dundhubi_boss": "res://assets/animations/humanoid/dundhubi_boss_animations.glb",
	"kumbhakarna": "res://assets/animations/humanoid/kumbhakarna_animations.glb",
}

static func load_animations_for_player(anim_player: AnimationPlayer, character_name: String) -> bool:
	"""Load all animations from a glTF file into an AnimationPlayer"""

	if not anim_player:
		push_error("AnimationPlayer is null")
		return false

	# Try to load from cache first
	var cache_key = character_name.to_lower()
	if cache_key in _animation_cache:
		_copy_cached_animations(anim_player, cache_key)
		return true

	# Find the animation file
	var anim_file = _get_animation_file(character_name)
	if not anim_file:
		push_warning("No animation file found for: " + character_name)
		return false

	if not ResourceLoader.exists(anim_file):
		push_warning("Animation file does not exist: " + anim_file)
		return false

	# Load the glTF scene with animations
	var anim_scene = load(anim_file)
	if not anim_scene:
		push_error("Failed to load animation scene: " + anim_file)
		return false

	# Instantiate to get the AnimationPlayer
	var temp_node = anim_scene.instantiate()
	var source_anim_player: AnimationPlayer = null

	# Find AnimationPlayer in the scene
	if temp_node is AnimationPlayer:
		source_anim_player = temp_node
	else:
		source_anim_player = _find_animation_player(temp_node)

	if not source_anim_player:
		push_error("No AnimationPlayer found in: " + anim_file)
		temp_node.queue_free()
		return false

	# Copy all animations
	var animation_list = source_anim_player.get_animation_list()
	for anim_name in animation_list:
		var anim = source_anim_player.get_animation(anim_name)
		# Clean animation name (remove library prefix)
		var clean_name = anim_name.split("/")[-1]
		if not anim_player.has_animation(clean_name):
			anim_player.add_animation(clean_name, anim)

	# Cache the source for reuse
	_animation_cache[cache_key] = source_anim_player

	temp_node.queue_free()

	print("✅ Loaded %d animations for: %s" % [animation_list.size(), character_name])
	return true

static func _find_animation_player(node: Node) -> AnimationPlayer:
	"""Recursively find AnimationPlayer in node tree"""
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null

static func _get_animation_file(character_name: String) -> String:
	"""Get the animation file path for a character"""
	var key = character_name.to_lower()

	# Check predefined paths
	if key in ANIMATION_PATHS:
		return ANIMATION_PATHS[key]

	# Try generic path
	var generic_path = "res://assets/animations/humanoid/%s_animations.glb" % key
	if ResourceLoader.exists(generic_path):
		return generic_path

	return ""

static func _copy_cached_animations(target_player: AnimationPlayer, cache_key: String) -> void:
	"""Copy animations from cache to target AnimationPlayer"""
	if cache_key not in _animation_cache:
		return

	var source_player = _animation_cache[cache_key]
	if not source_player:
		return

	for anim_name in source_player.get_animation_list():
		var anim = source_player.get_animation(anim_name)
		var clean_name = anim_name.split("/")[-1]
		if not target_player.has_animation(clean_name):
			target_player.add_animation(clean_name, anim)

static func setup_player_animations(player_node: Node3D) -> bool:
	"""Automatically set up animations for any character node"""
	var anim_player: AnimationPlayer = null

	# Try common paths
	var search_paths = ["AnimationPlayer", "Model/AnimationPlayer", "Skeleton/AnimationPlayer"]
	for path in search_paths:
		var node = player_node.get_node_or_null(path)
		if node is AnimationPlayer:
			anim_player = node
			break

	if not anim_player:
		push_warning("No AnimationPlayer found in: " + player_node.name)
		return false

	# Get character name from node or export variable
	var character_name = ""
	if player_node.has_meta("character_name"):
		character_name = player_node.get_meta("character_name")
	elif player_node.has_method("get_character_name"):
		character_name = player_node.get_character_name()
	elif "character_name" in player_node:
		character_name = player_node["character_name"]
	else:
		character_name = player_node.name

	return load_animations_for_player(anim_player, character_name)
