extends Node3D

class_name InnSimple

@export var inn_location: Vector3 = Vector3.ZERO
@export var rest_cost: float = 50.0
@export var healing_amount: float = 100.0

var is_resting: bool = false
var rest_quality: String = "comfortable"

signal rest_started
signal rest_completed(health_recovered: float)

func _ready() -> void:
	inn_location = global_position

func rest(player: Node3D, rest_hours: int = 1) -> bool:
	if is_resting:
		return false

	is_resting = true
	rest_started.emit()
	print("😴 Resting at inn for %d hours..." % rest_hours)

	var rest_duration = rest_hours * 0.5
	await get_tree().create_timer(rest_duration).timeout

	var healing = healing_amount * rest_hours
	if player.has_method("heal"):
		player.heal(healing)

	is_resting = false
	rest_completed.emit(healing)
	print("✓ Well rested! Recovered %.0f HP" % healing)
	return true

func get_rest_cost() -> float:
	return rest_cost

func get_inn_text() -> String:
	return "🏨 Inn\nRest Cost: %.0f gold\nHeal: %.0f HP per hour" % [rest_cost, healing_amount]

func set_rest_quality(quality: String) -> void:
	rest_quality = quality
	if quality == "luxurious":
		healing_amount = 150.0
	elif quality == "standard":
		healing_amount = 100.0
	else:
		healing_amount = 75.0
