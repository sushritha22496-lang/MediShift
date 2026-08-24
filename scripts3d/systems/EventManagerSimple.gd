extends BaseSystemSimple

class_name EventManagerSimple

var event_listeners: Dictionary = {}

signal event_triggered(event_name: String, data)
signal listener_registered(event_name: String)
signal listener_unregistered(event_name: String)

func _ready() -> void:
	set_state("event_history", [])
	set_state("event_performance", [])
	set_state("listener_efficiency", {})
	set_state("event_frequency", {})
	set_state("event_dependency_map", {})
	set_state("priority_events", [])
	set_state("event_statistics", {})

func register_listener(event_name: String, callback: Callable) -> void:
	if event_name not in event_listeners:
		event_listeners[event_name] = []
	event_listeners[event_name].append(callback)
	listener_registered.emit(event_name)
	emit_event("listener_registered", event_name)

func unregister_listener(event_name: String, callback: Callable) -> void:
	if event_name in event_listeners:
		event_listeners[event_name].erase(callback)
		listener_unregistered.emit(event_name)
		emit_event("listener_unregistered", event_name)

func trigger_event(event_name: String, data = null) -> void:
	var start_time = Time.get_ticks_msec()
	event_triggered.emit(event_name, data)
	emit_event("event_triggered", event_name)

	var listener_count = 0
	if event_name in event_listeners:
		listener_count = event_listeners[event_name].size()
		for callback in event_listeners[event_name]:
			callback.call(data)

	var execution_time = Time.get_ticks_msec() - start_time
	_record_event_performance(event_name, execution_time, listener_count)
	_update_event_frequency(event_name)

	var history = get_state("event_history", [])
	history.append({
		"event": event_name,
		"timestamp": Time.get_ticks_msec(),
		"data": data,
		"execution_time": execution_time
	})
	if history.size() > 100:
		history.pop_front()
	set_state("event_history", history)

func get_event_history() -> Array:
	return get_state("event_history", [])

func clear_event_history() -> void:
	set_state("event_history", [])
	emit_event("history_cleared", "")

func get_listener_count(event_name: String) -> int:
	return event_listeners.get(event_name, []).size()

func get_all_events() -> Array:
	return event_listeners.keys()

func get_event_text() -> String:
	var text = "Event System\nRegistered Events: %d\n" % event_listeners.size()
	for event in event_listeners.keys():
		text += "[%s] - %d listeners\n" % [event, get_listener_count(event)]
	return text

func _record_event_performance(event_name: String, execution_time_ms: int, listener_count: int) -> void:
	var perf = get_state("event_performance", [])
	perf.append({"event": event_name, "time": execution_time_ms, "listeners": listener_count, "timestamp": Time.get_ticks_msec()})
	if perf.size() > 100:
		perf.pop_front()
	set_state("event_performance", perf)

func _update_event_frequency(event_name: String) -> void:
	var frequency = get_state("event_frequency", {})
	frequency[event_name] = frequency.get(event_name, 0) + 1
	set_state("event_frequency", frequency)

func _update_listener_efficiency(event_name: String, execution_time_ms: int) -> void:
	var efficiency = get_state("listener_efficiency", {})
	if event_name not in efficiency:
		efficiency[event_name] = {"total_time": 0, "executions": 0}
	efficiency[event_name]["total_time"] += execution_time_ms
	efficiency[event_name]["executions"] += 1
	set_state("listener_efficiency", efficiency)

func get_event_frequency(event_name: String) -> int:
	var frequency = get_state("event_frequency", {})
	return frequency.get(event_name, 0)

func get_most_triggered_event() -> String:
	var frequency = get_state("event_frequency", {})
	var max_event = ""
	var max_count = 0
	for event in frequency:
		if frequency[event] > max_count:
			max_count = frequency[event]
			max_event = event
	return max_event

func set_event_dependency(event_a: String, event_b: String) -> void:
	var deps = get_state("event_dependency_map", {})
	if event_a not in deps:
		deps[event_a] = []
	deps[event_a].append(event_b)
	set_state("event_dependency_map", deps)

func get_event_dependencies(event_name: String) -> Array:
	var deps = get_state("event_dependency_map", {})
	return deps.get(event_name, [])

func set_priority_event(event_name: String, priority: int) -> void:
	var priorities = get_state("priority_events", [])
	var found = false
	for entry in priorities:
		if entry["event"] == event_name:
			entry["priority"] = priority
			found = true
			break
	if not found:
		priorities.append({"event": event_name, "priority": priority})
	set_state("priority_events", priorities)

func get_event_performance_average(event_name: String) -> float:
	var perf = get_state("event_performance", [])
	var total_time = 0
	var count = 0
	for entry in perf:
		if entry["event"] == event_name:
			total_time += entry["time"]
			count += 1
	return float(total_time) / float(count) if count > 0 else 0.0

func update_event_statistics() -> void:
	var stats = get_state("event_statistics", {})
	stats["total_events_triggered"] = get_state("event_history", []).size()
	stats["registered_events"] = event_listeners.size()
	stats["most_triggered"] = get_most_triggered_event()
	set_state("event_statistics", stats)

func get_event_statistics() -> Dictionary:
	update_event_statistics()
	return get_state("event_statistics", {})
