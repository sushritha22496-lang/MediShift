# Character3D with Animation Support
# Enhanced base class for all characters (player, enemies, bosses)

extends CharacterBody3D

class_name Character3D

# Animation states
enum AnimState { IDLE, WALK, RUN, ATTACK, GET_HIT, DEAD }

# Character stats
@export var max_health: float = 100.0
@export var character_name: String = "Character"
@export var attack_damage: float = 25.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 0.5
@export var movement_speed: float = 5.0
@export var sprint_speed: float = 8.0

# State tracking
var health: float
var is_dead: bool = false
var current_anim_state: AnimState = AnimState.IDLE
var velocity: Vector3 = Vector3.ZERO
var can_attack: bool = true
var attack_timer: float = 0.0

# Components
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# Signals
signal health_changed(current: float, maximum: float)
signal died(character: Character3D)
signal attacked

func _ready() -> void:
	health = max_health
	emit_signal("health_changed", health, max_health)
	_setup_animations()

func _process(delta: float) -> void:
	if is_dead:
		return

	# Update attack cooldown
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true

	# Apply gravity
	velocity.y -= 9.8 * delta
	move_and_slide()

# Animation Management
var animation_mapping: Dictionary = {
	AnimState.IDLE: "idle",
	AnimState.WALK: "walk",
	AnimState.RUN: "run",
	AnimState.ATTACK: "attack",
	AnimState.GET_HIT: "get_hit",
	AnimState.DEAD: "death"
}

func _setup_animations() -> void:
	"""Load character-specific animations if available"""
	if not anim_player:
		return

	# Try to load character-specific animation library
	var anim_path = "res://assets/animations/humanoid/%s_animations.glb" % character_name.to_lower()
	if ResourceLoader.exists(anim_path):
		var anim_lib = load(anim_path)
		if anim_lib:
			anim_player.add_animation_library(character_name.to_lower(), anim_lib)
			print("✅ Loaded animations for: %s" % character_name)

func set_animation_state(state: AnimState) -> void:
	"""Change character animation"""
	if current_anim_state == state or is_dead:
		return

	current_anim_state = state

	if anim_player and animation_mapping.has(state):
		var anim_name = animation_mapping[state]

		# Try to play with library prefix first, then fallback
		var lib_anim_name = "%s/%s" % [character_name.to_lower(), anim_name]
		if anim_player.has_animation(lib_anim_name):
			anim_player.play(lib_anim_name)
		elif anim_player.has_animation(anim_name):
			anim_player.play(anim_name)
		else:
			# Silent fallback - animation may not be loaded yet
			pass

func move_character(input_vector: Vector3, is_sprinting: bool = false) -> void:
	"""Move character with animation"""
	if is_dead or input_vector.length() == 0:
		set_animation_state(AnimState.IDLE)
		velocity.x = 0
		velocity.z = 0
		return

	var speed = sprint_speed if is_sprinting else movement_speed
	velocity.x = input_vector.x * speed
	velocity.z = input_vector.z * speed

	# Rotate to face movement direction
	if input_vector.length() > 0:
		look_at(global_position + input_vector, Vector3.UP)
		set_animation_state(AnimState.RUN if is_sprinting else AnimState.WALK)

func attack_target(target: Character3D) -> void:
	"""Perform attack on target"""
	if not can_attack or is_dead or target.is_dead:
		return

	# Check range
	var distance = global_position.distance_to(target.global_position)
	if distance > attack_range:
		return

	can_attack = false
	attack_timer = attack_cooldown
	set_animation_state(AnimState.ATTACK)

	# Deal damage
	target.take_damage(attack_damage)
	emit_signal("attacked")

func take_damage(damage: float) -> void:
	"""Receive damage"""
	if is_dead:
		return

	health -= damage
	emit_signal("health_changed", health, max_health)

	set_animation_state(AnimState.GET_HIT)

	if health <= 0:
		die()

func die() -> void:
	"""Character death"""
	is_dead = true
	set_animation_state(AnimState.DEAD)
	emit_signal("died", self)

	# Disable collision after death animation
	await get_tree().create_timer(2.0).timeout
	collision_shape.disabled = true

func get_health_percent() -> float:
	"""Return health as percentage"""
	return health / max_health
