extends CharacterBody3D

class_name RamaControllerSimple

@export var walk_speed: float = 5.0
@export var run_speed: float = 9.0
@export var jump_velocity: float = 8.5
@export var gravity: float = 22.0
@export var rotate_speed: float = 8.0

var is_calling: bool = false
var call_cooldown: float = 0.0
var call_intensity: float = 0.0

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var camera: Camera3D = $Camera3D
@onready var audio_player: AudioStreamPlayer3D = $CallAudio

signal rama_called(intensity: float)

func _ready() -> void:
	add_to_group("player")
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)

	if anim_player:
		_load_animations()
		if anim_player.has_animation("idle"):
			anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	_handle_movement(delta)
	_handle_calling(delta)

	move_and_slide()

func _handle_movement(delta: float) -> void:
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if input_dir.length() > 0.01:
		input_dir = input_dir.normalized()

		var cam_basis = camera.global_transform.basis
		var forward = -cam_basis.z
		forward.y = 0.0
		forward = forward.normalized()

		var right = cam_basis.x
		right.y = 0.0
		right = right.normalized()

		var move_dir = right * input_dir.x + forward * input_dir.y
		move_dir.y = 0.0
		move_dir = move_dir.normalized()

		var is_sprinting = Input.is_action_pressed("dash")
		var speed = run_speed if is_sprinting else walk_speed

		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed

		var target_angle = atan2(move_dir.x, move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotate_speed * delta)

		if not is_calling:
			var target_anim = "run" if is_sprinting else "walk"
			if anim_player and anim_player.current_animation != target_anim:
				anim_player.play(target_anim)
	else:
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

		if not is_calling and anim_player:
			if anim_player.current_animation != "idle":
				anim_player.play("idle")

func _handle_calling(delta: float) -> void:
	call_cooldown = maxf(call_cooldown - delta, 0.0)

	if Input.is_action_just_pressed("call_sita") and call_cooldown <= 0.0:
		_call_for_sita()

func _call_for_sita() -> void:
	is_calling = true
	call_cooldown = 5.0

	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")

	call_intensity = randf_range(0.8, 1.0)
	rama_called.emit(call_intensity)

	_play_call_audio()

	await get_tree().create_timer(1.5).timeout
	is_calling = false

func _play_call_audio() -> void:
	if audio_player:
		audio_player.pitch_scale = randf_range(0.95, 1.05)

func _load_animations() -> void:
	var animations_to_load = ["idle", "walk", "run", "attack", "jump"]

	for anim_name in animations_to_load:
		if anim_player.has_animation(anim_name):
			continue

		var anim_path = "res://assets/animations/rama/%s.tres" % anim_name
		if ResourceLoader.exists(anim_path):
			var anim = load(anim_path)
			anim_player.add_animation(anim_name, anim)

func get_character_name() -> String:
	return "Rama"

func is_moving() -> bool:
	return velocity.length() > 0.1
