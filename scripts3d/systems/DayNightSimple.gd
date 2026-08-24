extends BaseSystemSimple

class_name DayNightSimple

@export var cycle_speed: float = 0.1
@export var day_light_color: Color = Color.WHITE
@export var night_light_color: Color = Color(0.3, 0.3, 0.5)

signal day_started
signal night_started
signal hour_changed(hour: int)
signal day_changed(day: int)

func _ready() -> void:
	set_state("hour", 6)
	set_state("day", 1)
	set_state("time_elapsed", 0.0)
	set_state("is_day", true)

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
	var period = "AM" if hour < 12 else "PM"
	var display_hour = hour if hour <= 12 else hour - 12
	var time_str = "%02d:00 %s" % [display_hour if display_hour > 0 else 12, period]
	var day_str = "Day %d" % day
	return "%s - %s" % [time_str, day_str]

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
