extends Node3D

class_name DayNightSystem

@export var day_duration: float = 120.0
@export var sun: DirectionalLight3D
@export var world_environment: WorldEnvironment

var current_time: float = 6.0
var time_scale: float = 1.0
var is_day: bool = true

signal time_changed(hour: int, minute: int)
signal day_night_changed(is_day: bool)

func _ready() -> void:
	if not sun:
		sun = get_tree().root.get_child(0).find_child("DirectionalLight3D")

func _process(delta: float) -> void:
	_update_time(delta)
	_update_lighting()

func _update_time(delta: float) -> void:
	current_time += (delta / day_duration) * 24.0 * time_scale

	if current_time >= 24.0:
		current_time -= 24.0

	var hour = int(current_time)
	var minute = int((current_time - hour) * 60)

	time_changed.emit(hour, minute)

	var was_day = is_day
	is_day = (hour >= 6 and hour < 18)

	if was_day != is_day:
		day_night_changed.emit(is_day)

func _update_lighting() -> void:
	if not sun:
		return

	var angle = (current_time / 24.0) * TAU - PI / 2

	var sun_direction = Vector3(sin(angle), cos(angle), 0.5).normalized()
	sun.rotation = sun_direction

	var brightness = cos((current_time - 6) / 12.0 * PI)
	brightness = clamp(brightness, 0.2, 1.0)

	sun.energy_multiplier = brightness

	if world_environment:
		var env = world_environment.environment

		if is_day:
			env.sky.sky_material.sky_horizon_color = Color(0.75, 0.65, 0.45, 1).lerp(Color(1, 0.8, 0.6, 1), brightness)
			env.ambient_light_energy = 0.65 * brightness
		else:
			env.sky.sky_material.sky_horizon_color = Color(0.1, 0.15, 0.25, 1)
			env.ambient_light_energy = 0.2

func get_time_string() -> String:
	var hour = int(current_time)
	var minute = int((current_time - hour) * 60)
	return "%02d:%02d" % [hour, minute]

func get_hour() -> int:
	return int(current_time)

func get_minute() -> int:
	return int((current_time - get_hour()) * 60)

func set_time(hour: int, minute: int = 0) -> void:
	current_time = hour + (minute / 60.0)
	current_time = clamp(current_time, 0.0, 24.0)

func advance_time(hours: float) -> void:
	current_time += hours
	if current_time >= 24.0:
		current_time -= 24.0

func is_daytime() -> bool:
	return is_day

func is_nighttime() -> bool:
	return not is_day
