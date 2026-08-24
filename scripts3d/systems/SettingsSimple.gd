extends BaseSystemSimple

class_name SettingsSimple

signal setting_changed(setting_name: String, value)
signal settings_saved
signal settings_reset

func _ready() -> void:
	set_state("settings", {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8,
		"brightness": 1.0,
		"contrast": 1.0,
		"field_of_view": 75,
		"difficulty": "normal",
		"subtitles": true,
		"screen_shake": true,
		"motion_blur": false,
		"ray_tracing": false,
		"fullscreen": true,
		"resolution": "1920x1080",
		"frame_rate_limit": 60
	})

func set_setting(setting_name: String, value) -> void:
	var settings = get_state("settings", {})
	if setting_name in settings:
		settings[setting_name] = value
		set_state("settings", settings)
		setting_changed.emit(setting_name, value)
		emit_event("setting_changed", setting_name)

func get_setting(setting_name: String):
	var settings = get_state("settings", {})
	return settings.get(setting_name, null)

func get_all_settings() -> Dictionary:
	return get_state("settings", {})

func save_settings() -> void:
	settings_saved.emit()
	emit_event("settings_saved", "")

func reset_to_defaults() -> void:
	var defaults = {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8,
		"brightness": 1.0,
		"contrast": 1.0,
		"field_of_view": 75,
		"difficulty": "normal",
		"subtitles": true,
		"screen_shake": true,
		"motion_blur": false,
		"ray_tracing": false,
		"fullscreen": true,
		"resolution": "1920x1080",
		"frame_rate_limit": 60
	}
	set_state("settings", defaults)
	settings_reset.emit()
	emit_event("settings_reset", "")

func is_subtitles_enabled() -> bool:
	return get_setting("subtitles") as bool

func get_difficulty() -> String:
	return get_setting("difficulty") as String

func get_volume(category: String) -> float:
	return get_setting(category + "_volume") as float

func get_settings_text() -> String:
	var text = "Settings\n"
	text += "Volume: %.0f%%\n" % (get_volume("master") * 100.0)
	text += "Brightness: %.0f%%\n" % (get_setting("brightness") as float * 100.0)
	text += "Difficulty: %s\n" % get_difficulty()
	text += "Subtitles: %s\n" % ("On" if is_subtitles_enabled() else "Off")
	return text
