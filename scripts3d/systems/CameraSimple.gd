extends Camera3D

class_name CameraSimple

enum CameraMode { THIRD_PERSON, FIRST_PERSON, FOLLOW, CINEMATIC }

@export var camera_distance: float = 5.0
@export var camera_height: float = 2.0
@export var follow_speed: float = 5.0
@export var mouse_sensitivity: float = 0.003
@export var vertical_rotation_limit: float = PI / 2

var current_mode: CameraMode = CameraMode.THIRD_PERSON
var target: Node3D = null
var horizontal_angle: float = 0.0
var vertical_angle: float = 0.5

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if target == null:
		target = get_parent()

func _process(delta: float) -> void:
	_handle_camera_input()
	_update_camera_position(delta)

func _handle_camera_input() -> void:
	var mouse_delta = Input.get_last_mouse_velocity()
	if mouse_delta.length() > 0:
		horizontal_angle += mouse_delta.x * mouse_sensitivity
		vertical_angle += mouse_delta.y * mouse_sensitivity
		vertical_angle = clamp(vertical_angle, -vertical_rotation_limit, vertical_rotation_limit)

func _update_camera_position(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return

	match current_mode:
		CameraMode.THIRD_PERSON:
			_update_third_person(delta)
		CameraMode.FIRST_PERSON:
			_update_first_person(delta)
		CameraMode.FOLLOW:
			_update_follow(delta)
		CameraMode.CINEMATIC:
			_update_cinematic(delta)

func _update_third_person(delta: float) -> void:
	var offset = Vector3(
		sin(horizontal_angle) * camera_distance * cos(vertical_angle),
		camera_height + sin(vertical_angle) * camera_distance,
		cos(horizontal_angle) * camera_distance * cos(vertical_angle)
	)

	global_position = global_position.lerp(target.global_position + offset, follow_speed * delta)
	look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)

func _update_first_person(delta: float) -> void:
	global_position = global_position.lerp(target.global_position + Vector3(0, camera_height, 0), follow_speed * delta)
	look_at(target.global_position + Vector3(0, camera_height, 0) - Vector3(sin(horizontal_angle), tan(vertical_angle), cos(horizontal_angle)) * 10, Vector3.UP)

func _update_follow(delta: float) -> void:
	var follow_offset = Vector3(0, camera_height * 0.5, -camera_distance * 0.8)
	global_position = global_position.lerp(target.global_position + follow_offset, follow_speed * delta)
	look_at(target.global_position + Vector3(0, camera_height * 0.5, 0), Vector3.UP)

func _update_cinematic(delta: float) -> void:
	var cinematic_offset = Vector3(sin(horizontal_angle) * camera_distance, camera_height + 1, cos(horizontal_angle) * camera_distance)
	global_position = global_position.lerp(target.global_position + cinematic_offset, follow_speed * 0.5 * delta)
	look_at(target.global_position + Vector3(0, camera_height, 0), Vector3.UP)

func set_camera_mode(mode: CameraMode) -> void:
	current_mode = mode
	print("Camera mode: %s" % CameraMode.keys()[mode])

func set_target(new_target: Node3D) -> void:
	target = new_target

func set_sensitivity(sensitivity: float) -> void:
	mouse_sensitivity = sensitivity

func toggle_mouse_capture() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
