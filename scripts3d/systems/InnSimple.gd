extends BaseSystemSimple

class_name InnSimple

@export var rest_cost: float = 50.0
@export var base_healing: float = 100.0

signal rest_started
signal rest_completed(health_recovered: float)

func _ready() -> void:
	set_state("is_resting", false)
	set_state("quality", "comfortable")

func rest(player: Node3D, rest_hours: int = 1) -> bool:
	if get_state("is_resting", false):
		return false
	set_state("is_resting", true)
	rest_started.emit()
	emit_event("rest_started", rest_hours)
	await get_tree().create_timer(rest_hours * 0.5).timeout
	var healing = base_healing * rest_hours
	if player.has_method("heal"):
		player.heal(healing)
	set_state("is_resting", false)
	rest_completed.emit(healing)
	emit_event("rest_completed", healing)
	return true

func get_rest_cost() -> float:
	return rest_cost

func get_inn_text() -> String:
	var healing = base_healing
	if get_state("quality", "comfortable") == "luxurious":
		healing = 150.0
	elif get_state("quality", "comfortable") == "poor":
		healing = 75.0
	return "🏨 Inn\nRest Cost: %.0f gold\nHeal: %.0f HP per hour" % [rest_cost, healing]

func set_rest_quality(quality: String) -> void:
	set_state("quality", quality)
	emit_event("quality_set", quality)
