extends CharacterBody3D

class_name ScoutNPC

enum State { IDLE, PATROLLING, TALKING, FOLLOWING }

@export var npc_name: String = "Scout"
@export var walk_speed: float = 3.5
@export var run_speed: float = 6.0
@export var gravity: float = 22.0
@export var dialogue_radius: float = 5.0

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var current_state: State = State.IDLE
var target_position: Vector3 = Vector3.ZERO
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var can_talk: bool = true
var talked_with_player: bool = false

signal dialogue_triggered(npc_name: String)

func _ready() -> void:
	add_to_group("npcs")
	add_to_group("scouts")
	current_state = State.IDLE
	target_position = global_position
	_setup_patrol_points()

	if anim_player:
		CharacterAnimationSetup.load_animations_for_player(anim_player, "demon_demon_blue")
		if anim_player.has_animation("idle"):
			anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.IDLE:
			_idle_behavior(delta)
		State.PATROLLING:
			_patrol_behavior(delta)
		State.TALKING:
			_talking_behavior(delta)
		State.FOLLOWING:
			_following_behavior(delta)

	move_and_slide()

func _setup_patrol_points() -> void:
	var base_pos = global_position
	patrol_points = [
		base_pos,
		base_pos + Vector3(20, 0, 0),
		base_pos + Vector3(20, 0, 20),
		base_pos + Vector3(0, 0, 20),
	]

func _idle_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

	if randf() < 0.001:
		current_state = State.PATROLLING

func _patrol_behavior(delta: float) -> void:
	if patrol_points.is_empty():
		current_state = State.IDLE
		return

	var target = patrol_points[current_patrol_index]

	if global_position.distance_to(target) < 2.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		target = patrol_points[current_patrol_index]

	var direction = (target - global_position).normalized()
	direction.y = 0.0

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		if anim_player and anim_player.current_animation != "walk":
			anim_player.play("walk")

func _talking_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

func _following_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

func interact() -> void:
	if not can_talk:
		return

	current_state = State.TALKING
	can_talk = false
	dialogue_triggered.emit(npc_name)

	await get_tree().create_timer(3.0).timeout
	current_state = State.IDLE
	talked_with_player = true

func get_npc_name() -> String:
	return npc_name

func is_in_dialogue_range(player_pos: Vector3) -> bool:
	return global_position.distance_to(player_pos) < dialogue_radius
