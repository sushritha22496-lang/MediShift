extends Node

class_name EventBus

static var instance: EventBus
static var events: Dictionary = {}

func _ready() -> void:
	if instance == null:
		instance = self
		add_to_group("event_bus")

static func emit_event(event_name: String, data: Dictionary = {}) -> void:
	if instance:
		instance._do_emit(event_name, data)

static func connect_event(event_name: String, callback: Callable) -> void:
	if not events.has(event_name):
		events[event_name] = []
	events[event_name].append(callback)

func _do_emit(event_name: String, data: Dictionary) -> void:
	if events.has(event_name):
		for callback in events[event_name]:
			if callback.is_valid():
				callback.call(data)

static func clear_event(event_name: String) -> void:
	if events.has(event_name):
		events.erase(event_name)
