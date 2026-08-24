extends BaseSystemSimple

class_name AnalyticsSimple

signal event_logged(event_name: String)
signal session_started
signal session_ended

func _ready() -> void:
	set_state("session_start", Time.get_ticks_msec())
	set_state("events", [])
	set_state("session_count", 0)
	session_started.emit()
	emit_event("session_started", "")

func log_event(event_name: String, event_data: Dictionary = {}) -> void:
	var events = get_state("events", [])
	events.append({
		"name": event_name,
		"data": event_data,
		"timestamp": Time.get_ticks_msec()
	})
	if events.size() > 1000:
		events.pop_front()
	set_state("events", events)
	event_logged.emit(event_name)
	emit_event("event_logged", event_name)

func end_session() -> float:
	var start = get_state("session_start", 0.0)
	var duration = (Time.get_ticks_msec() - start) / 1000.0
	var count = get_state("session_count", 0)
	count += 1
	set_state("session_count", count)
	session_ended.emit()
	emit_event("session_ended", "")
	return duration

func get_session_duration() -> float:
	var start = get_state("session_start", 0.0)
	return (Time.get_ticks_msec() - start) / 1000.0

func get_event_count() -> int:
	return get_state("events", []).size()

func get_events() -> Array:
	return get_state("events", [])

func get_events_by_name(event_name: String) -> Array:
	var all_events = get_events()
	return all_events.filter(func(e): return e["name"] == event_name)

func get_analytics_text() -> String:
	var text = "Analytics\n"
	text += "Session Duration: %.1fs\n" % get_session_duration()
	text += "Total Events: %d\n" % get_event_count()
	text += "Sessions: %d\n" % get_state("session_count", 0)
	return text
