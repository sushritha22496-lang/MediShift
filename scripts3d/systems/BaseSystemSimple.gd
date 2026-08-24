extends Node
class_name BaseSystemSimple

signal event_triggered(name: String, data: Variant)

var _state: Dictionary = {}
var _callbacks: Dictionary = {}

func set_state(key: String, value: Variant) -> void:
	_state[key] = value

func get_state(key: String, default: Variant = null) -> Variant:
	return _state.get(key, default)

func on(event: String, callback: Callable) -> void:
	if not event in _callbacks:
		_callbacks[event] = []
	_callbacks[event].append(callback)

func emit_event(name: String, data: Variant = null) -> void:
	event_triggered.emit(name, data)
	if name in _callbacks:
		for cb in _callbacks[name]:
			cb.call(data)

func to_text(prefix: String = "") -> String:
	return "%s\n" % prefix
