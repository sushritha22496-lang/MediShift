extends Node3D

class_name CharacterVisualEnhancer

static func enhance_rama(character: Node3D) -> void:
	var model = character.get_node_or_null("Model")
	if not model:
		return

	_add_armor_chest(model, Color(0.3, 0.3, 0.3))
	_add_arm_guards(model, Color(0.4, 0.35, 0.3))
	_add_leg_guards(model, Color(0.25, 0.25, 0.25))
	_add_crown(model, Color(1.0, 0.84, 0.0))
	_add_cape(model, Color(0.8, 0.1, 0.1))
	_add_sword(model)

static func enhance_hanuman(character: Node3D) -> void:
	var model = character.get_node_or_null("Model")
	if not model:
		return

	_add_armor_chest(model, Color(0.5, 0.4, 0.2))
	_add_arm_guards(model, Color(0.45, 0.35, 0.25))
	_add_leg_guards(model, Color(0.35, 0.3, 0.2))
	_add_dhoti(model, Color(0.9, 0.8, 0.5))
	_add_necklace(model, Color(1.0, 0.84, 0.0))
	_add_mace(model)

static func enhance_monkey(character: Node3D) -> void:
	var model = character.get_node_or_null("Model")
	if not model:
		return

	_add_armor_light(model, Color(0.4, 0.3, 0.2))
	_add_battle_marks(model)

static func _add_armor_chest(parent: Node3D, color: Color) -> void:
	var armor = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 1.5, 0.4)
	armor.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.7
	mat.roughness = 0.3
	armor.set_surface_override_material(0, mat)
	armor.position = Vector3(0, 1.0, 0.1)
	parent.add_child(armor)

static func _add_arm_guards(parent: Node3D, color: Color) -> void:
	for side in [-1, 1]:
		var guard = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.radius = 0.25
		cyl.height = 1.0
		guard.mesh = cyl
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.metallic = 0.6
		guard.set_surface_override_material(0, mat)
		guard.position = Vector3(side * 0.8, 0.8, 0)
		guard.rotation.z = PI / 6.0 * side
		parent.add_child(guard)

static func _add_leg_guards(parent: Node3D, color: Color) -> void:
	for side in [-1, 1]:
		var guard = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.35, 1.2, 0.3)
		guard.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.metallic = 0.6
		guard.set_surface_override_material(0, mat)
		guard.position = Vector3(side * 0.4, -0.6, 0.1)
		parent.add_child(guard)

static func _add_crown(parent: Node3D, color: Color) -> void:
	var crown = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.4
	torus.outer_radius = 0.5
	crown.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.9
	crown.set_surface_override_material(0, mat)
	crown.position = Vector3(0, 1.8, 0)
	crown.scale = Vector3(1.0, 0.3, 1.0)
	parent.add_child(crown)

	for i in range(5):
		var spike = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 0.1
		cone.height = 0.4
		spike.mesh = cone
		spike.set_surface_override_material(0, mat)
		var angle = (TAU / 5.0) * i
		spike.position = Vector3(cos(angle) * 0.45, 2.0, sin(angle) * 0.45)
		parent.add_child(spike)

static func _add_cape(parent: Node3D, color: Color) -> void:
	var cape = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.5, 1.8, 0.1)
	cape.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.alpha_scissor_threshold = 0.5
	cape.set_surface_override_material(0, mat)
	cape.position = Vector3(0, 1.0, -0.3)
	parent.add_child(cape)

static func _add_sword(parent: Node3D) -> void:
	var sword_group = Node3D.new()
	sword_group.name = "Sword"
	parent.add_child(sword_group)

	var blade = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.15, 2.5, 0.02)
	blade.mesh = box
	var blade_mat = StandardMaterial3D.new()
	blade_mat.albedo_color = Color(0.7, 0.7, 0.8)
	blade_mat.metallic = 0.95
	blade_mat.roughness = 0.1
	blade.set_surface_override_material(0, blade_mat)
	blade.position = Vector3(0.8, 1.0, 0)
	sword_group.add_child(blade)

	var hilt = MeshInstance3D.new()
	var hilt_box = BoxMesh.new()
	hilt_box.size = Vector3(0.2, 0.5, 0.15)
	hilt.mesh = hilt_box
	var hilt_mat = StandardMaterial3D.new()
	hilt_mat.albedo_color = Color(0.5, 0.35, 0.15)
	hilt.set_surface_override_material(0, hilt_mat)
	hilt.position = Vector3(0.8, -0.2, 0)
	sword_group.add_child(hilt)

static func _add_dhoti(parent: Node3D, color: Color) -> void:
	var dhoti = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.radius = 0.6
	cyl.height = 1.0
	dhoti.mesh = cyl
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	dhoti.set_surface_override_material(0, mat)
	dhoti.position = Vector3(0, -0.5, 0)
	parent.add_child(dhoti)

static func _add_necklace(parent: Node3D, color: Color) -> void:
	var necklace = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.3
	torus.outer_radius = 0.35
	necklace.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.8
	necklace.set_surface_override_material(0, mat)
	necklace.position = Vector3(0, 1.2, 0.15)
	necklace.rotation.x = PI / 3.0
	necklace.scale = Vector3(1.2, 0.4, 1.0)
	parent.add_child(necklace)

static func _add_mace(parent: Node3D) -> void:
	var mace_group = Node3D.new()
	mace_group.name = "Mace"
	parent.add_child(mace_group)

	var handle = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.radius = 0.1
	cyl.height = 1.5
	handle.mesh = cyl
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.5, 0.35, 0.15)
	handle.set_surface_override_material(0, handle_mat)
	handle.position = Vector3(-0.8, 0.5, 0)
	mace_group.add_child(handle)

	var head = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	head.mesh = sphere
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.4, 0.3, 0.2)
	head_mat.metallic = 0.7
	head.set_surface_override_material(0, head_mat)
	head.position = Vector3(-0.8, 1.8, 0)
	mace_group.add_child(head)

	for i in range(8):
		var spike = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		cone.top_radius = 0.02
		cone.bottom_radius = 0.08
		cone.height = 0.2
		spike.mesh = cone
		spike.set_surface_override_material(0, head_mat)
		var angle = (TAU / 8.0) * i
		var radius = 0.25
		spike.position = Vector3(-0.8 + cos(angle) * radius, 1.8 + sin(angle) * radius * 0.5, sin(angle) * radius)
		mace_group.add_child(spike)

static func _add_armor_light(parent: Node3D, color: Color) -> void:
	var armor = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.8, 1.0, 0.3)
	armor.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.5
	armor.set_surface_override_material(0, mat)
	armor.position = Vector3(0, 0.7, 0.08)
	parent.add_child(armor)

static func _add_battle_marks(parent: Node3D) -> void:
	var marks = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.1, 0.8, 0.02)
	marks.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.1, 0.1)
	marks.set_surface_override_material(0, mat)
	marks.position = Vector3(0.4, 0.8, 0.35)
	parent.add_child(marks)
