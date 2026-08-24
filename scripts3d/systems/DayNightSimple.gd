extends BaseSystemSimple

class_name DayNightSimple

@export var cycle_speed: float = 0.1
@export var day_light_color: Color = Color.WHITE
@export var night_light_color: Color = Color(0.3, 0.3, 0.5)

signal day_started
signal night_started
signal hour_changed(hour: int)
signal day_changed(day: int)
signal weather_changed(weather: String)
signal celestial_event(event: String)

func _ready() -> void:
	set_state("hour", 6)
	set_state("day", 1)
	set_state("time_elapsed", 0.0)
	set_state("is_day", true)
	set_state("season", 0)
	set_state("temperature", 20.0)
	set_state("pollution", 0.0)
	set_state("scheduled_events", {})
	set_state("weather", "clear")
	set_state("weather_duration", 0.0)
	set_state("time_events", [])
	set_state("moon_phase", 0)

func _process(delta: float) -> void:
	var time = get_state("time_elapsed", 0.0)
	time += delta * cycle_speed
	set_state("time_elapsed", time)

	var hour = int(time) % 24
	var prev_hour = get_state("hour", 6)

	if hour != prev_hour:
		set_state("hour", hour)
		hour_changed.emit(hour)
		emit_event("hour_changed", hour)

		var is_day = hour >= 6 and hour < 18
		var was_day = get_state("is_day", true)

		if is_day != was_day:
			set_state("is_day", is_day)
			if is_day:
				day_started.emit()
				emit_event("day_started", hour)
			else:
				night_started.emit()
				emit_event("night_started", hour)

	if time >= 24.0:
		var day = get_state("day", 1)
		day += 1
		set_state("day", day)
		set_state("time_elapsed", 0.0)
		day_changed.emit(day)
		emit_event("day_changed", day)

func get_hour() -> int:
	return get_state("hour", 6)

func get_day() -> int:
	return get_state("day", 1)

func is_daytime() -> bool:
	return get_state("is_day", true)

func is_nighttime() -> bool:
	return not is_daytime()

func advance_hour(hours: int = 1) -> void:
	var hour = get_state("hour", 6)
	hour = (hour + hours) % 24
	set_state("hour", hour)
	hour_changed.emit(hour)

	var is_day = hour >= 6 and hour < 18
	var was_day = get_state("is_day", true)
	if is_day != was_day:
		set_state("is_day", is_day)
		if is_day:
			day_started.emit()
		else:
			night_started.emit()
	emit_event("hour_advanced", hour)

func set_time(hour: int) -> void:
	hour = clampi(hour, 0, 23)
	set_state("hour", hour)
	var is_day = hour >= 6 and hour < 18
	set_state("is_day", is_day)
	hour_changed.emit(hour)
	emit_event("time_set", hour)

func get_light_color() -> Color:
	if is_daytime():
		return day_light_color
	return night_light_color

func get_time_text() -> String:
	var hour = get_hour()
	var day = get_day()
	var season = get_season()
	var temp = get_state("temperature", 20.0)
	var period = "AM" if hour < 12 else "PM"
	var display_hour = hour if hour <= 12 else hour - 12
	var time_str = "%02d:00 %s" % [display_hour if display_hour > 0 else 12, period]
	var day_str = "Day %d (%s)" % [day, season.capitalize()]
	return "%s - %s - %.0f°C" % [time_str, day_str, temp]

func get_time_of_day() -> String:
	var hour = get_hour()
	if hour >= 6 and hour < 9:
		return "sunrise"
	elif hour >= 9 and hour < 12:
		return "morning"
	elif hour >= 12 and hour < 15:
		return "afternoon"
	elif hour >= 15 and hour < 18:
		return "sunset"
	elif hour >= 18 and hour < 21:
		return "evening"
	else:
		return "night"

func get_season() -> String:
	var day = get_day()
	var season_day = day % 90
	if season_day < 22:
		return "spring"
	elif season_day < 45:
		return "summer"
	elif season_day < 67:
		return "autumn"
	else:
		return "winter"

func update_temperature() -> void:
	var hour = get_hour()
	var season = get_season()
	var base_temp = 20.0
	var season_temps = {"spring": 15.0, "summer": 28.0, "autumn": 18.0, "winter": 5.0}
	base_temp = season_temps.get(season, 20.0)
	var hour_factor = sin((hour - 6.0) * PI / 12.0) * 8.0
	var new_temp = base_temp + hour_factor
	set_state("temperature", new_temp)

func register_scheduled_event(event_id: String, hour: int, callback: Callable) -> void:
	var events = get_state("scheduled_events", {})
	events[event_id] = {"hour": hour, "callback": callback, "triggered": false}
	set_state("scheduled_events", events)

func check_scheduled_events() -> void:
	var hour = get_hour()
	var events = get_state("scheduled_events", {})
	for event_id in events:
		var event = events[event_id]
		if event["hour"] == hour and not event.get("triggered", false):
			event["triggered"] = true
			emit_event("scheduled_event_triggered", event_id)

func get_time_of_day_atmosphere() -> Dictionary:
	var time_of_day = get_time_of_day()
	var atmospheres = {
		"sunrise": {"light": 0.6, "fog": 0.4, "visibility": 0.7},
		"morning": {"light": 1.0, "fog": 0.1, "visibility": 1.0},
		"afternoon": {"light": 1.0, "fog": 0.05, "visibility": 1.0},
		"sunset": {"light": 0.7, "fog": 0.5, "visibility": 0.7},
		"evening": {"light": 0.3, "fog": 0.3, "visibility": 0.5},
		"night": {"light": 0.1, "fog": 0.2, "visibility": 0.3}
	}
	return atmospheres.get(time_of_day, {})

func set_weather(weather_type: String, duration: float = 120.0) -> void:
	var valid = ["clear", "rainy", "stormy", "snowy", "foggy"]
	if weather_type in valid:
		set_state("weather", weather_type)
		set_state("weather_duration", duration)
		weather_changed.emit(weather_type)
		emit_event("weather_changed", weather_type)

func get_weather() -> String:
	return get_state("weather", "clear")

func update_moon_phase(delta: float = 1.0) -> void:
	var phase = get_state("moon_phase", 0)
	phase = (phase + int(delta)) % 29
	set_state("moon_phase", phase)
	if phase == 0 or phase == 14:
		celestial_event.emit("full_moon" if phase == 14 else "new_moon")
		emit_event("lunar_event", phase)

func get_moon_phase_name() -> String:
	var phase = get_state("moon_phase", 0)
	if phase < 3:
		return "new_moon"
	elif phase < 8:
		return "waxing_crescent"
	elif phase < 11:
		return "first_quarter"
	elif phase < 16:
		return "waxing_gibbous"
	elif phase < 19:
		return "full_moon"
	elif phase < 24:
		return "waning_gibbous"
	else:
		return "waning_crescent"

func record_time_event(event_type: String, description: String) -> void:
	var events = get_state("time_events", [])
	events.append({"type": event_type, "description": description, "day": get_day(), "hour": get_hour()})
	set_state("time_events", events)
	emit_event("time_event_recorded", event_type)

func get_time_events_in_range(start_day: int, end_day: int) -> Array:
	var events = get_state("time_events", [])
	return events.filter(func(e): return e["day"] >= start_day and e["day"] <= end_day)
