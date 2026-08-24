extends NPCSimple

class_name EnemySimple

@export var detection_range: float = 20.0
@export var patrol_distance: float = 20.0
@export var attack_cooldown: float = 1.5

var target: Node3D = null
var patrol_point: Vector3 = Vector3.ZERO
var last_attack_time: float = 0.0

signal enemy_died
signal enemy_attacked(target: Node3D, damage: float)

func _ready() -> void:
	npc_name = "Enemy"
	add_to_group("enemies")
	patrol_point = global_position + Vector3(randf_range(-patrol_distance, patrol_distance), 0, randf_range(-patrol_distance, patrol_distance))
	target_position = patrol_point
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
		State.MOVING:
			_chase_state(delta)
		State.APPROACHING:
			_attack_state(delta)
		State.TALKING:
			_dead_state(delta)

	move_and_slide()

func _patrol_state(delta: float) -> void:
	if global_position.distance_to(patrol_point) < 2.0:
		patrol_point = global_position + Vector3(randf_range(-patrol_distance, patrol_distance), 0, randf_range(-patrol_distance, patrol_distance))
	_move_to(patrol_point, walk_speed, "walk")
	_check_for_target()

func _alert_state(delta: float) -> void:
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance > detection_range:
			change_state(State.IDLE)
			target = null
		else:
			change_state(State.MOVING)

func _chase_state(delta: float) -> void:
	if not target or not is_instance_valid(target):
		change_state(State.IDLE)
		return
	var distance = global_position.distance_to(target.global_position)
	if distance > detection_range:
		change_state(State.IDLE)
		target = null
	elif distance < approach_distance:
		change_state(State.APPROACHING)
	else:
		_move_to(target.global_position, run_speed, "run")

func _attack_state(delta: float) -> void:
	_play_anim("attack")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	if Time.get_ticks_msec() - last_attack_time > attack_cooldown * 1000:
		_perform_attack()
		last_attack_time = Time.get_ticks_msec()
	if target and is_instance_valid(target):
		if global_position.distance_to(target.global_position) > approach_distance:
			change_state(State.MOVING)

func _dead_state(delta: float) -> void:
	velocity = Vector3.ZERO

func _check_for_target() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(player.global_position) < detection_range:
			target = player
			change_state(State.ALERT)
			break

func _perform_attack() -> void:
	if target and is_instance_valid(target):
		var damage = randf_range(5.0, 15.0)
		enemy_attacked.emit(target, damage)
		if target.has_method("take_damage"):
			target.take_damage(damage)

func take_damage(amount: float) -> void:
	velocity.y -= gravity * 0.016
	if global_position.distance_to(target.global_position) > approach_distance:
		die()

func die() -> void:
	change_state(State.TALKING)
	enemy_died.emit()
	await get_tree().create_timer(2.0).timeout
	queue_free()
