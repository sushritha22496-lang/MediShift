extends Node3D

class_name SageSimple

@export var sage_name: String = "Sage"
@export var meditation_spot: Vector3 = Vector3.ZERO
@export var interaction_range: float = 10.0

var is_meditating: bool = true
var dialogue_index: int = 0
var has_interacted: bool = false

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer

var wisdoms: Array[String] = [
	"The path to victory is through inner peace",
	"Dharma guides all righteous actions",
	"Patience is the greatest virtue",
	"Knowledge comes from meditation and experience"
]

signal sage_dialogue(text: String)
signal wisdom_shared(wisdom: String)

func _ready() -> void:
	add_to_group("npcs")
	meditation_spot = global_position
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func interact(player: Node3D) -> void:
	var distance = global_position.distance_to(player.global_position)
	if distance > interaction_range:
		return

	has_interacted = true
	var wisdom = wisdoms[dialogue_index % wisdoms.size()]
	sage_dialogue.emit("🧙 %s: %s" % [sage_name, wisdom])
	wisdom_shared.emit(wisdom)
	dialogue_index += 1

	_play_meditation_effect()

func _play_meditation_effect() -> void:
	if anim_player:
		if anim_player.current_animation != "idle":
			anim_player.play("idle")

func get_sage_text() -> String:
	return "🧙 %s\nWisdom: %d/4" % [sage_name, dialogue_index]
