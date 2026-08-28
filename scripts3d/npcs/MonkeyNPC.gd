extends CharacterBody3D

class_name MonkeyNPC

enum State { IDLE, PLAYING, EATING, CLIMBING, EXPLORING, RESTING }

@export var monkey_name: String = "Monkey"
@export var walk_speed: float = 3.0
@export var run_speed: float = 6.0
@export var gravity: float = 22.0
@export var roam_range: float = 30.0

var current_state: State = State.IDLE
var state_timer: float = 0.0
var target_position: Vector3 = Vector3.ZERO
var idle_duration: float = 0.0

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer

func _ready() -> void:
	add_to_group("npcs")
	add_to_group("monkeys")
	current_state = State.IDLE
	target_position = global_position
	# Load rigged character from Mixamo or fallback to procedural
	if not RiggedCharacterLoader.load_character(self, "monkey"):
		if model:
			ProfessionalCharacterBuilder.build_monkey_professional(self)
	_start_new_activity()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	state_timer -= delta

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.PLAYING:
			_playing_behavior(delta)
		State.EATING:
			_eating_behavior(delta)
		State.EXPLORING:
			_exploring_behavior(delta)
		State.RESTING:
			_resting_behavior(delta)

	move_and_slide()

	# Change activity periodically
	if state_timer <= 0.0:
		_start_new_activity()

func _idle_behavior(delta: float) -> void:
	"""Just standing/sitting around"""
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	_play_animation("idle")

func _playing_behavior(delta: float) -> void:
	"""Monkeys playing, jumping around"""
	if global_position.distance_to(target_position) < 2.0:
		target_position = global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))

	var direction = (target_position - global_position).normalized()
	direction.y = 0.0

	velocity.x = direction.x * run_speed
	velocity.z = direction.z * run_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		_play_animation("run")

func _eating_behavior(delta: float) -> void:
	"""Eating fruits, foraging"""
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	_play_animation("idle")
	# In a real game, monkey would be eating animation

func _exploring_behavior(delta: float) -> void:
	"""Walking around exploring"""
	if global_position.distance_to(target_position) < 1.5:
		target_position = global_position + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
		target_position = target_position.clamp(
			global_position - Vector3(roam_range, 0, roam_range),
			global_position + Vector3(roam_range, 0, roam_range)
		)

	var direction = (target_position - global_position).normalized()
	direction.y = 0.0

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		_play_animation("walk")

func _resting_behavior(delta: float) -> void:
	"""Lying down, sleeping"""
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	_play_animation("idle")

func _start_new_activity() -> void:
	"""Switch to random activity"""
	var activities = [State.IDLE, State.PLAYING, State.EATING, State.EXPLORING, State.RESTING]
	current_state = activities[randi() % activities.size()]
	state_timer = randf_range(3.0, 8.0)

	if current_state == State.PLAYING or current_state == State.EXPLORING:
		target_position = global_position + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))

	# Use rich animations from Mixamo: dance, sing, chant, gestures, emotes
	if current_state == State.IDLE and randf() > 0.6:
		var idle_variants = ["dance", "sing", "chant", "gesture", "emote", "play"]
		var anim = RiggedCharacterLoader.random_animation(self, idle_variants[randi() % idle_variants.size()])
		RiggedCharacterLoader.play_animation(self, anim)

func _play_animation(anim_name: String) -> void:
	"""Play animation safely"""
	if anim_player and not anim_player.is_playing():
		if anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
		elif anim_name == "idle" and anim_player.has_animation("idle"):
			anim_player.play("idle")

func get_character_name() -> String:
	return monkey_name

func is_playing() -> bool:
	return current_state == State.PLAYING
