extends BaseSystemSimple

class_name LightingSimple

class Light:
	var id: String
	var name: String
	var color: Color
	var intensity: float
	var range: float
	var light_type: String
	func _init(p_id: String, p_name: String, p_color: Color, p_intensity: float, p_range: float, p_type: String = "point") -> void:
		id = p_id
		name = p_name
		color = p_color
		intensity = p_intensity
		range = p_range
		light_type = p_type

var lights: Dictionary = {}

signal light_created(light: Light)
signal light_removed(light_id: String)
signal light_changed(light_id: String)

func _ready() -> void:
	set_state("active_lights", [])
	set_state("ambient_light", Color.WHITE)
	set_state("ambient_intensity", 0.5)
	_initialize_lights()

func _initialize_lights() -> void:
	lights = {
		"sun": Light.new("sun", "Sun", Color.WHITE, 1.0, 100.0, "directional"),
		"moon": Light.new("moon", "Moon", Color(0.5, 0.5, 1.0), 0.3, 50.0, "directional"),
		"torch": Light.new("torch", "Torch", Color(1.0, 0.7, 0.3), 1.0, 10.0, "omni"),
		"spell_glow": Light.new("spell_glow", "Spell Glow", Color(0.5, 0.5, 1.0), 0.8, 15.0, "omni"),
		"fire": Light.new("fire", "Fire", Color(1.0, 0.5, 0.0), 0.9, 20.0, "omni")
	}

func add_light(light_id: String) -> bool:
	if light_id in lights:
		var active = get_state("active_lights", [])
		if light_id not in active:
			active.append(light_id)
			set_state("active_lights", active)
			light_created.emit(lights[light_id])
			emit_event("light_added", light_id)
			return true
	return false

func remove_light(light_id: String) -> bool:
	var active = get_state("active_lights", [])
	if light_id in active:
		active.erase(light_id)
		set_state("active_lights", active)
		light_removed.emit(light_id)
		emit_event("light_removed", light_id)
		return true
	return false

func get_light(light_id: String) -> Light:
	return lights.get(light_id, null)

func set_light_intensity(light_id: String, intensity: float) -> void:
	if light_id in lights:
		lights[light_id].intensity = clampf(intensity, 0.0, 2.0)
		light_changed.emit(light_id)
		emit_event("light_intensity_changed", light_id)

func set_ambient_light(color: Color, intensity: float) -> void:
	set_state("ambient_light", color)
	set_state("ambient_intensity", clampf(intensity, 0.0, 1.0))
	emit_event("ambient_light_changed", "")

func get_active_lights() -> Array:
	var active_ids = get_state("active_lights", [])
	var active: Array = []
	for light_id in active_ids:
		active.append(lights[light_id])
	return active

func get_lighting_text() -> String:
	var active = get_active_lights()
	var ambient = get_state("ambient_light", Color.WHITE)
	var ambient_intensity = get_state("ambient_intensity", 0.5)
	var text = "Lighting\nActive Lights: %d\n" % active.size()
	text += "Ambient: %.0f%% brightness" % (ambient_intensity * 100.0)
	return text
