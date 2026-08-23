extends Node3D

@onready var player: Node3D = $Hanuman3D

func _ready() -> void:
	player.set_physics_process(false)
	if player.has_node("SpringArm3D/Camera3D"):
		player.get_node("SpringArm3D/Camera3D").current = false
	var cam: Camera3D = $ShowcaseCamera
	cam.current = true
	cam.fov = 40.0
	var center := Vector3(0, 1.0, 0)
	var radius := 2.6
	var height := 1.15
	var angles := [0, 45, 90, 135, 180, 225, 270, 315]
	for i in range(angles.size()):
		var rad := deg_to_rad(angles[i])
		cam.global_position = Vector3(sin(rad) * radius, height, -cos(rad) * radius) + Vector3(center.x, 0, center.z)
		cam.look_at(center, Vector3.UP)
		await get_tree().process_frame
		await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		img.save_png("res://../qa_360_%02d.png" % angles[i])
	cam.global_position = Vector3(0, 2.6, 0.01)
	cam.look_at(Vector3(0, 0, 0), Vector3(0, 0, -1))
	await get_tree().process_frame
	await get_tree().process_frame
	var img_top := get_viewport().get_texture().get_image()
	img_top.save_png("res://../qa_top.png")
	print("QA_360_SAVED")
	get_tree().quit()
