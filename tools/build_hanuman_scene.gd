extends SceneTree

func _init():
	var root := CharacterBody3D.new()
	root.name = "Hanuman3D"
	root.collision_layer = 2
	root.collision_mask = 5
	root.set_script(load("res://scripts3d/player/Hanuman3D.gd"))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.position = Vector3(0, 1.1, 0)
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 2.2
	col.shape = cap
	root.add_child(col)
	col.owner = root

	var glb_scene: PackedScene = load("res://assets/models/hanuman.glb")
	var glb_root: Node3D = glb_scene.instantiate()
	var found: Node3D = glb_root.find_child("Model", true, false)
	var model: Node3D
	if found == null:
		model = glb_root
		root.add_child(model)
	else:
		model = found.duplicate()
		glb_root.queue_free()
		model.name = "Model"
		root.add_child(model)
	model.name = "Model"
	model.position.y = 0.2
	model.owner = root
	_set_owner_recursive(model, root)

	var gada_pivot: Node3D = model.get_node("GadaPivot")
	var attack_area := Area3D.new()
	attack_area.name = "AttackArea"
	attack_area.collision_layer = 0
	attack_area.collision_mask = 4
	attack_area.monitoring = false
	gada_pivot.add_child(attack_area)
	attack_area.owner = root

	var attack_shape := CollisionShape3D.new()
	attack_shape.name = "AttackShape"
	attack_shape.position = Vector3(0, 0.7, 0)
	var cap2 := CapsuleShape3D.new()
	cap2.radius = 0.45
	cap2.height = 1.8
	attack_shape.shape = cap2
	attack_area.add_child(attack_shape)
	attack_shape.owner = root

	var spring := SpringArm3D.new()
	spring.name = "SpringArm3D"
	spring.transform = str_to_var("Transform3D(1, 0, 0, 0, 0.939693, 0.34202, 0, -0.34202, 0.939693, 0, 2.2, 0)")
	spring.spring_length = 7.0
	spring.collision_mask = 1
	root.add_child(spring)
	spring.owner = root

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.current = true
	cam.fov = 55.0
	var cam_attr := CameraAttributesPractical.new()
	cam_attr.dof_blur_far_enabled = true
	cam_attr.dof_blur_far_distance = 22.0
	cam_attr.dof_blur_far_transition = 12.0
	cam_attr.dof_blur_amount = 0.15
	cam.attributes = cam_attr
	spring.add_child(cam)
	cam.owner = root

	var packed := PackedScene.new()
	var result := packed.pack(root)
	if result != OK:
		print("PACK_FAILED: ", result)
		quit(1)
		return
	var save_result := ResourceSaver.save(packed, "res://scenes3d/player/hanuman_3d.tscn")
	if save_result != OK:
		print("SAVE_FAILED: ", save_result)
		quit(1)
		return
	print("SCENE_SAVED_OK")
	quit()

func _set_owner_recursive(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		_set_owner_recursive(child, owner)
