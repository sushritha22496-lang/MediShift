extends Node3D

class_name ProfessionalCharacterBuilder

static func build_rama_professional(character: Node3D) -> void:
	var model = character.get_node_or_null("Model")
	if not model:
		return

	_clear_character(model)

	var torso = _create_torso(Color(0.65, 0.45, 0.3), 1.0)
	model.add_child(torso)

	var head = _create_head(Color(0.7, 0.5, 0.35), Vector3(0, 1.8, 0))
	model.add_child(head)

	var left_arm = _create_arm(Color(0.65, 0.45, 0.3), Vector3(-0.8, 1.2, 0), -1)
	model.add_child(left_arm)

	var right_arm = _create_arm(Color(0.65, 0.45, 0.3), Vector3(0.8, 1.2, 0), 1)
	model.add_child(right_arm)

	var left_leg = _create_leg(Color(0.55, 0.38, 0.25), Vector3(-0.35, -0.8, 0), -1)
	model.add_child(left_leg)

	var right_leg = _create_leg(Color(0.55, 0.38, 0.25), Vector3(0.35, -0.8, 0), 1)
	model.add_child(right_leg)

	_add_armor_premium(model)
	_add_royal_symbols(model)
	_add_weapon_sword(model)

static func build_monkey_professional(character: Node3D) -> void:
	var model = character.get_node_or_null("Model")
	if not model:
		return

	_clear_character(model)

	var torso = _create_muscular_torso(Color(0.6, 0.3, 0.12), 0.9)
	model.add_child(torso)

	var head = _create_monkey_head(Color(0.55, 0.28, 0.1), Vector3(0, 1.8, 0))
	model.add_child(head)

	var left_arm = _create_muscular_arm(Color(0.6, 0.3, 0.12), Vector3(-0.9, 1.2, 0), -1)
	model.add_child(left_arm)

	var right_arm = _create_muscular_arm(Color(0.6, 0.3, 0.12), Vector3(0.9, 1.2, 0), 1)
	model.add_child(right_arm)

	var left_leg = _create_muscular_leg(Color(0.5, 0.25, 0.1), Vector3(-0.38, -0.9, 0), -1)
	model.add_child(left_leg)

	var right_leg = _create_muscular_leg(Color(0.5, 0.25, 0.1), Vector3(0.38, -0.9, 0), 1)
	model.add_child(right_leg)

	_add_monkey_tail(model)

static func build_hanuman_professional(character: Node3D) -> void:
	var model = character.get_node_or_null("Model")
	if not model:
		return

	_clear_character(model)

	var torso = _create_muscular_torso(Color(0.55, 0.28, 0.12), 1.2)
	model.add_child(torso)

	var head = _create_monkey_head(Color(0.5, 0.25, 0.1), Vector3(0, 2.0, 0))
	model.add_child(head)

	var left_arm = _create_muscular_arm(Color(0.55, 0.28, 0.12), Vector3(-1.0, 1.3, 0), -1)
	model.add_child(left_arm)

	var right_arm = _create_muscular_arm(Color(0.55, 0.28, 0.12), Vector3(1.0, 1.3, 0), 1)
	model.add_child(right_arm)

	var left_leg = _create_muscular_leg(Color(0.45, 0.22, 0.08), Vector3(-0.4, -1.0, 0), -1)
	model.add_child(left_leg)

	var right_leg = _create_muscular_leg(Color(0.45, 0.22, 0.08), Vector3(0.4, -1.0, 0), 1)
	model.add_child(right_leg)

	_add_monkey_features(model)
	_add_divine_marks(model)
	_add_weapon_mace(model)

static func _create_torso(color: Color, scale: float) -> Node3D:
	var torso = Node3D.new()
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 1.4, 0.5) * scale
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	mesh.set_surface_override_material(0, mat)
	mesh.position.y = 1.0
	torso.add_child(mesh)

	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(1.0, 1.4, 0.5) * scale
	collision.position.y = 1.0
	torso.add_child(collision)

	return torso

static func _create_muscular_torso(color: Color, scale: float) -> Node3D:
	var torso = Node3D.new()

	for i in range(2):
		var pec = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.35 * scale
		pec.mesh = sphere
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.5
		pec.set_surface_override_material(0, mat)
		pec.position = Vector3(sign(i - 0.5) * 0.5, 1.3, 0.15)
		pec.scale = Vector3(1.0, 1.2, 0.8)
		torso.add_child(pec)

	var main = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.1, 1.5, 0.6) * scale
	main.mesh = box
	var main_mat = StandardMaterial3D.new()
	main_mat.albedo_color = color
	main_mat.roughness = 0.6
	main.set_surface_override_material(0, main_mat)
	main.position.y = 1.0
	torso.add_child(main)

	return torso

