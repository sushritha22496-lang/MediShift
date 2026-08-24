extends BaseSystemSimple

class_name InputHandlerSimple

class InputBinding:
	var action: String
	var primary_key: String
	var secondary_keys: Array[String] = []
	var modifier: int = 0
	var is_enabled: bool = true
	func _init(p_action: String, p_key: String) -> void:
		action = p_action
		primary_key = p_key

signal input_detected(action: String)
signal direction_changed(direction: Vector3)
signal combo_detected(combo: String)
signal input_mode_changed(mode: String)

var input_bindings: Dictionary = {}
var current_input_mode: String = "game"
var input_buffer: Array = []
var input_hold_times: Dictionary = {}
var last_input_time: float = 0.0

func _ready() -> void:
	set_state("last_direction", Vector3.ZERO)
	set_state("input_history", [])
	set_state("input_contexts", {"game": {}, "ui": {}, "cutscene": {}})
	set_state("double_click_time", 0.2)
	set_state("combo_timeout", 0.5)
	set_state("input_latency", 0.0)
	set_state("gamepad_deadzone", 0.2)
	_initialize_bindings()

func _initialize_bindings() -> void:
	var b1 = InputBinding.new("move_forward", "w")
	var b2 = InputBinding.new("move_backward", "s")
	var b3 = InputBinding.new("move_left", "a")
	var b4 = InputBinding.new("move_right", "d")
	var b5 = InputBinding.new("jump", "space")
	var b6 = InputBinding.new("attack", "left_mouse")
	var b7 = InputBinding.new("special", "e")
	var b8 = InputBinding.new("interact", "f")
	var b9 = InputBinding.new("inventory", "i")
	var b10 = InputBinding.new("quests", "q")
	b10.secondary_keys = ["j"]
	var b11 = InputBinding.new("map", "m")
	var b12 = InputBinding.new("pause", "esc")
	var b13 = InputBinding.new("sprint", "shift")
	var b14 = InputBinding.new("dodge", "middle_mouse")
	input_bindings = {
		"move_forward": b1, "move_backward": b2, "move_left": b3, "move_right": b4,
		"jump": b5, "attack": b6, "special": b7, "interact": b8,
		"inventory": b9, "quests": b10, "map": b11, "pause": b12,
		"sprint": b13, "dodge": b14
	}

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var action = _get_action_from_key(event.keycode)
		if action != "":
			_process_input_action(action, event)
	elif event is InputEventMouseButton and event.pressed:
		var action = _get_action_from_mouse_button(event.button_index)
		if action != "":
			_process_input_action(action, event)

func _process_input_action(action: String, event: InputEvent) -> void:
	if current_input_mode == "ui" and action not in ["inventory", "quests", "map", "pause"]:
		return
	last_input_time = Time.get_ticks_msec() / 1000.0
	_add_to_input_buffer(action)
	_check_for_combos()
	input_detected.emit(action)
	_track_input(action)
	emit_event("input_detected", {"action": action, "mode": current_input_mode})

func _add_to_input_buffer(action: String) -> void:
	var combo_timeout = get_state("combo_timeout", 0.5)
	if not input_buffer.is_empty():
		var last_input = input_buffer[-1]
		if (Time.get_ticks_msec() / 1000.0 - last_input["time"]) > combo_timeout:
			input_buffer.clear()
	input_buffer.append({"action": action, "time": Time.get_ticks_msec() / 1000.0})
	if input_buffer.size() > 10:
		input_buffer.pop_front()

func _check_for_combos() -> void:
	if input_buffer.size() >= 2:
		var recent = input_buffer.slice(-2)
		if recent[0]["action"] == "attack" and recent[1]["action"] == "special":
			combo_detected.emit("power_attack")
			_clear_buffer_after_combo()

func _clear_buffer_after_combo() -> void:
	input_buffer.clear()

func _track_input(action: String) -> void:
	var history = get_state("input_history", [])
	history.append({"action": action, "timestamp": Time.get_ticks_msec(), "mode": current_input_mode})
	if history.size() > 200:
		history.pop_front()
	set_state("input_history", history)

func _get_action_from_mouse_button(button_index: int) -> String:
	var button_map = {MouseButton.LEFT: "attack", MouseButton.MIDDLE: "dodge", MouseButton.RIGHT: "interact"}
	return button_map.get(button_index, "")

func get_movement_direction() -> Vector3:
	var direction = Vector3.ZERO
	if Input.is_action_pressed("ui_up") or is_action_pressed("move_forward"):
		direction.z -= 1
	if Input.is_action_pressed("ui_down") or is_action_pressed("move_backward"):
		direction.z += 1
	if Input.is_action_pressed("ui_left") or is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right") or is_action_pressed("move_right"):
		direction.x += 1
	direction = direction.normalized()
	if direction != get_state("last_direction", Vector3.ZERO):
		set_state("last_direction", direction)
		direction_changed.emit(direction)
	return direction

func is_action_pressed(action: String) -> bool:
	if action not in input_bindings:
		return Input.is_action_pressed(action)
	var binding = input_bindings[action]
	return Input.is_key_pressed(OS.find_keycode_from_string(binding.primary_key))

func is_action_just_pressed(action: String) -> bool:
	return Input.is_action_just_pressed(action)

func set_input_mode(mode: String) -> void:
	if mode in ["game", "ui", "cutscene"]:
		current_input_mode = mode
		input_buffer.clear()
		input_mode_changed.emit(mode)
		emit_event("input_mode_changed", mode)

func get_input_mode() -> String:
	return current_input_mode

func rebind_action(action: String, key: String) -> void:
	if action in input_bindings:
		input_bindings[action].primary_key = key
		emit_event("action_rebound", {"action": action, "key": key})

func get_binding(action: String) -> String:
	if action in input_bindings:
		return input_bindings[action].primary_key
	return ""

func get_input_buffer() -> Array:
	return input_buffer.duplicate()

func get_input_history() -> Array:
	return get_state("input_history", [])

func get_last_input_time() -> float:
	return last_input_time

func _get_action_from_key(keycode: int) -> String:
	for action in input_bindings.keys():
		var binding = input_bindings[action]
		if binding.primary_key == str(keycode) or str(keycode) in binding.secondary_keys:
			return action
	return ""

func get_input_text() -> String:
	return "Input: %s | Buffer: %d | History: %d" % [current_input_mode.capitalize(), input_buffer.size(), get_state("input_history", []).size()]
