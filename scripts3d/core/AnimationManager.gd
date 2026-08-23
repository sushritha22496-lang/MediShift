extends Node

class_name AnimationManager

# Animation cache
var loaded_animations: Dictionary = {}

# Animation mapping for character states
var animation_states: Dictionary = {
	"idle": "idle",
	"walk": "walk",
	"run": "run",
	"attack": "attack",
	"get_hit": "get_hit",
	"death": "death",
	"jump": "jump",
	"celebrate": "celebration"
}

func _ready() -> void:
	pass

func load_character_animations(character_name: String) -> bool:
	"""Load animations for a character from glTF file"""
	var anim_file = "res://assets/animations/humanoid/%s_animations.glb" % character_name.to_lower()

	if anim_file in loaded_animations:
		return loaded_animations[anim_file] != null

	if not ResourceLoader.exists(anim_file):
		print("⚠️ Animation file not found: %s" % anim_file)
		loaded_animations[anim_file] = null
		return false

	var scene = load(anim_file)
	if scene:
		loaded_animations[anim_file] = scene
		print("✅ Loaded animations for: %s" % character_name)
		return true
	else:
		print("❌ Failed to load: %s" % anim_file)
		loaded_animations[anim_file] = null
		return false

func get_animation_name(state: String) -> String:
	"""Get animation name for a state"""
	return animation_states.get(state, state)

func apply_animations_to_player(anim_player: AnimationPlayer, character_name: String) -> void:
	"""Apply loaded animations to an AnimationPlayer"""
	var anim_file = "res://assets/animations/humanoid/%s_animations.glb" % character_name.to_lower()

	if not anim_file in loaded_animations or loaded_animations[anim_file] == null:
		if not load_character_animations(character_name):
			return

	var anim_scene = loaded_animations[anim_file]
	if anim_scene and anim_scene is PackedScene:
		var anim_node = anim_scene.instantiate()
		if anim_node is AnimationPlayer:
			for anim_name in anim_node.get_animation_list():
				var anim = anim_node.get_animation(anim_name)
				if not anim_player.has_animation(anim_name):
					anim_player.add_animation(anim_name, anim)
