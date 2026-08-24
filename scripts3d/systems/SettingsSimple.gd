extends Node

class_name SettingsSimple

var settings: Dictionary = {
	"graphics": {
		"quality": "High",
		"shadows": true,
		"bloom": true,
		"anti_aliasing": "FXAA",
		"resolution": Vector2(1280, 720),
		"vsync": true,
		"target_fps": 60
	},
	"audio": {
		"master_volume": 0.8,
		"music_volume": 0.6,
		"sfx_volume": 0.8,
		"dialogue_volume": 0.9
	},
	"gameplay": {
		"difficulty": "Normal",
		"auto_save": true,
		"show_hints": true,
		"camera_sensitivity": 0.5,
		"invert_y": false
	},
	"controls": {
		"movement_type": "WASD",
		"controller_enabled": false,
		"interact_key": "E",
		"jump_key": "Space",
		"sprint_key": "Shift"
	}
}

signal setting_changed(category: String, key: String, value)

func set_setting(category: String, key: String, value) -> void:
	if category in settings and key in settings[category]:
		settings[category][key] = value
		setting_changed.emit(category, key, value)
		print("Setting %s.%s = %s" % [category, key, str(value)])

func get_setting(category: String, key: String):
	if category in settings and key in settings[category]:
		return settings[category][key]
	return null

func get_graphics_quality() -> String:
	return get_setting("graphics", "quality")

func get_master_volume() -> float:
	return get_setting("audio", "master_volume")

func get_difficulty() -> String:
	return get_setting("gameplay", "difficulty")

func is_vsync_enabled() -> bool:
	return get_setting("graphics", "vsync")

func get_camera_sensitivity() -> float:
	return get_setting("gameplay", "camera_sensitivity")

func should_show_hints() -> bool:
	return get_setting("gameplay", "show_hints")

func get_resolution() -> Vector2:
	return get_setting("graphics", "resolution")

func set_resolution(res: Vector2) -> void:
	set_setting("graphics", "resolution", res)
	get_window().size = res

func set_difficulty(difficulty: String) -> void:
	set_setting("gameplay", "difficulty", difficulty)

func get_all_settings() -> Dictionary:
	return settings

func reset_to_defaults() -> void:
	settings = {
		"graphics": {
			"quality": "High",
			"shadows": true,
			"bloom": true,
			"anti_aliasing": "FXAA",
			"resolution": Vector2(1280, 720),
			"vsync": true,
			"target_fps": 60
		},
		"audio": {
			"master_volume": 0.8,
			"music_volume": 0.6,
			"sfx_volume": 0.8,
			"dialogue_volume": 0.9
		},
		"gameplay": {
			"difficulty": "Normal",
			"auto_save": true,
			"show_hints": true,
			"camera_sensitivity": 0.5,
			"invert_y": false
		},
		"controls": {
			"movement_type": "WASD",
			"controller_enabled": false,
			"interact_key": "E",
			"jump_key": "Space",
			"sprint_key": "Shift"
		}
	}
