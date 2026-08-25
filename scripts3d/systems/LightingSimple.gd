extends BaseSystemSimple

class_name LightingSimple

class Light:
	var id: String
	var name: String
	var color: Color
	var intensity: float
	var range: float
	var light_type: String
	var cast_shadows: bool = true
	var flicker_enabled: bool = false
	var flicker_speed: float = 0.0
	var bloom_enabled: bool = false
	var bloom_intensity: float = 0.0
	var layer: int = 0
	var animation_enabled: bool = false
	var animation_speed: float = 1.0
	var base_intensity: float = 0.0
	func _init(p_id: String, p_name: String, p_color: Color, p_intensity: float, p_range: float, p_type: String = "point") -> void:
		id = p_id
		name = p_name
		color = p_color
		intensity = p_intensity
		base_intensity = p_intensity
		range = p_range
		light_type = p_type

var lights: Dictionary = {}
var lighting_presets: Dictionary = {}

signal light_created(light: Light)
signal light_removed(light_id: String)
signal light_changed(light_id: String)
signal lighting_preset_applied(preset: String)

func _ready() -> void:
	set_state("active_lights", [])
	set_state("ambient_light", Color.WHITE)
	set_state("ambient_intensity", 0.5)
	set_state("fog_enabled", false)
	set_state("fog_color", Color.GRAY)
	set_state("fog_density", 0.1)
	set_state("bloom_enabled", false)
	set_state("bloom_strength", 0.5)
	set_state("hdr_enabled", false)
	set_state("lighting_history", [])
	set_state("global_brightness", 1.0)
	_initialize_lights()
	_initialize_presets()

func _initialize_lights() -> void:
	var sun = Light.new("sun", "Sun", Color.WHITE, 1.0, 100.0, "directional")
	sun.cast_shadows = true
	sun.bloom_enabled = true
	sun.bloom_intensity = 0.8
	var moon = Light.new("moon", "Moon", Color(0.5, 0.5, 1.0), 0.3, 50.0, "directional")
	moon.cast_shadows = true
	var torch = Light.new("torch", "Torch", Color(1.0, 0.7, 0.3), 1.0, 10.0, "omni")
	torch.flicker_enabled = true
	torch.flicker_speed = 2.0
	torch.bloom_enabled = true
	torch.bloom_intensity = 0.5
	var spell_glow = Light.new("spell_glow", "Spell Glow", Color(0.5, 0.5, 1.0), 0.8, 15.0, "omni")
	spell_glow.animation_enabled = true
	spell_glow.animation_speed = 1.5
	spell_glow.bloom_enabled = true
	spell_glow.bloom_intensity = 0.7
	var fire = Light.new("fire", "Fire", Color(1.0, 0.5, 0.0), 0.9, 20.0, "omni")
	fire.flicker_enabled = true
	fire.flicker_speed = 3.0
	fire.bloom_enabled = true
	fire.bloom_intensity = 0.6
	lights = {
		"sun": sun, "moon": moon, "torch": torch,
		"spell_glow": spell_glow, "fire": fire
	}

func _initialize_presets() -> void:
	lighting_presets = {
		"daylight": {"ambient": Color.WHITE, "intensity": 1.0, "fog": false, "bloom": false},
		"night": {"ambient": Color(0.2, 0.2, 0.3), "intensity": 0.3, "fog": true, "bloom": false},
		"dusk": {"ambient": Color(1.0, 0.7, 0.5), "intensity": 0.7, "fog": true, "bloom": true},
		"cave": {"ambient": Color(0.3, 0.3, 0.3), "intensity": 0.2, "fog": true, "bloom": false},
		"magical": {"ambient": Color(0.5, 0.3, 0.8), "intensity": 0.6, "fog": false, "bloom": true}
	}

func add_light(light_id: String) -> bool:
	if light_id in lights:
		var active = get_state("active_lights", [])
		if light_id not in active:
			active.append(light_id)
			set_state("active_lights", active)
			light_created.emit(lights[light_id])
			_track_light_change("add", light_id)
			emit_event("light_added", light_id)
			return true
	return false

func remove_light(light_id: String) -> bool:
	var active = get_state("active_lights", [])
	if light_id in active:
		active.erase(light_id)
		set_state("active_lights", active)
		light_removed.emit(light_id)
		_track_light_change("remove", light_id)
		emit_event("light_removed", light_id)
		return true
	return false

func get_light(light_id: String) -> Light:
	return lights.get(light_id, null)

func set_light_intensity(light_id: String, intensity: float) -> void:
	if light_id in lights:
		lights[light_id].intensity = clampf(intensity, 0.0, 2.0)
		light_changed.emit(light_id)
		_track_light_change("intensity", light_id, intensity)
		emit_event("light_intensity_changed", light_id)

