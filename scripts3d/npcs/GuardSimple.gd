extends NPCSimple

class_name GuardSimple

@export var detection_range: float = 30.0
@export var patrol_points: Array[Vector3] = []

var patrol_index: int = 0
var target: Node3D = null

signal guard_challenged(player: Node3D)
signal guard_speech(text: String)

func _ready() -> void:
	npc_name = "Guard"
	add_to_group("npcs")
	if patrol_points.is_empty():
		patrol_points = [global_position, global_position + Vector3(20, 0, 0)]
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.IDLE:
			_patrol_state(delta)
		State.ALERT:
			_alert_state(delta)
		State.APPROACHING:
			_challenge_state(delta)
		State.TALKING:
			_talking_state(delta)

	move_and_slide()

func _patrol_state(delta: float) -> void:
	if patrol_points.is_empty():
		return
	var target_point = patrol_points[patrol_index]
	if global_position.distance_to(target_point) < 2.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()
	_move_to(target_point, walk_speed, "walk")
	_check_for_intruder()

func _alert_state(delta: float) -> void:
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance < detection_range:
			change_state(State.APPROACHING)
		else:
			change_state(State.IDLE)
			target = null

func _challenge_state(delta: float) -> void:
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

func _talking_state(delta: float) -> void:
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)

func _check_for_intruder() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(player.global_position) < detection_range:
			target = player
			change_state(State.ALERT)
			break

func challenge_player(player: Node3D) -> void:
	target = player
	change_state(State.APPROACHING)
	guard_challenged.emit(player)
	guard_speech.emit("Halt! State your business!")
