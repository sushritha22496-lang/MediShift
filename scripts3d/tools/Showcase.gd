extends Node3D

@onready var player: Node3D = $Hanuman3D

func _ready() -> void:
	player.set_physics_process(false)
	if player.has_node("SpringArm3D/Camera3D"):
		player.get_node("SpringArm3D/Camera3D").current = false
	var cam: Camera3D = $ShowcaseCamera
	cam.global_position = Vector3(-1.2, 1.4, 3.0)
	cam.look_at(Vector3(0, 1.0, 0), Vector3.UP)
	cam.current = true
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("res://../screenshot_output.png")
	print("SCREENSHOT_SAVED")
	get_tree().quit()
