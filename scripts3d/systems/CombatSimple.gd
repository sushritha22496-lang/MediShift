extends BaseSystemSimple

class_name CombatSimple

@export var attack_range: float = 3.0
@export var attack_cooldown: float = 1.0
@export var attack_damage: float = 10.0

signal attack_performed(target: Node3D, damage: float)

func _ready() -> void:
	set_state("can_attack", true)
	set_state("cooldown_timer", 0.0)

func _physics_process(delta: float) -> void:
	if not get_state("can_attack", true):
		var timer = get_state("cooldown_timer", 0.0) - delta
		set_state("cooldown_timer", timer)
		if timer <= 0.0:
			set_state("can_attack", true)

func perform_attack(attacker: Node3D, target: Node3D) -> bool:
	if not get_state("can_attack", true):
		return false
	var distance = attacker.global_position.distance_to(target.global_position)
	if distance > attack_range:
		return false
	set_state("can_attack", false)
	set_state("cooldown_timer", attack_cooldown)
	attack_performed.emit(target, attack_damage)
	emit_event("attack", {"target": target, "damage": attack_damage})
	return true

func reset_cooldown() -> void:
	set_state("can_attack", true)
	set_state("cooldown_timer", 0.0)

func get_cooldown_remaining() -> float:
	return get_state("cooldown_timer", 0.0) if not get_state("can_attack", true) else 0.0
