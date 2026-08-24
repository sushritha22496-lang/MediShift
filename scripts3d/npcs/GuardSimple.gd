extends CharacterBody3D

class_name GuardSimple

enum State { PATROL, ALERT, CHALLENGE, TALKING }

@export var walk_speed: float = 3.0
@export var gravity: float = 22.0
@export var detection_range: float = 30.0
@export var patrol_points: Array[Vector3] = []

var current_state: State = State.PATROL
var patrol_index: int = 0
var target: Node3D = null
var dialogue: String = "Halt! State your business!"

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer

signal guard_challenged(player: Node3D)
signal guard_dialogue(text: String)

func _ready() -> void:
	add_to_group("npcs")
	if patrol_points.is_empty():
		patrol_points = [global_position, global_position + Vector3(20, 0, 0)]

	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.PATROL:
			_patrol_behavior(delta)
		State.ALERT:
			_alert_behavior(delta)
		State.CHALLENGE:
			_challenge_behavior(delta)
		State.TALKING:
			_talking_behavior(delta)

	move_and_slide()

func _patrol_behavior(delta: float) -> void:
	if patrol_points.is_empty():
		return

	var target_point = patrol_points[patrol_index]
	if global_position.distance_to(target_point) < 2.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()

	var direction = (target_point - global_position).normalized()
	direction.y = 0

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		if anim_player and anim_player.current_animation != "walk":
			anim_player.play("walk")

	_check_for_intruder()

func _alert_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance < detection_range:
			current_state = State.CHALLENGE
		else:
			current_state = State.PATROL
			target = null

func _challenge_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

func _talking_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)

func _check_for_intruder() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		var distance = global_position.distance_to(player.global_position)
		if distance < detection_range:
			target = player
			current_state = State.ALERT
			break

func challenge_player(player: Node3D) -> void:
	target = player
	current_state = State.CHALLENGE
	guard_challenged.emit(player)
	guard_dialogue.emit(dialogue)
