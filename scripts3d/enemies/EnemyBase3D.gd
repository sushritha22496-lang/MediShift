extends CharacterBody3D
class_name EnemyBase3D

const GRAVITY := 22.0

@export var enemy_name: String = "Demon"
@export var max_health: float = 100.0
@export var move_speed: float = 3.5
@export var attack_damage: float = 15.0
@export var attack_range: float = 2.2
@export var detect_range: float = 12.0
@export var score_value: int = 100

var health: float
var is_dead: bool = false
var player: Node3D = null
var attack_cooldown: float = 0.0

@onready var model: Node3D = $Model
@onready var attack_area: Area3D = $Model/AttackArea

signal died(enemy: EnemyBase3D)
signal health_changed(current: float, maximum: float)

func _ready() -> void:
	health = max_health
	add_to_group("enemies3d")
	if attack_area:
		attack_area.monitoring = false
		attack_area.body_entered.connect(_on_attack_landed)
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	_find_player()
	_chase_and_attack(delta)
	move_and_slide()

func _find_player() -> void:
	if player and is_instance_valid(player):
		return
	var candidates := get_tree().get_nodes_in_group("player3d")
	if candidates.size() > 0:
		player = candidates[0]

func _chase_and_attack(delta: float) -> void:
	if not player:
		return
	var dist: float = global_position.distance_to(player.global_position)
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if dist > detect_range:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if dist <= attack_range:
		velocity.x = 0.0
		velocity.z = 0.0
		if attack_cooldown <= 0.0:
			_do_attack()
		return
	var dir: Vector3 = (player.global_position - global_position)
	dir.y = 0.0
	dir = dir.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	model.rotation.y = atan2(dir.x, dir.z)

func _do_attack() -> void:
	attack_cooldown = 1.5
	attack_area.monitoring = true
	await get_tree().create_timer(0.3).timeout
	if attack_area:
		attack_area.monitoring = false

func _on_attack_landed(body: Node3D) -> void:
	if body.has_method("take_damage_3d"):
		body.take_damage_3d(attack_damage, global_position)

func take_damage_3d(amount: float, source_pos: Vector3) -> void:
	if is_dead:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	var dir: Vector3 = (global_position - source_pos)
	dir.y = 0.0
	if dir.length() > 0.01:
		velocity += dir.normalized() * 4.0
	if health <= 0.0:
		_die()

func _die() -> void:
	is_dead = true
	set_physics_process(false)
	died.emit(self)
	var tween := create_tween()
	tween.tween_property(model, "scale", Vector3.ZERO, 0.4)
	tween.tween_callback(queue_free)
