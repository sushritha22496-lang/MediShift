extends Node3D

class_name DayNightSimple

@export var cycle_duration: float = 120.0
@export var sun_light: DirectionalLight3D = null

var current_time: float = 0.0
var time_of_day: String = "day"

signal time_changed(hour: int, minute: int)
signal day_changed
signal night_changed

func _ready() -> void:
	if sun_light == null:
		sun_light = get_node_or_null("../DirectionalLight3D")
	current_time = 0.0

func _process(delta: float) -> void:
	current_time += delta
	if current_time >= cycle_duration:
		current_time = 0.0

	_update_sun_position()
	_update_environment()

func _update_sun_position() -> void:
	if sun_light == null:
		return

	var angle = (current_time / cycle_duration) * TAU - PI
	sun_light.rotation.x = angle
	sun_light.rotation.z = 0

func _update_environment() -> void:
	var hour = int((current_time / cycle_duration) * 24.0)
	var old_time = time_of_day

	if hour >= 6 and hour < 18:
		time_of_day = "day"
	else:
		time_of_day = "night"

	if time_of_day != old_time:
		if time_of_day == "day":
			day_changed.emit()
		else:
			night_changed.emit()

	time_changed.emit(hour, int((current_time / cycle_duration) * 60.0) % 60)

func get_time_text() -> String:
	var hour = int((current_time / cycle_duration) * 24.0)
	var minute = int((current_time / cycle_duration) * 1440.0) % 60
	var period = "AM" if hour < 12 else "PM"
	var display_hour = hour if hour <= 12 else hour - 12
	return "%02d:%02d %s (%s)" % [display_hour, minute, period, time_of_day]

func set_time(hour: int) -> void:
	current_time = (hour / 24.0) * cycle_duration