static func _create_head(color: Color, pos: Vector3) -> Node3D:
	var head = Node3D.new()
	head.position = pos

	var skull = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	skull.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	skull.set_surface_override_material(0, mat)
	head.add_child(skull)

	var left_eye = MeshInstance3D.new()
	var eye_sphere = SphereMesh.new()
	eye_sphere.radius = 0.1
	left_eye.mesh = eye_sphere
	var eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color.BLACK
	left_eye.set_surface_override_material(0, eye_mat)
	left_eye.position = Vector3(-0.15, 0.1, 0.35)
	head.add_child(left_eye)

	var right_eye = MeshInstance3D.new()
	right_eye.mesh = eye_sphere
	right_eye.set_surface_override_material(0, eye_mat)
	right_eye.position = Vector3(0.15, 0.1, 0.35)
	head.add_child(right_eye)

	return head

static func _create_monkey_head(color: Color, pos: Vector3) -> Node3D:
	var head = Node3D.new()
	head.position = pos

	var skull = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.45
	skull.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	skull.set_surface_override_material(0, mat)
	head.add_child(skull)

	for i in range(2):
		var ear = MeshInstance3D.new()
		var ear_sphere = SphereMesh.new()
		ear_sphere.radius = 0.15
		ear.mesh = ear_sphere
		var ear_mat = StandardMaterial3D.new()
		ear_mat.albedo_color = Color(0.4, 0.15, 0.05)
		ear.set_surface_override_material(0, ear_mat)
		ear.position = Vector3(sign(i - 0.5) * 0.35, 0.3, -0.2)
		head.add_child(ear)

	for i in range(2):
		var eye = MeshInstance3D.new()
		var eye_sphere = SphereMesh.new()
		eye_sphere.radius = 0.12
		eye.mesh = eye_sphere
		var eye_mat = StandardMaterial3D.new()
		eye_mat.albedo_color = Color(1, 1, 1)
		eye.set_surface_override_material(0, eye_mat)
		eye.position = Vector3(sign(i - 0.5) * 0.18, 0.15, 0.4)
		head.add_child(eye)

		var pupil = MeshInstance3D.new()
		var pupil_sphere = SphereMesh.new()
		pupil_sphere.radius = 0.06
		pupil.mesh = pupil_sphere
		var pupil_mat = StandardMaterial3D.new()
		pupil_mat.albedo_color = Color.BLACK
		pupil.set_surface_override_material(0, pupil_mat)
		pupil.position = Vector3(sign(i - 0.5) * 0.18, 0.15, 0.45)
		head.add_child(pupil)

	return head

static func _create_arm(color: Color, pos: Vector3, side: int) -> Node3D:
	var arm = Node3D.new()
	arm.position = pos

	var upper = MeshInstance3D.new()
	var upper_cyl = CylinderMesh.new()
	upper_cyl.radius = 0.2
	upper_cyl.height = 0.8
	upper.mesh = upper_cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	upper.set_surface_override_material(0, mat)
	upper.position.y = 0.0
	arm.add_child(upper)

	var lower = MeshInstance3D.new()
	var lower_cyl = CylinderMesh.new()
	lower_cyl.radius = 0.18
	lower_cyl.height = 0.75
	lower.mesh = lower_cyl
	lower.set_surface_override_material(0, mat)
	lower.position.y = -0.8
	arm.add_child(lower)

	var hand = MeshInstance3D.new()
	var hand_sphere = SphereMesh.new()
	hand_sphere.radius = 0.15
	hand.mesh = hand_sphere
	var hand_mat = StandardMaterial3D.new()
	hand_mat.albedo_color = Color(0.7, 0.5, 0.35)
	hand.set_surface_override_material(0, hand_mat)
	hand.position.y = -1.6
	arm.add_child(hand)

	return arm

static func _create_muscular_arm(color: Color, pos: Vector3, side: int) -> Node3D:
	var arm = Node3D.new()
	arm.position = pos

	var bicep = MeshInstance3D.new()
	var bicep_sphere = SphereMesh.new()
	bicep_sphere.radius = 0.3
	bicep.mesh = bicep_sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	bicep.set_surface_override_material(0, mat)
	bicep.position.y = 0.2
	bicep.scale = Vector3(1.0, 1.3, 0.8)
	arm.add_child(bicep)

	var upper = MeshInstance3D.new()
	var upper_cyl = CylinderMesh.new()
	upper_cyl.radius = 0.25
	upper_cyl.height = 0.9
	upper.mesh = upper_cyl
	upper.set_surface_override_material(0, mat)
	upper.position.y = 0.0
	arm.add_child(upper)

	var lower = MeshInstance3D.new()
	var lower_cyl = CylinderMesh.new()
	lower_cyl.radius = 0.22
	lower_cyl.height = 0.85
	lower.mesh = lower_cyl
	lower.set_surface_override_material(0, mat)
	lower.position.y = -0.9
	arm.add_child(lower)

	var hand = MeshInstance3D.new()
	var hand_sphere = SphereMesh.new()
	hand_sphere.radius = 0.18
	hand.mesh = hand_sphere
	var hand_mat = StandardMaterial3D.new()
	hand_mat.albedo_color = Color(0.5, 0.25, 0.1)
	hand.set_surface_override_material(0, hand_mat)
	hand.position.y = -1.8
	arm.add_child(hand)

	return arm

