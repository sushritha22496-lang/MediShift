extends BaseSystemSimple

class_name AnalyticsSimple

class AnalyticsEvent:
	var name: String
	var category: String
	var data: Dictionary
	var timestamp: float
	var session_id: String
	var value: float = 0.0
	var duration: float = 0.0
	func _init(p_name: String, p_category: String = "general", p_data: Dictionary = {}) -> void:
		name = p_name
		category = p_category
		data = p_data
		timestamp = Time.get_ticks_msec()
		session_id = ""

signal event_logged(event_name: String)
signal session_started
signal session_ended(duration: float)
signal crash_recorded(error: String)

var session_id: String = ""
var max_event_buffer: int = 5000

func _ready() -> void:
	session_id = "session_%d" % randi()
	set_state("session_start", Time.get_ticks_msec())
	set_state("events", [])
	set_state("session_count", 0)
	set_state("event_categories", {})
	set_state("crashes", [])
	set_state("performance_metrics", {})
	set_state("location_visits", {})
	set_state("action_sequence", [])
	session_started.emit()
	emit_event("session_started", session_id)

func log_event(event_name: String, event_data: Dictionary = {}, category: String = "general", value: float = 0.0) -> void:
	var event = AnalyticsEvent.new(event_name, category, event_data)
	event.value = value
	event.session_id = session_id
	var events = get_state("events", [])
	events.append({"name": event_name, "category": category, "data": event_data, "timestamp": event.timestamp, "value": value})
	if events.size() > max_event_buffer:
		events.pop_front()
	set_state("events", events)
	_track_event_category(category)
	_track_action_sequence(event_name)
	event_logged.emit(event_name)
	emit_event("event_logged", {"name": event_name, "category": category})

func log_location_visit(location: String) -> void:
	var visits = get_state("location_visits", {})
	visits[location] = visits.get(location, 0) + 1
	set_state("location_visits", visits)
	log_event("location_visit", {"location": location}, "navigation")

func log_performance(metric: String, value: float) -> void:
	var perf = get_state("performance_metrics", {})
	if not metric in perf:
		perf[metric] = []
	perf[metric].append({"value": value, "timestamp": Time.get_ticks_msec()})
	if perf[metric].size() > 100:
		perf[metric].pop_front()
	set_state("performance_metrics", perf)
	log_event("performance_metric", {"metric": metric, "value": value}, "performance", value)

func record_crash(error_message: String) -> void:
	var crashes = get_state("crashes", [])
	crashes.append({"error": error_message, "timestamp": Time.get_ticks_msec(), "session": session_id})
	if crashes.size() > 50:
		crashes.pop_front()
	set_state("crashes", crashes)
	crash_recorded.emit(error_message)
	emit_event("crash_recorded", error_message)

func _track_event_category(category: String) -> void:
	var categories = get_state("event_categories", {})
	categories[category] = categories.get(category, 0) + 1
	set_state("event_categories", categories)

func _track_action_sequence(action: String) -> void:
	var sequence = get_state("action_sequence", [])
	sequence.append({"action": action, "timestamp": Time.get_ticks_msec()})
	if sequence.size() > 100:
		sequence.pop_front()
	set_state("action_sequence", sequence)

func end_session() -> float:
	var start = get_state("session_start", 0.0)
	var duration = (Time.get_ticks_msec() - start) / 1000.0
	var count = get_state("session_count", 0)
	count += 1
	set_state("session_count", count)
	session_ended.emit(duration)
	emit_event("session_ended", {"duration": duration, "session_id": session_id})
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

func get_event_categories() -> Dictionary:
	return get_state("event_categories", {})

func get_location_visits() -> Dictionary:
	return get_state("location_visits", {})

func get_crashes() -> Array:
	return get_state("crashes", [])

func get_most_visited_location() -> String:
	var visits = get_location_visits()
	var max_location = ""
	var max_visits = 0
	for location in visits.keys():
		if visits[location] > max_visits:
			max_visits = visits[location]
			max_location = location
	return max_location

func get_top_events(count: int = 5) -> Array:
	var categories = get_event_categories()
	var sorted_cats = []
	for cat in categories.keys():
		sorted_cats.append({"category": cat, "count": categories[cat]})
	sorted_cats.sort_custom(func(a, b): return a["count"] > b["count"])
	return sorted_cats.slice(0, count)

func get_analytics_text() -> String:
	var text = "Analytics [%s]\n" % session_id.left(12)
	text += "Duration: %.0fs | Events: %d | Sessions: %d\n" % [get_session_duration(), get_event_count(), get_state("session_count", 0)]
	var top_cats = get_top_events(3)
	for cat in top_cats:
		text += "%s: %d  " % [cat["category"].left(4), cat["count"]]
	return text
