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
@export var approach_distance: float = 3.0  # How close to get before initiating meeting
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
	"""Hanuman does nothing, waiting and watching"""
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

func _foraging_behavior(delta: float) -> void:
	"""Hanuman searches for fruits and food"""
	# Wander around looking for food
	if global_position.distance_to(target_position) < 2.0:
		# Reached target, find new location
		target_position = global_position + Vector3(randf_range(-10, 10), 0, randf_range(-10, 10))

	var direction = (target_position - global_position).normalized()
	direction.y = 0.0

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		if anim_player and anim_player.current_animation != "walk":
			anim_player.play("walk")
	else:
		if anim_player and anim_player.current_animation != "idle":
			anim_player.play("idle")

func _curious_behavior(delta: float) -> void:
	"""Hanuman is curious about the sound, listening carefully"""
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

	# After listening, move to investigate
	if rama and rama.is_in_group("player"):
		var distance = global_position.distance_to(rama.global_position)
		if distance < hearing_range and distance > approach_distance:
			current_state = State.APPROACHING
			rama_detected.emit()

func _approaching_behavior(delta: float) -> void:
	"""Hanuman moves toward Rama"""
	if not rama:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(rama.global_position)

	# Check if close enough to meet
	if distance < approach_distance:
		current_state = State.MEETING
		meeting_initiated.emit()
		_initiate_meeting()
		return

	# Move toward Rama
	var direction = (rama.global_position - global_position).normalized()
	direction.y = 0.0

	velocity.x = direction.x * run_speed
	velocity.z = direction.z * run_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		if anim_player and anim_player.current_animation != "run":
			anim_player.play("run")

func _meeting_behavior(delta: float) -> void:
	"""Hanuman has met Rama - dialogue time"""
	velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

func _following_behavior(delta: float) -> void:
	"""Hanuman follows Rama on the mission"""
	if not rama:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(rama.global_position)

	# Stay close to Rama
	if distance > 5.0:
		var direction = (rama.global_position - global_position).normalized()
		direction.y = 0.0

		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed

		if direction.length() > 0.1:
			model.rotation.y = atan2(direction.x, direction.z)
			if anim_player and anim_player.current_animation != "walk":
				anim_player.play("walk")
	else:
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

		if anim_player and anim_player.current_animation != "idle":
			anim_player.play("idle")

func detect_rama_call(rama_node: Node3D, call_intensity: float) -> void:
	"""Called when Rama calls for Sita"""
	if has_met_rama:
		return

	rama = rama_node
	var distance = global_position.distance_to(rama.global_position)

	# Check if within hearing range
	if distance < hearing_range:
		# Check if call is interesting/desperate enough
		if call_intensity >= curiosity_threshold:
			if current_state != State.APPROACHING and current_state != State.MEETING:
				current_state = State.CURIOUS
				print("🐵 Hanuman hears a desperate cry! Investigating...")

func _initiate_meeting() -> void:
	"""Start the meeting scene between Rama and Hanuman"""
	has_met_rama = true
	print("🐵 Hanuman: Who are you? Why do you call with such sorrow?")
	await get_tree().create_timer(2.0).timeout
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