static func _create_leg(color: Color, pos: Vector3, side: int) -> Node3D:
	var leg = Node3D.new()
	leg.position = pos

	var thigh = MeshInstance3D.new()
	var thigh_cyl = CylinderMesh.new()
	thigh_cyl.radius = 0.22
	thigh_cyl.height = 0.9
	thigh.mesh = thigh_cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.6
	thigh.set_surface_override_material(0, mat)
	thigh.position.y = 0.0
	leg.add_child(thigh)

	var calf = MeshInstance3D.new()
	var calf_cyl = CylinderMesh.new()
	calf_cyl.radius = 0.18
	calf_cyl.height = 0.85
	calf.mesh = calf_cyl
	calf.set_surface_override_material(0, mat)
	calf.position.y = -0.9
	leg.add_child(calf)

	var foot = MeshInstance3D.new()
	var foot_box = BoxMesh.new()
	foot_box.size = Vector3(0.25, 0.2, 0.4)
	foot.mesh = foot_box
	foot.set_surface_override_material(0, mat)
	foot.position = Vector3(0, -1.8, 0.1)
	leg.add_child(foot)

	return leg

static func _create_muscular_leg(color: Color, pos: Vector3, side: int) -> Node3D:
	var leg = Node3D.new()
	leg.position = pos

	var thigh = MeshInstance3D.new()
	var thigh_cyl = CylinderMesh.new()
	thigh_cyl.radius = 0.28
	thigh_cyl.height = 1.0
	thigh.mesh = thigh_cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	thigh.set_surface_override_material(0, mat)
	thigh.position.y = 0.0
	leg.add_child(thigh)

	var calf = MeshInstance3D.new()
	var calf_cyl = CylinderMesh.new()
	calf_cyl.radius = 0.22
	calf_cyl.height = 0.9
	calf.mesh = calf_cyl
	calf.set_surface_override_material(0, mat)
	calf.position.y = -1.0
	leg.add_child(calf)

	var foot = MeshInstance3D.new()
	var foot_box = BoxMesh.new()
	foot_box.size = Vector3(0.28, 0.22, 0.45)
	foot.mesh = foot_box
	foot.set_surface_override_material(0, mat)
	foot.position = Vector3(0, -1.9, 0.12)
	leg.add_child(foot)

	return leg

static func _clear_character(model: Node3D) -> void:
	for child in model.get_children():
		if child.name != "AnimationPlayer":
			child.queue_free()

static func _add_armor_premium(model: Node3D) -> void:
	var chest = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.15, 1.5, 0.3)
	chest.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.35, 0.35)
	mat.metallic = 0.8
	mat.roughness = 0.2
	chest.set_surface_override_material(0, mat)
	chest.position = Vector3(0, 1.0, 0.15)
	model.add_child(chest)

	for side in [-1, 1]:
		var shoulder = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		shoulder.mesh = sphere
		shoulder.set_surface_override_material(0, mat)
		shoulder.position = Vector3(side * 0.65, 1.5, 0)
		shoulder.scale = Vector3(1.2, 1.0, 1.0)
		model.add_child(shoulder)

static func _add_royal_symbols(model: Node3D) -> void:
	var crown = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.35
	torus.outer_radius = 0.42
	crown.mesh = torus
	var crown_mat = StandardMaterial3D.new()
	crown_mat.albedo_color = Color(1.0, 0.84, 0.0)
	crown_mat.metallic = 0.95
	crown_mat.roughness = 0.1
	crown.set_surface_override_material(0, crown_mat)
	crown.position = Vector3(0, 2.1, 0)
	crown.scale = Vector3(1.0, 0.25, 1.0)
	model.add_child(crown)

	for i in range(7):
		var spike = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.04
		cone.bottom_radius = 0.08
		cone.height = 0.5
		spike.mesh = cone
		spike.set_surface_override_material(0, crown_mat)
		var angle = (TAU / 7.0) * i
		spike.position = Vector3(cos(angle) * 0.4, 2.2, sin(angle) * 0.4)
		model.add_child(spike)

