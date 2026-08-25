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

	# Copy all animations into the player's default AnimationLibrary, retargeting
	# bone tracks from the animation file's own skeleton path onto whatever path
	# the actual character's Skeleton3D lives at in this scene
	var library = _get_or_create_library(anim_player)
	var source_skeleton_path = _find_skeleton_path(source_anim_player)
	var target_skeleton_path = _find_skeleton_path(anim_player)
	var animation_list = source_anim_player.get_animation_list()
	for anim_name in animation_list:
		var anim = source_anim_player.get_animation(anim_name)
		if source_skeleton_path != NodePath() and target_skeleton_path != NodePath():
			anim = _retarget_animation(anim, source_skeleton_path, target_skeleton_path)
		# Clean animation name (remove library prefix)
		var clean_name = anim_name.split("/")[-1]
		if not library.has_animation(clean_name):
			library.add_animation(clean_name, anim)
	_register_standard_aliases(library)

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

	var library = _get_or_create_library(target_player)
	var source_skeleton_path = _find_skeleton_path(source_player)
	var target_skeleton_path = _find_skeleton_path(target_player)
	for anim_name in source_player.get_animation_list():
		var anim = source_player.get_animation(anim_name)
		if source_skeleton_path != NodePath() and target_skeleton_path != NodePath():
			anim = _retarget_animation(anim, source_skeleton_path, target_skeleton_path)
		var clean_name = anim_name.split("/")[-1]
		if not library.has_animation(clean_name):
			library.add_animation(clean_name, anim)
	_register_standard_aliases(library)

static func _find_skeleton_path(anim_player: AnimationPlayer) -> NodePath:
	"""Find this player's actual Skeleton3D and return its path relative to
	the AnimationPlayer's root_node, so copied tracks can be re-pointed at it."""
	var root = anim_player.get_node_or_null(anim_player.root_node)
	if not root:
		root = anim_player.get_parent()
	if not root:
		return NodePath()
	var skeleton = _find_skeleton_node(root)
	if not skeleton:
		return NodePath()
	return root.get_path_to(skeleton)

static func _find_skeleton_node(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton_node(child)
		if result:
			return result
	return null

static func _retarget_animation(anim: Animation, source_skeleton_path: NodePath, target_skeleton_path: NodePath) -> Animation:
	"""Duplicate an animation and repoint bone tracks that targeted the
	source file's own Skeleton3D onto the actual target Skeleton3D's path.
	Tracks pointing elsewhere (e.g. a separate root-motion node) are left
	untouched rather than guessed at."""
	var new_anim: Animation = anim.duplicate(true)
	var source_str = str(source_skeleton_path)
	var target_str = str(target_skeleton_path)
	for i in range(new_anim.get_track_count() - 1, -1, -1):
		var track_path = str(new_anim.track_get_path(i))
		var colon_idx = track_path.find(":")
		if colon_idx == -1:
			new_anim.remove_track(i)
			continue
		var node_part = track_path.substr(0, colon_idx)
		if node_part != source_str:
			new_anim.remove_track(i)
			continue
		var suffix = track_path.substr(colon_idx)
		new_anim.track_set_path(i, NodePath(target_str + suffix))
	return new_anim

const STANDARD_ALIASES = {
	"idle": ["idle"],
	"walk": ["walk", "run"],
	"run": ["run", "walk"],
	"call": ["celebration", "fight_idle", "shooting_standing", "idle"],
	"jump": ["jump", "air_jump"],
	"attack": ["fight_punch", "fight_kick"],
}

static func _register_standard_aliases(library: AnimationLibrary) -> void:
	"""Ensure simple gameplay names (idle/walk/run/call/jump/attack) always
	resolve to a real clip, whatever the raw Mixamo export named it."""
	var available = library.get_animation_list()
	for alias in STANDARD_ALIASES:
		if library.has_animation(alias):
			continue
		var match_name = _find_best_match(available, STANDARD_ALIASES[alias])
		if match_name != "":
			library.add_animation(alias, library.get_animation(match_name))

static func _find_best_match(available: PackedStringArray, keywords: Array) -> String:
	for keyword in keywords:
		var best = ""
		for anim_name in available:
			var lower_name = anim_name.to_lower()
			if lower_name == keyword:
				return anim_name
			if lower_name.begins_with(keyword) and not lower_name.contains("skeleton") and not lower_name.contains("reset"):
				if best == "" or anim_name.length() < best.length():
					best = anim_name
		if best != "":
			return best
	return ""

static func _get_or_create_library(anim_player: AnimationPlayer) -> AnimationLibrary:
	"""Get the player's default AnimationLibrary, creating one if needed"""
	if anim_player.has_animation_library(""):
		return anim_player.get_animation_library("")
	var library = AnimationLibrary.new()
	anim_player.add_animation_library("", library)
	return library

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
