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
	"""Build a procedural Gada (mace) and attach it to the given hand bone."""
	if not skeleton:
		return null
	var bone_idx = skeleton.find_bone(hand_bone)
	if bone_idx == -1:
		return null

	var attachment = BoneAttachment3D.new()
	attachment.name = "GadaAttachment"
	attachment.bone_name = hand_bone
	skeleton.add_child(attachment)

	var gada = Node3D.new()
	gada.name = "Gada"
	attachment.add_child(gada)
	gada.transform = Transform3D(Basis(), Vector3(0.0, -0.05, 0.0))

	var handle = MeshInstance3D.new()
	var handle_mesh = CylinderMesh.new()
	handle_mesh.top_radius = 0.03
	handle_mesh.bottom_radius = 0.035
	handle_mesh.height = 0.55
	handle.mesh = handle_mesh
	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.45, 0.32, 0.12)
	handle_mat.roughness = 0.7
	handle_mesh.material = handle_mat
	handle.position = Vector3(0, -0.3, 0)
	gada.add_child(handle)

	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.16
	head_mesh.height = 0.32
	head.mesh = head_mesh
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.7, 0.62, 0.25)
	head_mat.metallic = 0.4
	head_mat.roughness = 0.35
	head_mesh.material = head_mat
	head.position = Vector3(0, 0.02, 0)
	gada.add_child(head)

	for i in range(6):
		var spike = MeshInstance3D.new()
		var spike_mesh = CylinderMesh.new()
		spike_mesh.top_radius = 0.0
		spike_mesh.bottom_radius = 0.035
		spike_mesh.height = 0.12
		spike.mesh = spike_mesh
		spike_mesh.material = head_mat
		var angle = i * TAU / 6.0
		var direction = Vector3(cos(angle), 0, sin(angle))
		spike.transform = Transform3D(Basis.looking_at(direction, Vector3.UP), Vector3(direction.x * 0.16, 0.02, direction.z * 0.16))
		spike.rotate_object_local(Vector3.RIGHT, PI / 2.0)
		gada.add_child(spike)

	return attachment

static func attach_dhoti(skeleton: Skeleton3D, pelvis_bone: String = "pelvis") -> BoneAttachment3D:
	"""Build a simple traditional dhoti garment around the waist/thighs."""
	if not skeleton:
		return null
	var bone_idx = skeleton.find_bone(pelvis_bone)
	if bone_idx == -1:
		return null

	var attachment = BoneAttachment3D.new()
	attachment.name = "DhotiAttachment"
	attachment.bone_name = pelvis_bone
	skeleton.add_child(attachment)

	var dhoti = MeshInstance3D.new()
	dhoti.name = "Dhoti"
	var dhoti_mesh = CylinderMesh.new()
	dhoti_mesh.top_radius = 0.32
	dhoti_mesh.bottom_radius = 0.42
	dhoti_mesh.height = 0.65
	dhoti.mesh = dhoti_mesh
	var dhoti_mat = StandardMaterial3D.new()
	dhoti_mat.albedo_color = Color(0.85, 0.35, 0.1)
	dhoti_mat.roughness = 0.9
	dhoti_mesh.material = dhoti_mat
	dhoti.position = Vector3(0, -0.35, 0)
	attachment.add_child(dhoti)

	var sash = MeshInstance3D.new()
	sash.name = "Sash"
	var sash_mesh = BoxMesh.new()
	sash_mesh.size = Vector3(0.5, 0.12, 0.08)
	sash.mesh = sash_mesh
	var sash_mat = StandardMaterial3D.new()
	sash_mat.albedo_color = Color(0.95, 0.8, 0.2)
	sash_mesh.material = sash_mat
	sash.position = Vector3(0, 0.05, 0.35)
	attachment.add_child(sash)

	return attachment

static func enhance(character_root: Node) -> void:
	"""Apply full muscular build + gada + dhoti to a Hanuman character instance."""
	var skeleton = find_skeleton(character_root)
	if not skeleton:
		push_warning("HanumanBuildEnhancer: no Skeleton3D found under " + str(character_root))
		return
	apply_muscular_build(skeleton)
	if not skeleton.has_node("GadaAttachment"):
		attach_gada(skeleton)
	if not skeleton.has_node("DhotiAttachment"):
		attach_dhoti(skeleton)
