extends NPCSimple

class_name HanumanAISimple

@export var hearing_range: float = 100.0
@export var curiosity_threshold: float = 0.7
@export var follow_distance: float = 8.0

var rama: Node3D = null
var has_met_rama: bool = false
var forage_timer: float = 0.0

signal rama_detected
signal meeting_initiated
signal agreement_reached

func _ready() -> void:
	npc_name = "Hanuman"
	add_to_group("npcs")
	target_position = global_position
	if anim_player:
		_load_animations()
		if anim_player.has_animation("idle"):
			anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.IDLE:
			_idle_state(delta)
		State.MOVING:
			_forage_state(delta)
		State.ALERT:
			_curious_state(delta)
		State.APPROACHING:
			_approach_state(delta)
		State.TALKING:
			_follow_state(delta)

	move_and_slide()

func _idle_state(delta: float) -> void:
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	forage_timer += delta
	if forage_timer > randf_range(3.0, 6.0):
		target_position = global_position + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
		change_state(State.MOVING)
		forage_timer = 0.0

func _forage_state(delta: float) -> void:
	if global_position.distance_to(target_position) < 2.0:
		change_state(State.IDLE)
	else:
		_move_to(target_position, walk_speed, "walk")

func _curious_state(delta: float) -> void:
	_play_anim("idle")
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
	if rama and is_instance_valid(rama):
		var distance = global_position.distance_to(rama.global_position)
		if distance < hearing_range and distance > approach_distance:
			change_state(State.APPROACHING)
			rama_detected.emit()

func _approach_state(delta: float) -> void:
	if not rama or not is_instance_valid(rama):
		change_state(State.IDLE)
		return
	var distance = global_position.distance_to(rama.global_position)
	if distance < approach_distance:
		change_state(State.TALKING)
		meeting_initiated.emit()
		_initiate_meeting()
	else:
		_move_to(rama.global_position, run_speed, "run")

func _follow_state(delta: float) -> void:
	if not rama or not is_instance_valid(rama):
		change_state(State.IDLE)
		return
	var distance = global_position.distance_to(rama.global_position)
	if distance > follow_distance:
		_move_to(rama.global_position, walk_speed, "walk")
	else:
		_play_anim("idle")
		velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

func detect_rama_call(rama_node: Node3D, call_intensity: float) -> void:
	if has_met_rama:
		return
	rama = rama_node
	var distance = global_position.distance_to(rama.global_position)
	if distance < hearing_range and call_intensity >= curiosity_threshold:
		if current_state not in [State.APPROACHING, State.TALKING]:
			change_state(State.ALERT)

func _initiate_meeting() -> void:
	has_met_rama = true
	await get_tree().create_timer(2.0).timeout
	agreement_reached.emit()
	change_state(State.TALKING)

func _load_animations() -> void:
	var animations_to_load = ["idle", "walk", "run", "attack"]
	for anim_name in animations_to_load:
		if anim_player.has_animation(anim_name):
			continue
		var anim_path = "res://assets/animations/hanuman/%s.tres" % anim_name
		if ResourceLoader.exists(anim_path):
			var anim = load(anim_path)
			anim_player.add_animation(anim_name, anim)

func set_rama_reference(rama_node: Node3D) -> void:
	rama = rama_node
