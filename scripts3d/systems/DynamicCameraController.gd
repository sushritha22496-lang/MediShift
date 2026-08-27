extends Camera3D

class_name DynamicCameraController

var target: Node3D = null
var follow_distance: float = 8.0
var follow_height: float = 4.0
var follow_smoothness: float = 0.1
var focus_point: Vector3 = Vector3.ZERO
var is_combat_mode: bool = false

var camera_offset: Vector3 = Vector3(0, 4, 8)
var rotation_speed: float = 0.05
var zoom_distance: float = 8.0
var min_zoom: float = 3.0
var max_zoom: float = 15.0

var mouse_x: float = 0.0
var mouse_y: float = 0.0
var pitch: float = -0.3
var yaw: float = 0.0

func _ready() -> void:
	current = true
	fov = 75.0

func _process(delta: float) -> void:
	if not target:
		return

	_handle_input()
	_update_camera_position(delta)
	_update_camera_rotation(delta)

func set_target(node: Node3D) -> void:
	target = node
	focus_point = target.global_position

func set_combat_mode(enabled: bool) -> void:
	is_combat_mode = enabled
	if enabled:
		follow_distance = 12.0
		follow_height = 6.0
		var tween = get_tree().create_tween()
		tween.tween_property(self, "fov", 65.0, 0.5)
	else:
		follow_distance = 8.0
		follow_height = 4.0
		var tween = get_tree().create_tween()
		tween.tween_property(self, "fov", 75.0, 0.5)

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
	var original_pos = global_position
	var tween = get_tree().create_tween()
	for i in range(int(duration * 60)):
		var shake_offset = Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(self, "global_position", original_pos + shake_offset, 0.01)
	tween.tween_property(self, "global_position", original_pos, 0.05)

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
