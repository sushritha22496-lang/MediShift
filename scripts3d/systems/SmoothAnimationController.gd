extends Node3D

class_name SmoothAnimationController

var character: Node3D = null
var anim_player: AnimationPlayer = null
var current_anim: String = "idle"
var velocity_magnitude: float = 0.0
var target_speed: float = 0.0

# Animation state thresholds
var idle_threshold: float = 0.1
var walk_threshold: float = 2.0
var run_threshold: float = 5.0

# Transition smoothness
var blend_speed: float = 8.0
var transition_duration: float = 0.15

# Footstep timing
var footstep_timer: float = 0.0
var footstep_interval: float = 0.5

func initialize(char: Node3D) -> void:
	character = char
	var model = char.get_node_or_null("Model")
	if model:
		anim_player = _find_animation_player(model)

func update(velocity: Vector3, delta: float, is_sprinting: bool = false) -> void:
	if not character:
		return

	velocity_magnitude = velocity.length()
	_update_locomotion_animation(is_sprinting, delta)
	_update_footsteps(delta)

func _update_locomotion_animation(is_sprinting: bool, delta: float) -> void:
	var target_anim = "idle"

	if velocity_magnitude > run_threshold and is_sprinting:
		target_anim = "run"
	elif velocity_magnitude > walk_threshold:
		target_anim = "run"
	elif velocity_magnitude > idle_threshold:
		target_anim = "walk"
	else:
		target_anim = "idle"

	if current_anim != target_anim:
		_play_smooth_transition(target_anim)

func _play_smooth_transition(target_anim: String) -> void:
	if not character:
		return

	current_anim = target_anim

	# Try rigged character loader first (for Mixamo models)
	if RiggedCharacterLoader.play_animation(character, target_anim):
		return

	# Fallback to direct animation player
	if anim_player and anim_player.has_animation(target_anim):
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_parallel(false)
		if anim_player.is_playing():
			tween.tween_callback(func():
				anim_player.play(target_anim)
				if anim_player.speed_scale != 1.0:
					anim_player.speed_scale = 1.0
			)
		else:
			anim_player.play(target_anim)

func play_action(action: String, one_shot: bool = false) -> bool:
	if not character:
		return false

	if RiggedCharacterLoader.play_animation(character, action):
		if one_shot:
			await get_tree().create_timer(0.5).timeout
			_play_smooth_transition(current_anim)
		return true

	if anim_player and anim_player.has_animation(action):
		anim_player.play(action)
		return true

	return false

func _update_footsteps(delta: float) -> void:
	footstep_timer += delta

	# Play footstep every interval during walk/run
	if velocity_magnitude > idle_threshold and footstep_timer >= footstep_interval:
		footstep_timer = 0.0
		_spawn_footstep()

func _spawn_footstep() -> void:
	if not character:
		return

	var pos = character.global_position + Vector3(0, 0.1, 0)
	ParticleEffects.spawn_dust_effect(pos, character.get_parent() if character.get_parent() else character)

func add_impact_feedback(force: float = 1.0) -> void:
	if not character or not character.has_node("Model"):
		return

	var model = character.get_node("Model")
	var tween = create_tween()
	var original_scale = model.scale
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(model, "scale", original_scale * Vector3(1.15, 0.85, 1.15), 0.08)
	tween.tween_property(model, "scale", original_scale, 0.12)

func get_animation_list() -> PackedStringArray:
	return RiggedCharacterLoader.get_all_animations(character)

func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null
