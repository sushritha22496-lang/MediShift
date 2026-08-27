extends Node3D

class_name AdvancedAnimationBlender

class BlendState:
	var primary: String
	var secondary: String
	var blend_weight: float = 0.0
	var transition_speed: float = 2.0

var blend_states: Array[BlendState] = []
var current_speed: float = 0.0
var target_speed: float = 0.0
var anim_player: AnimationPlayer = null
var model: Node3D = null

func _ready() -> void:
	pass

func initialize(player: AnimationPlayer, character_model: Node3D) -> void:
	anim_player = player
	model = character_model

func update_movement_animation(velocity: Vector3, is_sprinting: bool, delta: float) -> void:
	if not anim_player:
		return

	var current_speed_magnitude = velocity.length()
	target_speed = current_speed_magnitude
	current_speed = lerp(current_speed, target_speed, delta * 5.0)

	if current_speed < 0.5:
		_blend_to_animation("idle", delta)
	elif current_speed < 4.0:
		_blend_to_animation("walk", delta)
	elif is_sprinting:
		_blend_to_animation("run", delta)
	else:
		_blend_to_animation("run", delta)

	if model:
		model.rotation.y = atan2(velocity.x, velocity.z)

func _blend_to_animation(target_anim: String, delta: float) -> void:
	if not anim_player:
		return

	if anim_player.current_animation != target_anim:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(func(): anim_player.play(target_anim))

func play_action_animation(action: String, duration: float = 1.0) -> void:
	if not anim_player:
		return
	if anim_player.has_animation(action):
		anim_player.play(action)

func update_idle_variation(delta: float) -> void:
	if not anim_player or anim_player.current_animation != "idle":
		return

	var anim_pos = anim_player.current_animation_position
	var anim_length = anim_player.current_animation_length

	if is_zero_approx(anim_length):
		return

	var progress = fmod(anim_pos, anim_length) / anim_length

	if model and randf() < 0.1:
		var sway = sin(progress * TAU) * 0.1
		model.position.x = sway
		model.rotation.z = sin(progress * TAU * 0.5) * 0.05

func add_footstep_effect(position: Vector3, intensity: float = 1.0) -> void:
	if not model:
		return
	ParticleEffects.spawn_dust_effect(position, model.get_parent())

func add_impact_animation(impact_force: Vector3) -> void:
	if not model:
		return

	var tween = create_tween()
	var original_scale = model.scale
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(model, "scale", original_scale * Vector3(1.1, 0.9, 1.1), 0.1)
	tween.tween_property(model, "scale", original_scale, 0.2)
