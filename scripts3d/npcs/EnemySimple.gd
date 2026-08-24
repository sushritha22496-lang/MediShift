extends CharacterBody3D

class_name EnemySimple

enum State { PATROL, ALERT, CHASE, ATTACK, DEAD }

@export var health: float = 30.0
@export var walk_speed: float = 3.0
@export var chase_speed: float = 6.0
@export var gravity: float = 22.0
@export var attack_range: float = 2.0
@export var detection_range: float = 20.0
@export var patrol_distance: float = 20.0

var current_health: float
var current_state: State = State.PATROL
var target: Node3D = null
var patrol_point: Vector3 = Vector3.ZERO
var last_attack_time: float = 0.0
var attack_cooldown: float = 1.5

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

signal enemy_died
signal enemy_attacked(target: Node3D, damage: float)

func _ready() -> void:
	add_to_group("enemies")
	current_health = health
	patrol_point = global_position + Vector3(randf_range(-patrol_distance, patrol_distance), 0, randf_range(-patrol_distance, patrol_distance))

	if anim_player:
		_load_animations()
		if anim_player.has_animation("idle"):
			anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if current_state != State.DEAD:
		if not is_on_floor():
			velocity.y -= gravity * delta

	match current_state:
		State.PATROL:
			_patrol_behavior(delta)
		State.ALERT:
			_alert_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)
		State.DEAD:
			_dead_behavior(delta)

	move_and_slide()

func _patrol_behavior(delta: float) -> void:
	if global_position.distance_to(patrol_point) < 2.0:
		patrol_point = global_position + Vector3(randf_range(-patrol_distance, patrol_distance), 0, randf_range(-patrol_distance, patrol_distance))

	var direction = (patrol_point - global_position).normalized()
	direction.y = 0.0

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		if anim_player and anim_player.current_animation != "walk":
			anim_player.play("walk")

	_check_for_target()

func _alert_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance > detection_range:
			current_state = State.PATROL
			target = null
		else:
			current_state = State.CHASE

func _chase_behavior(delta: float) -> void:
	if not target or not is_instance_valid(target):
		current_state = State.PATROL
		return

	var distance = global_position.distance_to(target.global_position)

	if distance > detection_range:
		current_state = State.PATROL
		target = null
		return

	if distance < attack_range:
		current_state = State.ATTACK
		return

	var direction = (target.global_position - global_position).normalized()
	direction.y = 0.0

	velocity.x = direction.x * chase_speed
	velocity.z = direction.z * chase_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		if anim_player and anim_player.current_animation != "run":
			anim_player.play("run")

func _attack_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "attack":
		anim_player.play("attack")

	if Time.get_ticks_msec() - last_attack_time > attack_cooldown * 1000:
		_perform_attack()
		last_attack_time = Time.get_ticks_msec()

	if target and is_instance_valid(target):
		var distance = global_position.distance_to(target.global_position)
		if distance > attack_range:
			current_state = State.CHASE

func _dead_behavior(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	velocity.y = 0

func _check_for_target() -> void:
	for player in get_tree().get_nodes_in_group("player"):
		var distance = global_position.distance_to(player.global_position)
		if distance < detection_range:
			target = player
			current_state = State.ALERT
			break

func _perform_attack() -> void:
	if target and is_instance_valid(target):
		var damage = randf_range(5.0, 15.0)
		enemy_attacked.emit(target, damage)
		if target.has_method("take_damage"):
			target.take_damage(damage)

func take_damage(amount: float) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	current_state = State.DEAD
	enemy_died.emit()
	await get_tree().create_timer(2.0).timeout
	queue_free()

func _load_animations() -> void:
	var animations_to_load = ["idle", "walk", "run", "attack"]
	for anim_name in animations_to_load:
		if anim_player.has_animation(anim_name):
			continue
		var anim_path = "res://assets/animations/enemy/%s.tres" % anim_name
		if ResourceLoader.exists(anim_path):
			var anim = load(anim_path)
			anim_player.add_animation(anim_name, anim)
