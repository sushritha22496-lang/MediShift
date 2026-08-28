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
var anim_controller: SmoothAnimationController
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

	# Load rigged character from Mixamo or fallback to procedural
	if not RiggedCharacterLoader.load_character(self, "rama"):
		if model:
			ProfessionalCharacterBuilder.build_rama_professional(self)

	# Initialize smooth animation controller
	anim_controller = SmoothAnimationController.new()
	add_child(anim_controller)
	anim_controller.initialize(self)

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

	# Update animations based on velocity
	if anim_controller:
		var is_sprint = Input.is_action_pressed("dash")
		anim_controller.update(velocity, delta, is_sprint)

	move_and_slide()

func _handle_movement(delta: float) -> void:
	var input_dir = Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down"))

	if input_dir.length() > 0.01:
		input_dir = input_dir.normalized()
		var cam = camera.global_transform.basis
		var fwd = (-cam.z).normalized()
		var rgt = cam.x.normalized()
		var move_dir = (rgt * input_dir.x + fwd * input_dir.y).normalized()
		var is_sprint = Input.is_action_pressed("dash")
		var spd = run_speed if is_sprint else walk_speed
		velocity.x = move_dir.x * spd
		velocity.z = move_dir.z * spd
		model.rotation.y = lerp_angle(model.rotation.y, atan2(move_dir.x, move_dir.z), rotate_speed * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

func _handle_calling(delta: float) -> void:
	"""Handle Rama calling for Sita"""
	call_cooldown = maxf(call_cooldown - delta, 0.0)

	# Call for Sita (spacebar or custom action)
	if Input.is_action_just_pressed("call_sita") and call_cooldown <= 0.0:
		_call_for_sita()

func _call_for_sita() -> void:
	is_calling = true
	call_cooldown = 5.0

	# Play call/shout animation
	if anim_controller:
		anim_controller.play_action("call")

	# Emit signal (for NPC reactions)
	call_intensity = randf_range(0.8, 1.0)
	rama_called.emit(call_intensity)

	# Play audio
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
	velocity.x = 0.0
	velocity.z = 0.0
	dialogue_started.emit()
	if anim_state:
		anim_state.play("idle")

func end_dialogue() -> void:
	"""End dialogue with NPC"""
	dialogue_ended.emit()

func is_moving() -> bool:
	"""Check if Rama is currently moving"""
	return velocity.length() > 0.1
