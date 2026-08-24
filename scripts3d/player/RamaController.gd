extends CharacterBody3D

class_name RamaController

# Movement
@export var walk_speed: float = 5.0
@export var run_speed: float = 9.0
@export var jump_velocity: float = 8.5
@export var gravity: float = 22.0
@export var rotate_speed: float = 8.0

# States
var is_calling: bool = false
var call_cooldown: float = 0.0
var call_intensity: float = 0.0  # How loud/emotional the call is

# Components
@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var audio_player: AudioStreamPlayer3D = $CallAudio

# Camera
@onready var camera: Camera3D = $Camera3D

# Systems
var inventory: InventorySystem
var detection_range: float = 10.0

# Signals
signal rama_called(intensity: float)
signal dialogue_started
signal dialogue_ended
signal item_collected(item_name: String)

func _ready() -> void:
	add_to_group("player")
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		add_child(audio_player)

	inventory = InventorySystem.new()
	add_child(inventory)

	# Load animations for Rama
	if anim_player:
		CharacterAnimationSetup.load_animations_for_player(anim_player, "hanuman_final")
		if anim_player.has_animation("idle"):
			anim_player.play("idle")

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Handle movement input
	_handle_movement(delta)

	# Handle calling for Sita
	_handle_calling(delta)

	move_and_slide()

func _handle_movement(delta: float) -> void:
	"""Handle Rama's movement through forest"""
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if input_dir.length() > 0.01:
		input_dir = input_dir.normalized()

		# Get camera basis for movement direction
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

		# Calculate speed based on sprinting
		var is_sprinting = Input.is_action_pressed("dash")
		var speed = run_speed if is_sprinting else walk_speed

		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed

		# Rotate character to face movement direction
		var target_angle = atan2(move_dir.x, move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_angle, rotate_speed * delta)

		# Play walk/run animation
		if not is_calling:
			var target_anim = "run" if is_sprinting else "walk"
			if anim_player and anim_player.current_animation != target_anim:
				anim_player.play(target_anim)
	else:
		# Idle when not moving
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

		if not is_calling and anim_player:
			if anim_player.current_animation != "idle":
				anim_player.play("idle")

func _handle_calling(delta: float) -> void:
	"""Handle Rama calling for Sita"""
	call_cooldown = maxf(call_cooldown - delta, 0.0)

	# Call for Sita (spacebar or custom action)
	if Input.is_action_just_pressed("call_sita") and call_cooldown <= 0.0:
		_call_for_sita()

func _call_for_sita() -> void:
	"""Rama calls out desperately for Sita"""
	is_calling = true
	call_cooldown = 5.0  # 5 second cooldown between calls

	# Animation
	if anim_player:
		anim_player.play("call")

	# Emit signal (for NPC reactions)
	call_intensity = randf_range(0.8, 1.0)  # Random emotional intensity
	rama_called.emit(call_intensity)

	# Play audio (will add real voice later)
	_play_call_audio()

	# Duration of call animation
	await get_tree().create_timer(2.0).timeout
	is_calling = false

func _play_call_audio() -> void:
	"""Play Rama's calling sound"""
	if audio_player:
		# For now, just play a basic sound
		# Later: add proper voice acting
		audio_player.pitch_scale = randf_range(0.95, 1.05)
		# audio_player.play()

func get_character_name() -> String:
	return "Rama"

func talk_to_npc(npc_name: String) -> void:
	"""Start dialogue with an NPC"""
	velocity.x = 0.0
	velocity.z = 0.0
	dialogue_started.emit()
	if anim_player:
		anim_player.play("idle")

func end_dialogue() -> void:
	"""End dialogue with NPC"""
	dialogue_ended.emit()

func is_moving() -> bool:
	"""Check if Rama is currently moving"""
	return velocity.length() > 0.1
