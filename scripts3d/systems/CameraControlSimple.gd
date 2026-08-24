extends BaseSystemSimple

class_name CameraControlSimple

class CameraPreset:
	var name: String
	var mode: int
	var distance: float
	var height: float
	var fov: float = 70.0
	var transition_speed: float = 0.5
	var look_ahead: float = 0.0
	var position_offset: Vector3 = Vector3.ZERO
	func _init(p_name: String, p_mode: int, p_distance: float, p_height: float) -> void:
		name = p_name
		mode = p_mode
		distance = p_distance
		height = p_height

signal camera_mode_changed(mode: String)
signal camera_zoomed(zoom_level: float)
signal camera_target_locked(target: Node3D)
signal camera_shake_started(intensity: float)

enum CameraMode { FOLLOW, FIXED, ISOMETRIC, FIRST_PERSON, CINEMATIC }

var camera_presets: Dictionary = {}
var is_transitioning: bool = false
var target_locked: Node3D = null

func _ready() -> void:
	set_state("camera_mode", CameraMode.FOLLOW)
	set_state("zoom_level", 1.0)
	set_state("camera_distance", 5.0)
	set_state("camera_height", 2.0)
	set_state("look_ahead", 1.0)
	set_state("fov", 70.0)
	set_state("camera_shake_intensity", 0.0)
	set_state("transition_speed", 0.5)
	set_state("motion_blur", 0.0)
	set_state("screen_position", Vector2(0.5, 0.4))
	set_state("camera_history", [])
	_initialize_presets()

func _initialize_presets() -> void:
	var follow_preset = CameraPreset.new("Follow", CameraMode.FOLLOW, 5.0, 2.0)
	follow_preset.fov = 70.0
	var isometric_preset = CameraPreset.new("Isometric", CameraMode.ISOMETRIC, 7.0, 7.0)
	isometric_preset.fov = 60.0
	isometric_preset.position_offset = Vector3(-3, 0, -3)
	var first_person_preset = CameraPreset.new("FirstPerson", CameraMode.FIRST_PERSON, 0.0, 0.0)
	first_person_preset.fov = 90.0
	var cinematic_preset = CameraPreset.new("Cinematic", CameraMode.CINEMATIC, 8.0, 4.0)
	cinematic_preset.fov = 50.0
	cinematic_preset.transition_speed = 1.0
	camera_presets = {
		"follow": follow_preset,
		"isometric": isometric_preset,
		"first_person": first_person_preset,
		"cinematic": cinematic_preset
	}

func set_camera_mode(mode: CameraMode, use_transition: bool = true) -> void:
	if use_transition and is_transitioning:
		return
	is_transitioning = true
	var transition_speed = get_state("transition_speed", 0.5)
	if use_transition:
		await get_tree().create_timer(transition_speed).timeout
	set_state("camera_mode", mode)
	is_transitioning = false
	camera_mode_changed.emit(CameraMode.keys()[mode])
	emit_event("camera_mode_changed", {"mode": CameraMode.keys()[mode], "transitioned": use_transition})

func get_camera_mode() -> CameraMode:
	return get_state("camera_mode", CameraMode.FOLLOW)

func zoom(factor: float) -> void:
	var zoom = get_state("zoom_level", 1.0)
	zoom = clampf(zoom + factor, 0.5, 3.0)
	set_state("zoom_level", zoom)
	camera_zoomed.emit(zoom)
	emit_event("zoom_changed", {"zoom": zoom})

func set_camera_distance(distance: float) -> void:
	set_state("camera_distance", clampf(distance, 2.0, 20.0))
	emit_event("distance_changed", distance)

func set_camera_height(height: float) -> void:
	set_state("camera_height", clampf(height, 0.5, 10.0))
	emit_event("height_changed", height)

func set_fov(fov: float) -> void:
	set_state("fov", clampf(fov, 30.0, 120.0))
	emit_event("fov_changed", fov)

func apply_camera_shake(intensity: float, duration: float = 0.3) -> void:
	set_state("camera_shake_intensity", intensity)
	camera_shake_started.emit(intensity)
	await get_tree().create_timer(duration).timeout
	set_state("camera_shake_intensity", 0.0)
	emit_event("camera_shake_finished", {})

func lock_on_target(target: Node3D) -> void:
	target_locked = target
	camera_target_locked.emit(target)
	emit_event("target_locked", target.name if target else "none")

func unlock_target() -> void:
	target_locked = null
	emit_event("target_unlocked", "")

func get_target_locked() -> Node3D:
	return target_locked

func set_screen_position(position: Vector2) -> void:
	set_state("screen_position", position.clamp(Vector2.ZERO, Vector2.ONE))
	emit_event("screen_position_changed", position)

func set_motion_blur(amount: float) -> void:
	set_state("motion_blur", clampf(amount, 0.0, 1.0))
	emit_event("motion_blur_changed", amount)

func get_camera_offset() -> Vector3:
	var distance = get_state("camera_distance", 5.0)
	var height = get_state("camera_height", 2.0)
	var zoom = get_state("zoom_level", 1.0)
	var offset = Vector3(0, height, distance / zoom)
	var preset = camera_presets.get(CameraMode.keys()[get_camera_mode()].to_lower())
	if preset:
		offset += preset.position_offset
	return offset

func get_camera_mode() -> CameraMode:
	return get_state("camera_mode", CameraMode.FOLLOW)

func get_fov() -> float:
	return get_state("fov", 70.0)

func get_camera_shake_intensity() -> float:
	return get_state("camera_shake_intensity", 0.0)

func get_preset(preset_name: String) -> CameraPreset:
	return camera_presets.get(preset_name)

func apply_preset(preset_name: String) -> bool:
	if preset_name not in camera_presets:
		return false
	var preset = camera_presets[preset_name]
	set_camera_mode(preset.mode)
	set_state("camera_distance", preset.distance)
	set_state("camera_height", preset.height)
	set_fov(preset.fov)
	set_state("transition_speed", preset.transition_speed)
	set_state("look_ahead", preset.look_ahead)
	return true

func get_camera_history() -> Array:
	var history = get_state("camera_history", [])
	return history

func _record_camera_position() -> void:
	var history = get_state("camera_history", [])
	history.append({
		"mode": CameraMode.keys()[get_camera_mode()],
		"zoom": get_state("zoom_level", 1.0),
		"timestamp": Time.get_ticks_msec()
	})
	if history.size() > 50:
		history.pop_front()
	set_state("camera_history", history)

func get_camera_text() -> String:
	var mode = CameraMode.keys()[get_camera_mode()]
	var zoom = get_state("zoom_level", 1.0)
	var shake = get_state("camera_shake_intensity", 0.0)
	var locked = "🔒" if target_locked else "📷"
	return "%s Camera: %s | Zoom: %.1fx | Shake: %.1f" % [locked, mode, zoom, shake]
