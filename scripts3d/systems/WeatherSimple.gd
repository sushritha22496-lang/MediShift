extends Node3D

class_name WeatherSimple

enum WeatherType { CLEAR, RAIN, STORM, FOG, SNOW }

@export var weather_change_interval: float = 30.0
@export var world_environment: WorldEnvironment = null

var current_weather: WeatherType = WeatherType.CLEAR
var weather_timer: float = 0.0

signal weather_changed(new_weather: WeatherType)

func _ready() -> void:
	if world_environment == null:
		world_environment = get_node_or_null("../WorldEnvironment")

	weather_timer = weather_change_interval
	_update_weather_effects()

func _process(delta: float) -> void:
	weather_timer -= delta
	if weather_timer <= 0:
		weather_timer = weather_change_interval
		change_weather()

func change_weather() -> void:
	var new_weather = WeatherType.values()[randi() % WeatherType.size()]
	set_weather(new_weather)

func set_weather(weather: WeatherType) -> void:
	if weather == current_weather:
		return

	current_weather = weather
	_update_weather_effects()
	weather_changed.emit(weather)

func _update_weather_effects() -> void:
	match current_weather:
		WeatherType.CLEAR:
			print("🌞 Clear weather")
		WeatherType.RAIN:
			print("🌧️ Rain")
		WeatherType.STORM:
			print("⛈️ Thunderstorm")
		WeatherType.FOG:
			print("🌫️ Fog")
		WeatherType.SNOW:
			print("❄️ Snow")

func get_weather_text() -> String:
	match current_weather:
		WeatherType.CLEAR:
			return "Clear"
		WeatherType.RAIN:
			return "Rain"
		WeatherType.STORM:
			return "Thunderstorm"
		WeatherType.FOG:
			return "Fog"
		WeatherType.SNOW:
			return "Snow"
	return "Unknown"

func is_weather_harsh() -> bool:
	return current_weather in [WeatherType.STORM, WeatherType.SNOW]

func affects_visibility() -> bool:
	return current_weather in [WeatherType.FOG, WeatherType.STORM]
