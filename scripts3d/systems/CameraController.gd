extends Node3D

class_name CameraController

@export var camera_distance: float = 5.0
@export var camera_height: float = 1.5
@export var look_speed: float = 5.0
@export var min_angle: float = -30.0
@export var max_angle: float = 60.0

var camera: Camera3D
var target: Node3D
var pitch: float = 15.0
var yaw: float = 0.0

signal camera_updated

func _ready() -> void:
	camera = $Camera3D
	if not camera:
		push_error("No Camera3D found")

func set_target(node: Node3D) -> void:
	target = node

func _process(delta: float) -> void:
	if not target or not camera:
		return

	var mouse_input = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		mouse_input.x += 1
	if Input.is_action_pressed("ui_left"):
		mouse_input.x -= 1
	if Input.is_action_pressed("ui_up"):
		mouse_input.y += 1
	if Input.is_action_pressed("ui_down"):
		mouse_input.y -= 1

	yaw += mouse_input.x * look_speed * delta
	pitch -= mouse_input.y * look_speed * delta
	pitch = clamp(pitch, min_angle, max_angle)

	var cam_pos = target.global_position
	cam_pos.y += camera_height
	cam_pos -= Vector3(sin(deg_to_rad(yaw)) * camera_distance * cos(deg_to_rad(pitch)),
		sin(deg_to_rad(pitch)) * camera_distance, cos(deg_to_rad(yaw)) * camera_distance * cos(deg_to_rad(pitch)))

	camera.global_position = cam_pos
	camera.look_at(target.global_position + Vector3(0, camera_height, 0), Vector3.UP)
	camera_updated.emit()

func get_forward() -> Vector3:
	if not camera:
		return Vector3.ZERO
	return -camera.global_transform.basis.z.normalized()
