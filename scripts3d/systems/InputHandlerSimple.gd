extends BaseSystemSimple

class_name InputHandlerSimple

signal input_detected(action: String)
signal direction_changed(direction: Vector3)

var input_bindings: Dictionary = {}

func _ready() -> void:
	set_state("last_direction", Vector3.ZERO)
	_initialize_bindings()

func _initialize_bindings() -> void:
	input_bindings = {
		"move_forward": "w",
		"move_backward": "s",
		"move_left": "a",
		"move_right": "d",
		"jump": "space",
		"attack": "left_mouse",
		"special": "e",
		"interact": "f",
		"inventory": "i",
		"quests": "q",
		"map": "m",
		"pause": "esc",
		"sprint": "shift",
		"dodge": "middle_mouse"
	}

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var action = _get_action_from_key(event.keycode)
		if action != "":
			input_detected.emit(action)
			emit_event("input_detected", action)

func get_movement_direction() -> Vector3:
	var direction = Vector3.ZERO
	if Input.is_action_pressed("ui_up"):
		direction.z -= 1
	if Input.is_action_pressed("ui_down"):
		direction.z += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	
	direction = direction.normalized()
	if direction != get_state("last_direction", Vector3.ZERO):
		set_state("last_direction", direction)
		direction_changed.emit(direction)
	return direction

func is_action_pressed(action: String) -> bool:
	return Input.is_action_pressed(action)

func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)

func rebind_action(action: String, key: String) -> void:
	input_bindings[action] = key
	emit_event("action_rebound", action)

func get_binding(action: String) -> String:
	return input_bindings.get(action, "")

func get_input_text() -> String:
	return "Input System Ready\nBindings: %d" % input_bindings.size()

func _get_action_from_key(keycode: int) -> String:
	for action in input_bindings.keys():
		if input_bindings[action] == str(keycode):
			return action
	return ""
