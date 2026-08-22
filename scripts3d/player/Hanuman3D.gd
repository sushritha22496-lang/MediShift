extends CharacterBody3D

const WALK_SPEED := 5.0
const RUN_SPEED := 9.0
const JUMP_VELOCITY := 8.5
const GRAVITY := 22.0
const ROTATE_SPEED := 10.0
const ATTACK_COOLDOWN := 0.4

@export var max_health: float = 200.0
@export var gada_damage: float = 35.0

var health: float
var attack_cooldown: float = 0.0
var is_attacking: bool = false
var facing_yaw: float = 0.0
var lean: float = 0.0

@onready var model: Node3D = $Model
@onready var body_mesh: MeshInstance3D = $Model/Body
@onready var gada_pivot: Node3D = $Model/GadaPivot
@onready var attack_area: Area3D = $Model/GadaPivot/AttackArea
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var tail_mesh: MeshInstance3D = $Model/Tail
@onready var left_arm: Node3D = $Model/LeftArmPivot
@onready var left_leg: Node3D = $Model/LeftLegPivot
@onready var right_leg: Node3D = $Model/RightLegPivot

signal health_changed(current: float, maximum: float)
signal died()

func _ready() -> void:
	add_to_group("player3d")
	health = max_health
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_gada_hit)
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_attack(delta)
	_handle_camera_input(delta)
	_animate_idle_motion(delta)
	move_and_slide()

func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_VELOCITY

func _handle_movement(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	var cam_basis := camera.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right: Vector3 = cam_basis.x
	right.y = 0.0
	right = right.normalized()

	var move_dir: Vector3 = (right * input_dir.x + forward * -input_dir.y)
	move_dir.y = 0.0
	var speed: float = RUN_SPEED if Input.is_action_pressed("dash") else WALK_SPEED

	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		facing_yaw = atan2(move_dir.x, move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, facing_yaw, ROTATE_SPEED * delta)
		lean = clampf(lean + delta * 4.0, 0.0, 1.0)
	else:
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
		lean = clampf(lean - delta * 4.0, 0.0, 1.0)

	model.rotation.z = lerp_angle(model.rotation.z, -0.08 * lean, 8.0 * delta)

func _handle_camera_input(delta: float) -> void:
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		pass

func _animate_idle_motion(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var moving := Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		var walk_speed := 10.0
		body_mesh.position.y = 0.9 + sin(t * walk_speed) * 0.05
		tail_mesh.rotation.x = sin(t * walk_speed) * 0.4
		if not is_attacking:
			left_arm.rotation.x = sin(t * walk_speed) * 0.9
			gada_pivot.rotation.x = 0.3 - sin(t * walk_speed) * 0.5
		left_leg.rotation.x = sin(t * walk_speed) * 0.7
		right_leg.rotation.x = -sin(t * walk_speed) * 0.7
	else:
		body_mesh.position.y = 0.9 + sin(t * 2.0) * 0.02
		tail_mesh.rotation.x = sin(t * 1.5) * 0.15
		if not is_attacking:
			left_arm.rotation.x = lerp_angle(left_arm.rotation.x, 0.0, 6.0 * delta)
			gada_pivot.rotation.x = lerp_angle(gada_pivot.rotation.x, 0.3, 6.0 * delta)
		left_leg.rotation.x = lerp_angle(left_leg.rotation.x, 0.0, 6.0 * delta)
		right_leg.rotation.x = lerp_angle(right_leg.rotation.x, 0.0, 6.0 * delta)

func _handle_attack(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0 and not is_attacking:
		_do_attack()

func _do_attack() -> void:
	is_attacking = true
	attack_cooldown = ATTACK_COOLDOWN
	attack_area.monitoring = true
	var tween := create_tween()
	tween.tween_property(gada_pivot, "rotation:x", -2.2, 0.12)
	tween.tween_property(gada_pivot, "rotation:x", 0.3, 0.18)
	await tween.finished
	attack_area.monitoring = false
	is_attacking = false

func _on_gada_hit(body: Node3D) -> void:
	if body.has_method("take_damage_3d"):
		body.take_damage_3d(gada_damage, global_position)

func take_damage_3d(amount: float, source_pos: Vector3) -> void:
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()
