extends CharacterBody3D
class_name NPCSimple

@export var npc_name: String = "NPC"
@export var walk_speed: float = 3.5
@export var run_speed: float = 6.0
@export var gravity: float = 22.0
@export var detection_range: float = 30.0
@export var approach_distance: float = 5.0

enum State { IDLE, MOVING, ALERT, APPROACHING, TALKING }

var current_state: State = State.IDLE
var target: Node3D = null
var target_position: Vector3 = Vector3.ZERO
var dialogue: String = ""

@onready var model: Node3D = $Model
@onready var anim_player: AnimationPlayer = $Model/AnimationPlayer

signal dialogue(text: String)
signal state_changed(new_state: State)

func _ready() -> void:
	add_to_group("npcs")
	target_position = global_position
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	match current_state:
		State.IDLE:
			_play_anim("idle")
			velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
		State.MOVING:
			_move_to(target_position, walk_speed)
		State.APPROACHING:
			if target and is_instance_valid(target):
				if global_position.distance_to(target.global_position) < approach_distance:
					change_state(State.TALKING)
					_initiate_dialogue()
				else:
					_move_to(target.global_position, run_speed, "run")
		State.ALERT:
			_play_anim("idle")
			velocity.x = lerp(velocity.x, 0.0, 5.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 5.0 * delta)
		State.TALKING:
			_play_anim("idle")
			velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
			velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)

	move_and_slide()

func _move_to(pos: Vector3, speed: float, anim: String = "walk") -> void:
	var direction = (pos - global_position).normalized()
	direction.y = 0.0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if direction.length() > 0.1:
		model.rotation.y = atan2(direction.x, direction.z)
		_play_anim(anim)

func _play_anim(name: String) -> void:
	if anim_player and anim_player.current_animation != name:
		anim_player.play(name)

func change_state(new_state: State) -> void:
	if current_state != new_state:
		current_state = new_state
		state_changed.emit(new_state)

func approach(player: Node3D) -> void:
	target = player
	change_state(State.APPROACHING)

func _initiate_dialogue() -> void:
	dialogue.emit(dialogue)
	await get_tree().create_timer(2.0).timeout
	change_state(State.IDLE)

func say(text: String) -> void:
	dialogue = text
	change_state(State.TALKING)
	dialogue.emit(text)

func set_target_position(pos: Vector3) -> void:
	target_position = pos
	change_state(State.MOVING)
