extends Node3D

class_name CameraSystem

enum CameraMode { THIRD_PERSON, FOLLOW, CINEMATIC }

@export var camera_distance: float = 3.0
@export var camera_height: float = 1.5
@export var look_ahead_distance: float = 5.0
@export var mouse_sensitivity: float = 0.01
@export var smoothing: float = 0.1

@onready var camera: Camera3D = $Camera3D

var current_mode: CameraMode = CameraMode.THIRD_PERSON
var target_position: Vector3 = Vector3.ZERO
var target_rotation: Vector3 = Vector3.ZERO
var camera_horizontal_angle: float = 0.0
var camera_vertical_angle: float = 0.0

var player: Node3D = null

func _ready() -> void:
	if not camera:
		camera = Camera3D.new()
		add_child(camera)
		camera.current = true

func _physics_process(delta: float) -> void:
	if not player:
		return

	match current_mode:
		CameraMode.THIRD_PERSON:
			_update_third_person(delta)
		CameraMode.FOLLOW:
			_update_follow(delta)
		CameraMode.CINEMATIC:
			_update_cinematic(delta)

func _update_third_person(delta: float) -> void:
	var player_pos = player.global_position

	var forward = -player.model.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var up = Vector3.UP

	target_position = player_pos + (up * camera_height) - (forward * camera_distance)

	camera.global_position = camera.global_position.lerp(target_position, smoothing)
	camera.look_at(player_pos + Vector3(0, camera_height * 0.5, 0), up)

func _update_follow(delta: float) -> void:
	var mouse_delta = Input.get_vector("ui_right", "ui_left", "ui_up", "ui_down")

	camera_horizontal_angle += mouse_delta.x * mouse_sensitivity
	camera_vertical_angle = clamp(camera_vertical_angle + mouse_delta.y * mouse_sensitivity, -PI / 2, PI / 2)

	var player_pos = player.global_position + Vector3(0, camera_height, 0)

	var offset = Vector3(
		sin(camera_horizontal_angle) * cos(camera_vertical_angle),
		sin(camera_vertical_angle),
		cos(camera_horizontal_angle) * cos(camera_vertical_angle)
	) * camera_distance

	target_position = player_pos + offset
	camera.global_position = camera.global_position.lerp(target_position, smoothing)
	camera.look_at(player_pos, Vector3.UP)

func _update_cinematic(delta: float) -> void:
	var player_pos = player.global_position
	var offset = Vector3(sin(get_tree().get_frame()), camera_height, cos(get_tree().get_frame() * 0.5)) * camera_distance

	target_position = player_pos + offset
	camera.global_position = camera.global_position.lerp(target_position, smoothing)
	camera.look_at(player_pos + Vector3(0, camera_height * 0.5, 0), Vector3.UP)

func set_camera_mode(mode: CameraMode) -> void:
	current_mode = mode

func set_player_reference(p: Node3D) -> void:
	player = p

func set_camera_distance(distance: float) -> void:
	camera_distance = distance

func set_camera_height(height: float) -> void:
	camera_height = height