func enable_light_flicker(light_id: String, enabled: bool) -> void:
	if light_id in lights:
		lights[light_id].flicker_enabled = enabled
		_track_light_change("flicker", light_id, enabled)

func enable_light_animation(light_id: String, enabled: bool, speed: float = 1.0) -> void:
	if light_id in lights:
		lights[light_id].animation_enabled = enabled
		lights[light_id].animation_speed = speed
		_track_light_change("animation", light_id, enabled)

func _track_light_change(action: String, light_id: String, value: Variant = "") -> void:
	var history = get_state("lighting_history", [])
	history.append({"action": action, "light": light_id, "value": value, "timestamp": Time.get_ticks_msec()})
	if history.size() > 100:
		history.pop_front()
	set_state("lighting_history", history)

func set_ambient_light(color: Color, intensity: float) -> void:
	set_state("ambient_light", color)
	set_state("ambient_intensity", clampf(intensity, 0.0, 1.0))
	_track_light_change("ambient", "ambient", {"color": color.to_html(), "intensity": intensity})
	emit_event("ambient_light_changed", {})

func set_fog(enabled: bool, color: Color = Color.GRAY, density: float = 0.1) -> void:
	set_state("fog_enabled", enabled)
	set_state("fog_color", color)
	set_state("fog_density", clampf(density, 0.0, 1.0))
	emit_event("fog_changed", {"enabled": enabled, "density": density})

func set_bloom(enabled: bool, strength: float = 0.5) -> void:
	set_state("bloom_enabled", enabled)
	set_state("bloom_strength", clampf(strength, 0.0, 2.0))
	emit_event("bloom_changed", {"enabled": enabled, "strength": strength})

func apply_preset(preset_name: String) -> bool:
	if preset_name not in lighting_presets:
		return false
	var preset = lighting_presets[preset_name]
	set_ambient_light(preset["ambient"], preset["intensity"])
	set_fog(preset["fog"])
	set_bloom(preset["bloom"])
	lighting_preset_applied.emit(preset_name)
	emit_event("preset_applied", preset_name)
	return true

func set_global_brightness(brightness: float) -> void:
	set_state("global_brightness", clampf(brightness, 0.0, 2.0))
	emit_event("brightness_changed", brightness)

func get_active_lights() -> Array:
	var active_ids = get_state("active_lights", [])
	var active: Array = []
	for light_id in active_ids:
		active.append(lights[light_id])
	return active

func is_fog_enabled() -> bool:
	return get_state("fog_enabled", false)

func is_bloom_enabled() -> bool:
	return get_state("bloom_enabled", false)

func get_active_light_count() -> int:
	return get_state("active_lights", []).size()

func get_shadow_casting_lights() -> Array:
	var result: Array = []
	for light in get_active_lights():
		if light.cast_shadows:
			result.append(light)
	return result

func get_flickering_lights() -> Array:
	var result: Array = []
	for light in get_active_lights():
		if light.flicker_enabled:
			result.append(light)
	return result

func get_animated_lights() -> Array:
	var result: Array = []
	for light in get_active_lights():
		if light.animation_enabled:
			result.append(light)
	return result

func get_lighting_history() -> Array:
	return get_state("lighting_history", [])

func get_available_presets() -> Array:
	return lighting_presets.keys()

func get_lighting_statistics() -> Dictionary:
	return {
		"active_lights": get_active_light_count(),
		"total_lights_defined": lights.size(),
		"shadow_casting_lights": get_shadow_casting_lights().size(),
		"flickering_lights": get_flickering_lights().size(),
		"animated_lights": get_animated_lights().size(),
		"history_entries": get_state("lighting_history", []).size(),
		"fog_enabled": is_fog_enabled(),
		"bloom_enabled": is_bloom_enabled(),
		"presets_available": lighting_presets.size(),
		"global_brightness": get_state("global_brightness", 1.0)
	}

func get_lighting_text() -> String:
	var active = get_active_lights()
	var ambient = get_state("ambient_light", Color.WHITE)
	var ambient_intensity = get_state("ambient_intensity", 0.5)
	var brightness = get_state("global_brightness", 1.0)
	var fog = "Fog" if get_state("fog_enabled", false) else ""
	var bloom = "Bloom" if get_state("bloom_enabled", false) else ""
	var effects = [fog, bloom].filter(func(x): return x != "")
	var text = "Lights: %d | Ambient: %.0f%% | Brightness: %.1fx\n" % [active.size(), ambient_intensity * 100, brightness]
	if not effects.is_empty():
		text += "Effects: %s" % ", ".join(effects)
	return text
