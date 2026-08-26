extends Node

class_name DialogueManager

var current_dialogue: Array = []
var current_index: int = 0
var is_showing: bool = false
var display_callback: Callable

signal dialogue_started
signal dialogue_ended
signal line_shown(text: String)

func setup(display_func: Callable) -> void:
	display_callback = display_func

func show_dialogue(lines: Array) -> void:
	if is_showing:
		return
	current_dialogue = lines
	current_index = 0
	is_showing = true
	dialogue_started.emit()
	_show_next()

func _show_next() -> void:
	if current_index >= current_dialogue.size():
		is_showing = false
		dialogue_ended.emit()
		return

	var line = current_dialogue[current_index]
	current_index += 1

	if display_callback.is_valid():
		display_callback.call(line.text)

	line_shown.emit(line.text)

	await get_tree().create_timer(line.duration).timeout
	_show_next()

class DialogueLine:
	var text: String
	var duration: float = 2.0

	func _init(t: String, d: float = 2.0) -> void:
		text = t
		duration = d
