extends NPCSimple

class_name SageSimple

@export var interaction_range: float = 10.0

var dialogue_index: int = 0
var wisdoms: Array[String] = [
	"The path to victory is through inner peace",
	"Dharma guides all righteous actions",
	"Patience is the greatest virtue",
	"Knowledge comes from meditation and experience"
]

signal wisdom_shared(wisdom: String)

func _ready() -> void:
	npc_name = "Sage"
	add_to_group("npcs")
	approach_distance = interaction_range
	walk_speed = 0.0
	run_speed = 0.0
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	move_and_slide()

func interact(player: Node3D) -> void:
	var distance = global_position.distance_to(player.global_position)
	if distance > interaction_range:
		return
	var wisdom = wisdoms[dialogue_index % wisdoms.size()]
	dialogue.emit("🧙 %s: %s" % [npc_name, wisdom])
	wisdom_shared.emit(wisdom)
	dialogue_index += 1

func get_sage_text() -> String:
	return "🧙 %s\nWisdom: %d/4" % [npc_name, dialogue_index]
