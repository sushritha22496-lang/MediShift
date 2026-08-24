extends Node3D

class_name CombatSimple

@export var attack_range: float = 3.0
@export var attack_cooldown: float = 1.0
@export var attack_damage: float = 10.0

var can_attack: bool = true
var attack_cooldown_timer: float = 0.0

signal attack_performed(target: Node3D, damage: float)

func _physics_process(delta: float) -> void:
	if not can_attack:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0.0:
			can_attack = true

func perform_attack(attacker: Node3D, target: Node3D) -> bool:
	if not can_attack:
		return false

	var distance = attacker.global_position.distance_to(target.global_position)
	if distance > attack_range:
		return false

	can_attack = false
	attack_cooldown_timer = attack_cooldown
	attack_performed.emit(target, attack_damage)
	return true

func reset_cooldown() -> void:
	can_attack = true
	attack_cooldown_timer = 0.0

func get_cooldown_remaining() -> float:
	return attack_cooldown_timer if not can_attack else 0.0
