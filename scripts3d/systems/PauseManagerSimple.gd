extends BaseSystemSimple

class_name PauseManagerSimple

signal paused
signal resumed
signal pause_menu_opened
signal pause_menu_closed

func _ready() -> void:
	set_state("is_paused", false)
	set_state("pause_menu_open", false)
	set_state("pause_reason", "")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_tree().root.set_input_as_handled()

func toggle_pause() -> void:
	if is_paused():
		resume()
	else:
		pause()

func pause(reason: String = "menu") -> void:
	set_state("is_paused", true)
	set_state("pause_reason", reason)
	get_tree().paused = true
	paused.emit()
	emit_event("paused", reason)

func resume() -> void:
	set_state("is_paused", false)
	set_state("pause_reason", "")
	get_tree().paused = false
	resumed.emit()
	emit_event("resumed", "")

func is_paused() -> bool:
	return get_state("is_paused", false)

func get_pause_reason() -> String:
	return get_state("pause_reason", "")

func open_pause_menu() -> void:
	set_state("pause_menu_open", true)
	pause("menu")
	pause_menu_opened.emit()
	emit_event("pause_menu_opened", "")

func close_pause_menu() -> void:
	set_state("pause_menu_open", false)
	resume()
	pause_menu_closed.emit()
	emit_event("pause_menu_closed", "")

func is_pause_menu_open() -> bool:
	return get_state("pause_menu_open", false)

func get_pause_text() -> String:
	if is_paused():
		var reason = get_pause_reason()
		return "PAUSED - %s\nPress ESC to resume" % reason.capitalize()
	return "Running"
