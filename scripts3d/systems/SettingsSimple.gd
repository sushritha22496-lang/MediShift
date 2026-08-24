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
	set_state("settings_change_history", [])
	set_state("settings_profiles", {})
	set_state("current_profile", "default")
	set_state("performance_impact_tracking", [])
	set_state("accessibility_features", {})
	set_state("settings_reset_count", 0)
	set_state("settings_statistics", {})

func set_setting(setting_name: String, value) -> void:
	var settings = get_state("settings", {})
	if setting_name in settings:
		var old_value = settings[setting_name]
		settings[setting_name] = value
		set_state("settings", settings)
		_record_setting_change(setting_name, old_value, value)
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
	var count = get_state("settings_reset_count", 0) + 1
	set_state("settings_reset_count", count)
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

func _record_setting_change(setting_name: String, old_value, new_value) -> void:
	var history = get_state("settings_change_history", [])
	history.append({"setting": setting_name, "old": old_value, "new": new_value, "time": Time.get_ticks_msec()})
	if history.size() > 50:
		history.pop_front()
	set_state("settings_change_history", history)

func save_settings_profile(profile_name: String) -> void:
	var profiles = get_state("settings_profiles", {})
	profiles[profile_name] = get_state("settings", {}).duplicate()
	set_state("settings_profiles", profiles)
	emit_event("profile_saved", profile_name)

func load_settings_profile(profile_name: String) -> bool:
	var profiles = get_state("settings_profiles", {})
	if profile_name in profiles:
		set_state("settings", profiles[profile_name].duplicate())
		set_state("current_profile", profile_name)
		setting_changed.emit("profile", profile_name)
		emit_event("profile_loaded", profile_name)
		return true
	return false

func get_settings_profiles() -> Array:
	var profiles = get_state("settings_profiles", {})
	return profiles.keys()

func record_performance_impact(setting_name: String, fps_before: int, fps_after: int) -> void:
	var tracking = get_state("performance_impact_tracking", [])
	tracking.append({"setting": setting_name, "fps_before": fps_before, "fps_after": fps_after, "time": Time.get_ticks_msec()})
	if tracking.size() > 50:
		tracking.pop_front()
	set_state("performance_impact_tracking", tracking)

func enable_accessibility_feature(feature_name: String, enabled: bool) -> void:
	var features = get_state("accessibility_features", {})
	features[feature_name] = enabled
	set_state("accessibility_features", features)
	emit_event("accessibility_feature_toggled", feature_name)

func is_accessibility_enabled(feature_name: String) -> bool:
	var features = get_state("accessibility_features", {})
	return features.get(feature_name, false)

func get_settings_change_history() -> Array:
	return get_state("settings_change_history", [])

func update_settings_statistics() -> void:
	var stats = get_state("settings_statistics", {})
	stats["changes_made"] = get_state("settings_change_history", []).size()
	stats["resets"] = get_state("settings_reset_count", 0)
	stats["profiles_saved"] = get_state("settings_profiles", {}).size()
	set_state("settings_statistics", stats)

func get_settings_statistics() -> Dictionary:
	update_settings_statistics()
	return get_state("settings_statistics", {})
