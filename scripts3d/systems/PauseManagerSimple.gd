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
	set_state("pause_history", [])
	set_state("pause_reasons_count", {})
	set_state("current_pause_start_time", 0)
	set_state("total_pause_time", 0)
	set_state("pause_count", 0)
	set_state("pause_performance", [])
	set_state("pause_session_data", {})

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
	set_state("current_pause_start_time", Time.get_ticks_msec())
	var count = get_state("pause_count", 0) + 1
	set_state("pause_count", count)
	_record_pause_reason(reason)
	get_tree().paused = true
	paused.emit()
	emit_event("paused", reason)

func resume() -> void:
	var start_time = get_state("current_pause_start_time", 0)
	var duration = Time.get_ticks_msec() - start_time
	var total = get_state("total_pause_time", 0) + duration
	set_state("total_pause_time", total)
	_record_pause_history(get_state("pause_reason", ""), duration)
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

func _record_pause_reason(reason: String) -> void:
	var reasons = get_state("pause_reasons_count", {})
	reasons[reason] = reasons.get(reason, 0) + 1
	set_state("pause_reasons_count", reasons)

func _record_pause_history(reason: String, duration_ms: int) -> void:
	var history = get_state("pause_history", [])
	history.append({"reason": reason, "duration": duration_ms, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("pause_history", history)

func get_pause_history() -> Array:
	return get_state("pause_history", [])

func get_pause_reason_count(reason: String) -> int:
	var reasons = get_state("pause_reasons_count", {})
	return reasons.get(reason, 0)

func get_total_pause_time_ms() -> int:
	return get_state("total_pause_time", 0)

func get_pause_session_count() -> int:
	return get_state("pause_count", 0)

func record_pause_performance(duration_ms: int, memory_used: int) -> void:
	var perf = get_state("pause_performance", [])
	perf.append({"duration": duration_ms, "memory": memory_used, "time": Time.get_ticks_msec()})
	if perf.size() > 50:
		perf.pop_front()
	set_state("pause_performance", perf)

func get_average_pause_duration() -> float:
	var history = get_state("pause_history", [])
	if history.size() == 0:
		return 0.0
	var total = 0
	for entry in history:
		total += entry["duration"]
	return float(total) / float(history.size())

func get_most_common_pause_reason() -> String:
	var reasons = get_state("pause_reasons_count", {})
	var max_reason = ""
	var max_count = 0
	for reason in reasons:
		if reasons[reason] > max_count:
			max_count = reasons[reason]
			max_reason = reason
	return max_reason

func get_pause_statistics() -> Dictionary:
	return {
		"total_pauses": get_pause_session_count(),
		"total_pause_time_ms": get_total_pause_time_ms(),
		"average_pause_duration_ms": get_average_pause_duration(),
		"most_common_reason": get_most_common_pause_reason(),
		"unique_reasons": get_state("pause_reasons_count", {}).size(),
		"is_currently_paused": is_paused(),
		"performance_samples": get_state("pause_performance", []).size()
	}
