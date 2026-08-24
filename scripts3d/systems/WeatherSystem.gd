extends Node3D

class_name WeatherSystem

enum WeatherType { CLEAR, RAIN, STORM, FOG, CLOUDY }

@export var weather_change_interval: float = 60.0
@export var world_environment: WorldEnvironment

var current_weather: WeatherType = WeatherType.CLEAR
var weather_intensity: float = 0.0
var weather_timer: float = 0.0

signal weather_changed(weather_type: WeatherType)
signal weather_intensity_changed(intensity: float)

func _ready() -> void:
	if not world_environment:
		world_environment = get_tree().root.get_child(0).find_child("WorldEnvironment")

func _process(delta: float) -> void:
	weather_timer += delta

	if weather_timer >= weather_change_interval:
		weather_timer = 0.0
		_change_weather()

	_update_weather_effects(delta)

func _change_weather() -> void:
	var weather_types = [
		WeatherType.CLEAR,
		WeatherType.CLOUDY,
		WeatherType.FOG,
		WeatherType.RAIN,
		WeatherType.STORM
	]

	var new_weather = weather_types[randi() % weather_types.size()]

	if new_weather != current_weather:
		current_weather = new_weather
		weather_changed.emit(current_weather)

func _update_weather_effects(delta: float) -> void:
	if not world_environment or not world_environment.environment:
		return

	var env = world_environment.environment

	match current_weather:
		WeatherType.CLEAR:
			env.fog_density = lerp(env.fog_density, 0.005, delta * 0.5)
			weather_intensity = 0.0

		WeatherType.CLOUDY:
			env.fog_density = lerp(env.fog_density, 0.008, delta * 0.5)
			weather_intensity = 0.3

		WeatherType.FOG:
			env.fog_density = lerp(env.fog_density, 0.02, delta * 0.5)
			weather_intensity = 0.5

		WeatherType.RAIN:
			env.fog_density = lerp(env.fog_density, 0.015, delta * 0.5)
			weather_intensity = 0.7

		WeatherType.STORM:
			env.fog_density = lerp(env.fog_density, 0.025, delta * 0.5)
			weather_intensity = 1.0

	weather_intensity_changed.emit(weather_intensity)

func get_weather_name() -> String:
	match current_weather:
		WeatherType.CLEAR:
			return "Clear"
		WeatherType.RAIN:
			return "Rainy"
		WeatherType.STORM:
			return "Stormy"
		WeatherType.FOG:
			return "Foggy"
		WeatherType.CLOUDY:
			return "Cloudy"
		_:
			return "Unknown"

func get_weather_intensity() -> float:
	return weather_intensity

func set_weather(weather: WeatherType) -> void:
	current_weather = weather
	weather_changed.emit(current_weather)
