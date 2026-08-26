extends CharacterBody3D

class_name HanumanAI

# Hanuman states
enum State { IDLE, FORAGING, CURIOUS, APPROACHING, MEETING, FOLLOWING }

# Movement
@export var walk_speed: float = 4.0
@export var run_speed: float = 7.0
@export var gravity: float = 22.0
@export var rotate_speed: float = 10.0

# Behavior
@export var hearing_range: float = 50.0  # How far Hanuman can hear Rama's call
@export var approach_distance: float = 5.5  # How close to get before initiating meeting
@export var curiosity_threshold: float = 0.7  # How interesting the call is

# State
var current_state: State = State.IDLE
var rama: Node3D = null
var target_position: Vector3 = Vector3.ZERO
var call_heard: bool = false
var has_met_rama: bool = false

# Components
@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# Signals
signal rama_detected
signal meeting_initiated
signal agreement_reached

func _ready() -> void:
	add_to_group("npcs")
	add_to_group("monkeys")
	current_state = State.IDLE
	target_position = global_position

	# Load animations for Hanuman
	if anim_player:
		CharacterAnimationSetup.load_animations_for_player(anim_player, "hanuman_final")
		if anim_player.has_animation("idle"):
			anim_player.play("idle")

	# Muscular build, Gada, and dhoti
	if model:
		HanumanBuildEnhancer.enhance(model)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.FORAGING:
			_foraging_behavior(delta)
		State.CURIOUS:
			_curious_behavior(delta)
		State.APPROACHING:
			_approaching_behavior(delta)
		State.MEETING:
			_meeting_behavior(delta)
		State.FOLLOWING:
			_following_behavior(delta)

	move_and_slide()

func _idle_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

func _foraging_behavior(delta: float) -> void:
	if global_position.distance_to(target_position) < 2.0:
		target_position = global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))
	var dir = (target_position - global_position).normalized()
	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed
	if dir.length() > 0.1:
		model.rotation.y = atan2(dir.x, dir.z)
		if anim_player and anim_player.current_animation != "walk":
			anim_player.play("walk")
	elif anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

func _curious_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")
	if rama and rama.is_in_group("player"):
		var dist = global_position.distance_to(rama.global_position)
		if dist < hearing_range and dist > approach_distance:
			current_state = State.APPROACHING
			rama_detected.emit()

func _approaching_behavior(delta: float) -> void:
	if not rama:
		current_state = State.IDLE
		return
	var dist = global_position.distance_to(rama.global_position)
	if dist < approach_distance:
		current_state = State.MEETING
		meeting_initiated.emit()
		_initiate_meeting()
		return
	var dir = (rama.global_position - global_position).normalized()
	velocity.x = dir.x * run_speed
	velocity.z = dir.z * run_speed
	if dir.length() > 0.1:
		model.rotation.y = atan2(dir.x, dir.z)
		if anim_player and anim_player.current_animation != "run":
			anim_player.play("run")

func _meeting_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

func _following_behavior(delta: float) -> void:
	if not rama:
		current_state = State.IDLE
		return
	var dist = global_position.distance_to(rama.global_position)
	if dist > 5.0:
		var dir = (rama.global_position - global_position).normalized()
		velocity.x = dir.x * walk_speed
		velocity.z = dir.z * walk_speed
		if dir.length() > 0.1:
			model.rotation.y = atan2(dir.x, dir.z)
			if anim_player and anim_player.current_animation != "walk":
				anim_player.play("walk")
	else:
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
		if anim_player and anim_player.current_animation != "idle":
			anim_player.play("idle")

func detect_rama_call(rama_node: Node3D, call_intensity: float) -> void:
	if has_met_rama:
		return
	rama = rama_node
	var dist = global_position.distance_to(rama.global_position)
	if dist < hearing_range and call_intensity >= curiosity_threshold:
		if current_state != State.APPROACHING and current_state != State.MEETING:
			current_state = State.CURIOUS

func _initiate_meeting() -> void:
	has_met_rama = true
	await get_tree().create_timer(3.5).timeout
	agreement_reached.emit()
	current_state = State.FOLLOWING

func get_character_name() -> String:
	return "Hanuman"

func agree_to_help() -> void:
	"""Hanuman agrees to help Rama"""
	current_state = State.FOLLOWING
	print("🐵 Hanuman: I will help you find Sita! I swear by my strength!")

func set_rama_reference(rama_node: Node3D) -> void:
	"""Set reference to Rama"""
	rama = rama_node
