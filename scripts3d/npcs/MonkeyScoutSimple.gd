extends NPCSimple

class_name MonkeyScoutSimple

enum ExtraState { FORAGING, CURIOUS }

@export var hearing_range: float = 80.0
@export var forage_range: float = 15.0

var rama: Node3D = null
var has_talked: bool = false
var forage_timer: float = 0.0

signal monkey_dialogue(text: String)
signal monkey_joined

func _ready() -> void:
	npc_name = "Monkey Scout"
	add_to_group("npcs")
	target_position = global_position
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.IDLE:
			_idle_state(delta)
		State.MOVING:
			_move_to(target_position, walk_speed)
		State.ALERT:
			_alert_state(delta)
		State.APPROACHING:
			_approach_state(delta)
		State.TALKING:
			_talking_state(delta)

	move_and_slide()

func _idle_state(delta: float) -> void:
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	forage_timer += delta
	if forage_timer > randf_range(3.0, 6.0):
		target_position = global_position + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))
		change_state(State.MOVING)
		forage_timer = 0.0

func _alert_state(delta: float) -> void:
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	if rama and is_instance_valid(rama):
		var distance = global_position.distance_to(rama.global_position)
		if distance < hearing_range and distance > approach_distance:
			change_state(State.APPROACHING)

func _approach_state(delta: float) -> void:
	if not rama or not is_instance_valid(rama):
		change_state(State.IDLE)
		return
	if global_position.distance_to(rama.global_position) < approach_distance:
		change_state(State.TALKING)
		_initiate_talk()
	else:
		_move_to(rama.global_position, run_speed, "run")

func _talking_state(delta: float) -> void:
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)

func detect_call(rama_node: Node3D) -> void:
	if has_talked:
		return
	rama = rama_node
	if current_state not in [State.APPROACHING, State.TALKING]:
		change_state(State.ALERT)

func _initiate_talk() -> void:
	has_talked = true
	monkey_dialogue.emit("Greetings, Rama!")
	await get_tree().create_timer(2.0).timeout
	monkey_joined.emit()
	change_state(State.IDLE)

func set_rama_reference(rama_node: Node3D) -> void:
	rama = rama_node