static func _add_monkey_tail(model: Node3D) -> void:
	var tail = MeshInstance3D.new()
	var tail_cyl = CylinderMesh.new()
	tail_cyl.radius = 0.12
	tail_cyl.height = 2.0
	tail.mesh = tail_cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.2, 0.08)
	mat.roughness = 0.6
	tail.set_surface_override_material(0, mat)
	tail.position = Vector3(0, 0.3, -0.6)
	tail.rotation.z = 0.35
	model.add_child(tail)

static func _add_monkey_features(model: Node3D) -> void:
	var tail = MeshInstance3D.new()
	var tail_cyl = CylinderMesh.new()
	tail_cyl.radius = 0.15
	tail_cyl.height = 2.0
	tail.mesh = tail_cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.2, 0.08)
	tail.set_surface_override_material(0, mat)
	tail.position = Vector3(0, 0.5, -0.5)
	tail.rotation.z = 0.3
	model.add_child(tail)

static func _add_divine_marks(model: Node3D) -> void:
	for i in range(3):
		var mark = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.08, 0.3, 0.02)
		mark.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.7, 0.0)
		mark.set_surface_override_material(0, mat)
		mark.position = Vector3(0, 1.5 - i * 0.3, 0.4)
		model.add_child(mark)

static func _add_weapon_sword(model: Node3D) -> void:
	var sword_holder = Node3D.new()
	sword_holder.name = "Sword"
	model.add_child(sword_holder)

	var blade = MeshInstance3D.new()
	var blade_box = BoxMesh.new()
	blade_box.size = Vector3(0.12, 2.5, 0.02)
	blade.mesh = blade_box
	var blade_mat = StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.75, 0.78, 0.8)
	blade_mat.metallic = 0.98
	blade_mat.roughness = 0.08
	blade.set_surface_override_material(0, blade_mat)
	blade.position = Vector3(1.0, 0.8, 0)
	sword_holder.add_child(blade)

	var guard = MeshInstance3D.new()
	var guard_box = BoxMesh.new()
	guard_box.size = Vector3(0.5, 0.1, 0.08)
	guard.mesh = guard_box
	var guard_mat = StandardMaterial3D.new()
	guard_mat.albedo_color = Color(0.8, 0.7, 0.5)
	guard.set_surface_override_material(0, guard_mat)
	guard.position = Vector3(1.0, 0.0, 0)
	sword_holder.add_child(guard)

	var hilt = MeshInstance3D.new()
	var hilt_cyl = CylinderMesh.new()
	hilt_cyl.radius = 0.08
	hilt_cyl.height = 0.4
	hilt.mesh = hilt_cyl
	hilt.set_surface_override_material(0, guard_mat)
	hilt.position = Vector3(1.0, -0.3, 0)
	sword_holder.add_child(hilt)

	var pommel = MeshInstance3D.new()
	var pommel_sphere = SphereMesh.new()
	pommel_sphere.radius = 0.1
	pommel.mesh = pommel_sphere
	pommel.set_surface_override_material(0, guard_mat)
	pommel.position = Vector3(1.0, -0.6, 0)
	sword_holder.add_child(pommel)

static func _add_weapon_mace(model: Node3D) -> void:
	var mace_holder = Node3D.new()
	mace_holder.name = "Mace"
	model.add_child(mace_holder)

	var handle = MeshInstance3D.new()
	var handle_cyl = CylinderMesh.new()
	handle_cyl.radius = 0.12
	handle_cyl.height = 1.6
	handle.mesh = handle_cyl
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.55, 0.4, 0.2)
	handle_mat.roughness = 0.7
	handle.set_surface_override_material(0, handle_mat)
	handle.position = Vector3(-1.1, 0.5, 0)
	mace_holder.add_child(handle)

	var head = MeshInstance3D.new()
	var head_sphere = SphereMesh.new()
	head_sphere.radius = 0.4
	head.mesh = head_sphere
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.45, 0.35, 0.2)
	head_mat.metallic = 0.7
	head_mat.roughness = 0.3
	head.set_surface_override_material(0, head_mat)
	head.position = Vector3(-1.1, 2.0, 0)
	mace_holder.add_child(head)

	for i in range(12):
		var spike = MeshInstance3D.new()
		var spike_cone = CylinderMesh.new()
		spike_cone.top_radius = 0.02
		spike_cone.bottom_radius = 0.1
		spike_cone.height = 0.25
		spike.mesh = spike_cone
		spike.set_surface_override_material(0, head_mat)
		var angle = (TAU / 12.0) * i
		var radius = 0.32
		spike.position = Vector3(-1.1 + cos(angle) * radius, 2.0 + sin(angle) * radius * 0.7, sin(angle) * radius * 0.5)
		mace_holder.add_child(spike)
