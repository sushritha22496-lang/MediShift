extends BaseSystemSimple

class_name CameraControlSimple

signal camera_mode_changed(mode: String)
signal camera_zoomed(zoom_level: float)

enum CameraMode { FOLLOW, FIXED, ISOMETRIC, FIRST_PERSON, CINEMATIC }

func _ready() -> void:
	set_state("camera_mode", CameraMode.FOLLOW)
	set_state("zoom_level", 1.0)
	set_state("camera_distance", 5.0)
	set_state("camera_height", 2.0)
	set_state("look_ahead", 1.0)

func set_camera_mode(mode: CameraMode) -> void:
	set_state("camera_mode", mode)
	camera_mode_changed.emit(CameraMode.keys()[mode])
	emit_event("camera_mode_changed", CameraMode.keys()[mode])

func get_camera_mode() -> CameraMode:
	return get_state("camera_mode", CameraMode.FOLLOW)

func zoom(factor: float) -> void:
	var zoom = get_state("zoom_level", 1.0)
	zoom = clampf(zoom + factor, 0.5, 3.0)
	set_state("zoom_level", zoom)
	camera_zoomed.emit(zoom)
	emit_event("zoom_changed", zoom)

func set_camera_distance(distance: float) -> void:
	set_state("camera_distance", clampf(distance, 2.0, 20.0))
	emit_event("distance_changed", distance)

func set_camera_height(height: float) -> void:
	set_state("camera_height", clampf(height, 0.5, 10.0))
	emit_event("height_changed", height)

func get_camera_offset() -> Vector3:
	var distance = get_state("camera_distance", 5.0)
	var height = get_state("camera_height", 2.0)
	var zoom = get_state("zoom_level", 1.0)
	return Vector3(0, height, distance / zoom)

func get_camera_text() -> String:
	var mode = CameraMode.keys()[get_camera_mode()]
	var zoom = get_state("zoom_level", 1.0)
	return "Camera: %s | Zoom: %.1fx" % [mode, zoom]
