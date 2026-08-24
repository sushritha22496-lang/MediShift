extends BaseSystemSimple

class_name WeatherSimple

@export var change_interval: float = 30.0

signal weather_changed(weather_type: String)
signal storm_started
signal storm_ended
signal hazard_triggered(hazard_type: String)

var weather_types = ["clear", "cloudy", "rain", "storm", "snow"]
var weather_transitions = {"clear": ["cloudy"], "cloudy": ["clear", "rain"], "rain": ["cloudy", "storm"], "storm": ["rain"], "snow": ["cloudy"]}

func _ready() -> void:
	set_state("current_weather", "clear")
	set_state("intensity", 0.0)
	set_state("change_timer", 0.0)
	set_state("temperature", 20.0)
	set_state("wind_speed", 0.0)
	set_state("lightning_strikes", 0)
	set_state("visibility_obstacles", [])
	set_state("weather_change_history", [])
	set_state("temperature_history", [])
	set_state("wind_history", [])
	set_state("hazard_tracking", [])
	set_state("weather_statistics", {})
	set_state("visibility_history", [])

func _process(delta: float) -> void:
	var timer = get_state("change_timer", 0.0)
	timer += delta
	if timer >= change_interval:
		change_weather()
		set_state("change_timer", 0.0)
	else:
		set_state("change_timer", timer)

func change_weather() -> void:
	var old_weather = get_state("current_weather", "clear")
	var possible_transitions = weather_transitions.get(old_weather, ["clear"])
	var new_weather = possible_transitions[randi() % possible_transitions.size()]

	if new_weather != old_weather:
		set_state("current_weather", new_weather)
		var intensity = randf_range(0.3, 1.0)
		set_state("intensity", intensity)
		_record_weather_change(old_weather, new_weather, intensity)
		update_weather_properties(new_weather, intensity)
		weather_changed.emit(new_weather)
		emit_event("weather_changed", new_weather)

		if new_weather == "storm":
			storm_started.emit()
			emit_event("storm_started", "")
		elif old_weather == "storm":
			storm_ended.emit()
			emit_event("storm_ended", "")

func update_weather_properties(weather: String, intensity: float) -> void:
	var temp = 20.0
	var wind = 0.0
	match weather:
		"clear":
			temp = 20.0 + intensity * 5.0
			wind = intensity * 2.0
		"cloudy":
			temp = 18.0
			wind = intensity * 4.0
		"rain":
			temp = 15.0
			wind = intensity * 8.0
		"storm":
			temp = 12.0
			wind = intensity * 15.0
			if randf() < intensity * 0.3:
				var strikes = get_state("lightning_strikes", 0) + 1
				set_state("lightning_strikes", strikes)
				hazard_triggered.emit("lightning")
		"snow":
			temp = -5.0 + intensity * 5.0
			wind = intensity * 10.0
	set_state("temperature", temp)
	set_state("wind_speed", wind)
	_record_temperature_history(temp)
	_record_wind_history(wind)
	_record_visibility(get_visibility_modifier())

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
	var temp = get_state("temperature", 20.0)
	var wind = get_state("wind_speed", 0.0)
	return "%s (%.0f%%) | Temp: %.0f°C | Wind: %.1f m/s" % [weather.capitalize(), intensity * 100.0, temp, wind]

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

func get_damage_modifier(damage_type: String) -> float:
	var weather = get_weather()
	var intensity = get_intensity()
	match weather:
		"storm":
			if damage_type == "electrical":
				return 1.5 * intensity
		"rain":
			if damage_type == "electrical":
				return 1.2 * intensity
		"snow":
			if damage_type == "fire":
				return 0.7
	return 1.0

func get_vision_range_modifier() -> float:
	var weather = get_weather()
	var intensity = get_intensity()
	match weather:
		"clear":
			return 1.0
		"cloudy":
			return 0.9 - (intensity * 0.1)
		"rain":
			return 0.7 - (intensity * 0.2)
		"storm":
			return 0.5 - (intensity * 0.3)
		"snow":
			return 0.6 - (intensity * 0.2)
	return 1.0

func apply_environmental_hazard(hazard_type: String) -> float:
	var damage = 0.0
	var weather = get_weather()
	var intensity = get_intensity()
	match hazard_type:
		"lightning" if weather == "storm":
			damage = randf_range(10.0, 30.0) * intensity
		"frostbite" if weather == "snow":
			damage = randf_range(5.0, 15.0) * intensity
		"dehydration" if weather == "clear":
			damage = randf_range(2.0, 8.0) * intensity
	if damage > 0:
		_record_hazard(hazard_type, damage)
	return damage

func _record_weather_change(old_weather: String, new_weather: String, intensity: float) -> void:
	var history = get_state("weather_change_history", [])
	history.append({"from": old_weather, "to": new_weather, "intensity": intensity, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("weather_change_history", history)

func _record_temperature_history(temp: float) -> void:
	var history = get_state("temperature_history", [])
	history.append({"temp": temp, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("temperature_history", history)

func _record_wind_history(wind: float) -> void:
	var history = get_state("wind_history", [])
	history.append({"wind": wind, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("wind_history", history)

func _record_hazard(hazard_type: String, damage: float) -> void:
	var tracking = get_state("hazard_tracking", [])
	tracking.append({"type": hazard_type, "damage": damage, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("hazard_tracking", tracking)
	emit_event("hazard_triggered", hazard_type)

func _record_visibility(visibility: float) -> void:
	var history = get_state("visibility_history", [])
	history.append({"visibility": visibility, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("visibility_history", history)

func get_weather_change_history() -> Array:
	return get_state("weather_change_history", [])

func get_hazard_tracking() -> Array:
	return get_state("hazard_tracking", [])

func update_weather_statistics() -> void:
	var stats = get_state("weather_statistics", {})
	stats["current_weather"] = get_weather()
	stats["current_temp"] = get_state("temperature", 20.0)
	stats["current_wind"] = get_state("wind_speed", 0.0)
	stats["lightning_strikes"] = get_state("lightning_strikes", 0)
	stats["weather_changes"] = get_state("weather_change_history", []).size()
	set_state("weather_statistics", stats)

func get_weather_statistics() -> Dictionary:
	update_weather_statistics()
	return get_state("weather_statistics", {})
