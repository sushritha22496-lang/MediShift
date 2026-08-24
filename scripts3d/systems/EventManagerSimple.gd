extends BaseSystemSimple

class_name EventManagerSimple

var event_listeners: Dictionary = {}

signal event_triggered(event_name: String, data)
signal listener_registered(event_name: String)
signal listener_unregistered(event_name: String)

func _ready() -> void:
	set_state("event_history", [])

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
	event_triggered.emit(event_name, data)
	emit_event("event_triggered", event_name)
	
	if event_name in event_listeners:
		for callback in event_listeners[event_name]:
			callback.call(data)
	
	var history = get_state("event_history", [])
	history.append({
		"event": event_name,
		"timestamp": Time.get_ticks_msec(),
		"data": data
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
