extends BaseSystemSimple

class_name WeatherSimple

@export var change_interval: float = 30.0

signal weather_changed(weather_type: String)
signal storm_started
signal storm_ended

var weather_types = ["clear", "cloudy", "rain", "storm", "snow"]

func _ready() -> void:
	set_state("current_weather", "clear")
	set_state("intensity", 0.0)
	set_state("change_timer", 0.0)

func _process(delta: float) -> void:
	var timer = get_state("change_timer", 0.0)
	timer += delta
	if timer >= change_interval:
		change_weather()
		set_state("change_timer", 0.0)
	else:
		set_state("change_timer", timer)

func change_weather() -> void:
	var new_weather = weather_types[randi() % weather_types.size()]
	var old_weather = get_state("current_weather", "clear")
	
	if new_weather != old_weather:
		set_state("current_weather", new_weather)
		set_state("intensity", randf() * 1.0)
		weather_changed.emit(new_weather)
		emit_event("weather_changed", new_weather)

		if new_weather == "storm":
			storm_started.emit()
			emit_event("storm_started", "")
		elif old_weather == "storm":
			storm_ended.emit()
			emit_event("storm_ended", "")

func get_weather() -> String:
	return get_state("current_weather", "clear")

func get_intensity() -> float:
	return get_state("intensity", 0.0)

func set_weather(weather_type: String) -> bool:
	if weather_type in weather_types:
		set_state("current_weather", weather_type)
		set_state("intensity", randf() * 1.0)
		weather_changed.emit(weather_type)
		emit_event("weather_set", weather_type)
		return true
	return false

func is_storming() -> bool:
	return get_weather() == "storm"

func is_raining() -> bool:
	var weather = get_weather()
	return weather == "rain" or weather == "storm"

func get_visibility_modifier() -> float:
	var weather = get_weather()
	match weather:
		"clear":
			return 1.0
		"cloudy":
			return 0.8
		"rain":
			return 0.6
		"storm":
			return 0.4
		"snow":
			return 0.5
	return 1.0

func get_weather_effects() -> String:
	var weather = get_weather()
	var intensity = get_intensity()
	return "%s (%.0f%%)" % [weather.capitalize(), intensity * 100.0]

func get_movement_penalty() -> float:
	var weather = get_weather()
	var intensity = get_intensity()
	match weather:
		"rain":
			return 0.1 * intensity
		"storm":
			return 0.3 * intensity
		"snow":
			return 0.15 * intensity
	return 0.0
