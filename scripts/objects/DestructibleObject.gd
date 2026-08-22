extends StaticBody2D
class_name DestructibleObject

@export var max_health: float = 20.0
@export var score_value: int = 50

var health: float

signal destroyed()

func _ready() -> void:
	health = max_health
	add_to_group("destructible")

func take_damage(amount: float, _source_pos: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	if health <= 0.0:
		_destroy()

func _destroy() -> void:
	GameManager.add_score(score_value)
	AudioManager.play_sfx("enemy_hit")
	destroyed.emit()
	queue_free()
