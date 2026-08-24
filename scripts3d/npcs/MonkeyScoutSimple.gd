extends CharacterBody3D

class_name MonkeyScoutSimple

enum State { IDLE, FORAGING, CURIOUS, APPROACHING, TALKING }

@export var walk_speed: float = 3.5
@export var run_speed: float = 6.0
@export var gravity: float = 22.0
@export var rotate_speed: float = 10.0
@export var hearing_range: float = 80.0
@export var approach_distance: float = 4.0

var current_state: State = State.IDLE
var rama: Node3D = null
var target_position: Vector3 = Vector3.ZERO
var dialogue_text: String = "Greetings, Rama!"
var has_talked: bool = false

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

signal monkey_dialogue(text: String)
signal monkey_joined

func _ready() -> void:
	add_to_group("npcs")
	current_state = State.IDLE
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
			_idle_behavior(delta)
		State.FORAGING:
			_foraging_behavior(delta)
		State.CURIOUS:
			_curious_behavior(delta)
		State.APPROACHING:
			_approaching_behavior(delta)
		State.TALKING:
			_talking_behavior(delta)

	move_and_slide()

func _idle_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

	if randf() < 0.0015:
		current_state = State.FORAGING

func _foraging_behavior(delta: float) -> void:
	if global_position.distance_to(target_position) < 2.0:
		target_position = global_position + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15))

	var direction = (target_position - global_position).normalized()
	direction.y = 0.0

	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		if anim_player and anim_player.current_animation != "walk":
			anim_player.play("walk")

func _curious_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

	if rama:
		var distance = global_position.distance_to(rama.global_position)
		if distance < hearing_range and distance > approach_distance:
			current_state = State.APPROACHING

func _approaching_behavior(delta: float) -> void:
	if not rama:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(rama.global_position)

	if distance < approach_distance:
		current_state = State.TALKING
		_initiate_talk()
		return

	var direction = (rama.global_position - global_position).normalized()
	direction.y = 0.0

	velocity.x = direction.x * run_speed
	velocity.z = direction.z * run_speed

	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		if anim_player and anim_player.current_animation != "run":
			anim_player.play("run")

func _talking_behavior(delta: float) -> void:
	velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)

	if anim_player and anim_player.current_animation != "idle":
		anim_player.play("idle")

func detect_call(rama_node: Node3D) -> void:
	if has_talked:
		return
	rama = rama_node
	if current_state != State.APPROACHING and current_state != State.TALKING:
		current_state = State.CURIOUS

func _initiate_talk() -> void:
	has_talked = true
	monkey_dialogue.emit(dialogue_text)
	await get_tree().create_timer(2.0).timeout
	monkey_joined.emit()
	current_state = State.IDLE

func _load_animations() -> void:
	var animations_to_load = ["idle", "walk", "run"]
	for anim_name in animations_to_load:
		if anim_player.has_animation(anim_name):
			continue
		var anim_path = "res://assets/animations/monkey/%s.tres" % anim_name
		if ResourceLoader.exists(anim_path):
			var anim = load(anim_path)
			anim_player.add_animation(anim_name, anim)

func set_rama_reference(rama_node: Node3D) -> void:
	rama = rama_node

func get_character_name() -> String:
	return "Monkey Scout"
