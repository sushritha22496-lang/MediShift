extends CharacterBody3D

const WALK_SPEED := 5.0
const RUN_SPEED := 9.0
const JUMP_VELOCITY := 8.5
const GRAVITY := 22.0
const ROTATE_SPEED := 10.0
const ATTACK_COOLDOWN := 0.6

@export var max_health: float = 200.0
@export var gada_damage: float = 35.0

var health: float
var attack_cooldown: float = 0.0
var is_attacking: bool = false
var facing_yaw: float = 0.0
var lean: float = 0.0
var blink_timer: float = 0.0

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var attack_area: Area3D = $Model/Skeleton/Skeleton3D/GadaAttach/AttackArea
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var eye_white_l: MeshInstance3D = $Model/Skeleton/Skeleton3D/EyeWhiteL
@onready var eye_white_r: MeshInstance3D = $Model/Skeleton/Skeleton3D/EyeWhiteR

signal health_changed(current: float, maximum: float)
signal died()

func _ready() -> void:
	add_to_group("player3d")
	health = max_health
	attack_area.monitoring = false
	attack_area.body_entered.connect(_on_gada_hit)
	health_changed.emit(health, max_health)
	blink_timer = randf_range(2.0, 5.0)
	anim_player.play("Idle")

func _physics_process(delta: float) -> void:
	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_attack(delta)
	_handle_blink(delta)
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
	var moving := false

	if move_dir.length() > 0.01:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * speed
		velocity.z = move_dir.z * speed
		facing_yaw = atan2(move_dir.x, move_dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, facing_yaw, ROTATE_SPEED * delta)
		lean = clampf(lean + delta * 4.0, 0.0, 1.0)
		moving = true
	else:
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
		lean = clampf(lean - delta * 4.0, 0.0, 1.0)

	model.rotation.z = lerp_angle(model.rotation.z, -0.08 * lean, 8.0 * delta)

	if not is_attacking:
		var target_anim := "Walk" if moving else "Idle"
		if anim_player.current_animation != target_anim:
			anim_player.play(target_anim, 0.2)
		anim_player.speed_scale = 1.6 if (moving and Input.is_action_pressed("dash")) else 1.0

func _handle_blink(delta: float) -> void:
	blink_timer -= delta
	if blink_timer <= 0.0:
		blink_timer = randf_range(2.5, 6.0)
		_do_blink()

func _do_blink() -> void:
	var tween := create_tween()
	tween.tween_method(_set_blink_weight, 0.0, 1.0, 0.06)
	tween.tween_method(_set_blink_weight, 1.0, 0.0, 0.08)

func _set_blink_weight(w: float) -> void:
	eye_white_l.set("blend_shapes/Blink", w)
	eye_white_r.set("blend_shapes/Blink", w)

func _handle_attack(delta: float) -> void:
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0 and not is_attacking:
		_do_attack()

func _do_attack() -> void:
	is_attacking = true
	attack_cooldown = ATTACK_COOLDOWN
	anim_player.play("Attack", 0.05)
	await get_tree().create_timer(0.2).timeout
	attack_area.monitoring = true
	await get_tree().create_timer(0.15).timeout
	attack_area.monitoring = false
	await anim_player.animation_finished
	is_attacking = false

func roar() -> void:
	if not is_attacking:
		anim_player.play("Roar", 0.1)
		await anim_player.animation_finished

func _on_gada_hit(body: Node3D) -> void:
	if body.has_method("take_damage_3d"):
		body.take_damage_3d(gada_damage, global_position)

func take_damage_3d(amount: float, source_pos: Vector3) -> void:
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()
