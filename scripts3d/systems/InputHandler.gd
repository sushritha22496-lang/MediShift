extends Node

class_name InputHandler

signal movement_input(direction: Vector2)
signal action_performed(action: String)
signal interact_pressed
signal pause_toggled

var enabled: bool = true
var paused: bool = false

func _input(event: InputEvent) -> void:
	if not enabled:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			pause_toggled.emit()
			paused = not paused
			get_tree().paused = paused

func _process(_delta: float) -> void:
	if not enabled or paused:
		return

	var move_dir = Vector2.ZERO
	move_dir.x = Input.get_axis("move_left", "move_right")
	move_dir.y = Input.get_axis("move_up", "move_down")

	if move_dir.length() > 0.01:
		movement_input.emit(move_dir.normalized())

	if Input.is_action_just_pressed("interact"):
		interact_pressed.emit()
		action_performed.emit("interact")

	if Input.is_action_just_pressed("call_sita"):
		action_performed.emit("call")

	if Input.is_action_just_pressed("dash"):
		action_performed.emit("dash")

func set_enabled(e: bool) -> void:
	enabled = e

func set_paused(p: bool) -> void:
	paused = p
	get_tree().paused = p
