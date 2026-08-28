extends Camera3D

class_name DynamicCameraController

enum CameraMode { FOLLOW, CINEMATIC, COMBAT, DIALOGUE, TOP_DOWN }

var target: Node3D = null
var follow_distance: float = 8.0
var follow_height: float = 4.0
var follow_smoothness: float = 0.1
var focus_point: Vector3 = Vector3.ZERO
var current_camera_mode: CameraMode = CameraMode.FOLLOW

var camera_offset: Vector3 = Vector3(0, 4, 8)
var rotation_speed: float = 0.05
var zoom_distance: float = 8.0
var min_zoom: float = 3.0
var max_zoom: float = 15.0

var mouse_x: float = 0.0
var mouse_y: float = 0.0
var pitch: float = -0.3
var yaw: float = 0.0

# Camera presets for different modes
var camera_presets = {
	CameraMode.FOLLOW: {"distance": 8.0, "height": 4.0, "fov": 75.0, "pitch": -0.3},
	CameraMode.CINEMATIC: {"distance": 10.0, "height": 5.0, "fov": 60.0, "pitch": -0.4},
	CameraMode.COMBAT: {"distance": 12.0, "height": 6.0, "fov": 65.0, "pitch": -0.35},
	CameraMode.DIALOGUE: {"distance": 6.0, "height": 3.0, "fov": 70.0, "pitch": -0.25},
	CameraMode.TOP_DOWN: {"distance": 15.0, "height": 12.0, "fov": 75.0, "pitch": -1.2}
}

# Screen shake tracking
var shake_intensity: float = 0.0
var shake_time_remaining: float = 0.0

func _ready() -> void:
	current = true
	fov = 75.0

func _process(delta: float) -> void:
	if not target:
		return

	_handle_input()
	_update_camera_position(delta)
	_update_camera_rotation(delta)
	_update_screen_shake(delta)

func set_target(node: Node3D) -> void:
	target = node
	focus_point = target.global_position

func set_camera_mode(mode: CameraMode, transition_time: float = 0.5) -> void:
	current_camera_mode = mode
	if camera_presets.has(mode):
		var preset = camera_presets[mode]
		var tween = get_tree().create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)

		tween.tween_parallel()
		tween.tween_property(self, "follow_distance", preset["distance"], transition_time)
		tween.tween_property(self, "follow_height", preset["height"], transition_time)
		tween.tween_property(self, "fov", preset["fov"], transition_time)
		tween.tween_property(self, "pitch", preset["pitch"], transition_time)

func set_combat_mode(enabled: bool) -> void:
	if enabled:
		set_camera_mode(CameraMode.COMBAT, 0.5)
	else:
		set_camera_mode(CameraMode.FOLLOW, 0.5)

func look_at_target() -> void:
	if target:
		look_at(target.global_position + Vector3(0, 2, 0), Vector3.UP)

func pan_camera(direction: Vector3, duration: float = 1.0) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", global_position + direction, duration)

func _handle_input() -> void:
	if Input.is_action_pressed("ui_right"):
		yaw -= rotation_speed
	if Input.is_action_pressed("ui_left"):
		yaw += rotation_speed
	if Input.is_action_pressed("ui_up"):
		pitch = clamp(pitch + rotation_speed, -PI / 2, PI / 4)
	if Input.is_action_pressed("ui_down"):
		pitch = clamp(pitch - rotation_speed, -PI / 2, PI / 4)

	if Input.is_action_pressed("zoom_in"):
		zoom_distance = max(min_zoom, zoom_distance - 0.2)
	if Input.is_action_pressed("zoom_out"):
		zoom_distance = min(max_zoom, zoom_distance + 0.2)

func _update_camera_position(delta: float) -> void:
	if not target:
		return

	var target_pos = target.global_position
	target_pos.y += follow_height

	var camera_dir = Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	).normalized()

	var desired_position = target_pos - camera_dir * zoom_distance

	global_position = global_position.lerp(desired_position, follow_smoothness)

func _update_camera_rotation(delta: float) -> void:
	if not target:
		return

	var target_look = target.global_position + Vector3(0, 2, 0)

	var current_forward = -global_transform.basis.z
	var desired_forward = (target_look - global_position).normalized()

	var new_forward = current_forward.lerp(desired_forward, 0.05)
	look_at(global_position + new_forward, Vector3.UP)

func apply_screen_shake(intensity: float, duration: float = 0.3) -> void:
	shake_intensity = intensity
	shake_time_remaining = duration

func _update_screen_shake(delta: float) -> void:
	if shake_time_remaining > 0:
		shake_time_remaining -= delta
	else:
		shake_intensity = 0.0

func focus_on_action(focus_target: Vector3, zoom_level: float = 5.0) -> void:
	focus_point = focus_target
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "zoom_distance", zoom_level, 0.5)

func return_to_target() -> void:
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "zoom_distance", 8.0, 0.5)

func get_camera_forward() -> Vector3:
	return -global_transform.basis.z

func get_camera_right() -> Vector3:
	return global_transform.basis.x
