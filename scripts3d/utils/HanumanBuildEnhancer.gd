extends Node

class_name HanumanBuildEnhancer

const BULK_SCALE = {
	"upperarm.l": Vector3(1.6, 1.15, 1.6),
	"upperarm.r": Vector3(1.6, 1.15, 1.6),
	"lowerarm.l": Vector3(1.35, 1.05, 1.35),
	"lowerarm.r": Vector3(1.35, 1.05, 1.35),
	"clavicle.l": Vector3(1.3, 1.2, 1.3),
	"clavicle.r": Vector3(1.3, 1.2, 1.3),
	"spine_01": Vector3(1.5, 1.1, 1.4),
	"spine_02": Vector3(1.6, 1.1, 1.5),
	"thigh.l": Vector3(1.5, 1.1, 1.5),
	"thigh.r": Vector3(1.5, 1.1, 1.5),
	"calf.l": Vector3(1.3, 1.05, 1.3),
	"calf.r": Vector3(1.3, 1.05, 1.3),
	"neck_01": Vector3(1.25, 1.0, 1.25),
}

static func apply_muscular_build(skeleton: Skeleton3D) -> void:
	"""Bulk up torso/limb bones for a powerful, muscular Hanuman silhouette."""
	if not skeleton:
		return
	for bone_name in BULK_SCALE:
		var idx = skeleton.find_bone(bone_name)
		if idx != -1:
			skeleton.set_bone_pose_scale(idx, BULK_SCALE[bone_name])

static func find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = find_skeleton(child)
		if result:
			return result
	return null

static func attach_gada(skeleton: Skeleton3D, hand_bone: String = "hand.r") -> BoneAttachment3D:
	if not skeleton or skeleton.find_bone(hand_bone) == -1:
		return null
	var attachment = BoneAttachment3D.new()
	attachment.bone_name = hand_bone
	skeleton.add_child(attachment)
	var gada = Node3D.new()
	attachment.add_child(gada)
	gada.position.y = -0.05

	var handle = MeshInstance3D.new()
	var h_mesh = CylinderMesh.new()
	h_mesh.top_radius = 0.03
	h_mesh.bottom_radius = 0.035
	h_mesh.height = 0.55
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color(0.45, 0.32, 0.12)
	h_mat.roughness = 0.7
	handle.mesh = h_mesh
	handle.position.y = -0.3
	gada.add_child(handle)

	var head = MeshInstance3D.new()
	var h_mesh2 = SphereMesh.new()
	h_mesh2.radius = 0.16
	h_mesh2.height = 0.32
	var h_mat2 = StandardMaterial3D.new()
	h_mat2.albedo_color = Color(0.7, 0.62, 0.25)
	h_mat2.metallic = 0.4
	h_mat2.roughness = 0.35
	head.mesh = h_mesh2
	gada.add_child(head)

	for i in range(6):
		var spike = MeshInstance3D.new()
		var s_mesh = CylinderMesh.new()
		s_mesh.top_radius = 0.0
		s_mesh.bottom_radius = 0.035
		s_mesh.height = 0.12
		spike.mesh = s_mesh
		var angle = i * TAU / 6.0
		var dir = Vector3(cos(angle), 0, sin(angle))
		spike.position = dir * 0.16
		spike.look_at(spike.global_position + dir, Vector3.UP)
		gada.add_child(spike)

	return attachment

static func attach_dhoti(skeleton: Skeleton3D, pelvis_bone: String = "pelvis") -> BoneAttachment3D:
	if not skeleton or skeleton.find_bone(pelvis_bone) == -1:
		return null
	var attachment = BoneAttachment3D.new()
	attachment.bone_name = pelvis_bone
	skeleton.add_child(attachment)

	var dhoti = MeshInstance3D.new()
	var d_mesh = CylinderMesh.new()
	d_mesh.top_radius = 0.32
	d_mesh.bottom_radius = 0.42
	d_mesh.height = 0.65
	var d_mat = StandardMaterial3D.new()
	d_mat.albedo_color = Color(0.85, 0.35, 0.1)
	d_mat.roughness = 0.9
	dhoti.mesh = d_mesh
	dhoti.position.y = -0.35
	attachment.add_child(dhoti)

	var sash = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(0.5, 0.12, 0.08)
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color(0.95, 0.8, 0.2)
	sash.mesh = s_mesh
	sash.position = Vector3(0, 0.05, 0.35)
	attachment.add_child(sash)

	return attachment

static func enhance(character_root: Node) -> void:
	var skeleton = find_skeleton(character_root)
	if not skeleton:
		return
	apply_muscular_build(skeleton)
	attach_gada(skeleton)
	attach_dhoti(skeleton)
	apply_skin_color(character_root, Color(0.55, 0.28, 0.12), Color(0.75, 0.4, 0.15))

static func find_mesh_instances(node: Node, out_list: Array) -> void:
	if node is MeshInstance3D:
		out_list.append(node)
	for child in node.get_children():
		find_mesh_instances(child, out_list)

static func apply_skin_color(character_root: Node, primary_color: Color, fur_color: Color = Color(0.75, 0.4, 0.15)) -> void:
	var meshes: Array = []
	find_mesh_instances(character_root, meshes)
	for mesh_inst in meshes:
		for i in range(mesh_inst.mesh.get_surface_count()):
			var src_mat = mesh_inst.mesh.surface_get_material(i)
			if not src_mat:
				continue
			var mat_name = src_mat.resource_name
			var mat = StandardMaterial3D.new()
			if mat_name == "hanuman_skin":
				mat.albedo_color = primary_color
				mat.roughness = 0.65
				mesh_inst.set_surface_override_material(i, mat)
			elif mat_name == "Negro_COLOR_0":
				mat.albedo_color = fur_color
				mat.roughness = 0.8
				mesh_inst.set_surface_override_material(i, mat)
