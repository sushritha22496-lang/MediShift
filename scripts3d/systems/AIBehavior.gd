extends Node3D

class_name AIBehavior

enum BehaviorState { IDLE, PATROL, FOLLOW, ATTACK, FLEE }

@export var patrol_radius: float = 20.0
@export var follow_distance: float = 5.0
@export var stop_distance: float = 1.0

var character: CharacterBody3D
var target: Node3D
var state: BehaviorState = BehaviorState.IDLE
var patrol_target: Vector3
var move_speed: float = 4.0

signal state_changed(new_state: BehaviorState)

func _ready() -> void:
	character = get_parent()
	_select_patrol_point()

func set_target(t: Node3D) -> void:
	target = t
	if t:
		state = BehaviorState.FOLLOW
	else:
		state = BehaviorState.IDLE
		_select_patrol_point()
	state_changed.emit(state)

func _process(delta: float) -> void:
	if not character:
		return

	match state:
		BehaviorState.IDLE:
			_idle_behavior(delta)
		BehaviorState.PATROL:
			_patrol_behavior(delta)
		BehaviorState.FOLLOW:
			_follow_behavior(delta)
		BehaviorState.ATTACK:
			_attack_behavior(delta)
		BehaviorState.FLEE:
			_flee_behavior(delta)

func _idle_behavior(delta: float) -> void:
	character.velocity *= 0.95
	if randf() < 0.01:
		state = BehaviorState.PATROL
		_select_patrol_point()

func _patrol_behavior(delta: float) -> void:
	var dist = character.global_position.distance_to(patrol_target)
	if dist < stop_distance:
		state = BehaviorState.IDLE
		return
	var dir = (patrol_target - character.global_position).normalized()
	character.velocity.x = dir.x * move_speed
	character.velocity.z = dir.z * move_speed

func _follow_behavior(delta: float) -> void:
	if not target:
		state = BehaviorState.IDLE
		return
	var dist = character.global_position.distance_to(target.global_position)
	if dist < follow_distance:
		character.velocity *= 0.9
		return
	var dir = (target.global_position - character.global_position).normalized()
	character.velocity.x = dir.x * move_speed
	character.velocity.z = dir.z * move_speed

func _attack_behavior(delta: float) -> void:
	if target:
		character.global_position = character.global_position.lerp(target.global_position, 0.1)

func _flee_behavior(delta: float) -> void:
	if target:
		var dir = (character.global_position - target.global_position).normalized()
		character.velocity.x = dir.x * move_speed * 1.5
		character.velocity.z = dir.z * move_speed * 1.5

func _select_patrol_point() -> void:
	var angle = randf() * TAU
	var dist = randf_range(5, patrol_radius)
	patrol_target = character.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
