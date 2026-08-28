extends Node3D

class_name ProfessionalCharacterBuilder

# Character specifications
const SPEC_RAMA = {
	"torso_scale": 1.0,
	"head_pos": Vector3(0, 1.8, 0),
	"arm_pos_x": 0.8,
	"arm_pos_y": 1.2,
	"leg_pos_x": 0.35,
	"leg_pos_y": -0.8,
	"skin_color": Color(0.65, 0.45, 0.3),
	"skin_light": Color(0.7, 0.5, 0.35),
	"leg_color": Color(0.55, 0.38, 0.25),
	"is_muscular": false,
	"has_armor": true,
	"has_crown": true,
	"weapon": "sword"
}

const SPEC_HANUMAN = {
	"torso_scale": 1.2,
	"head_pos": Vector3(0, 2.0, 0),
	"arm_pos_x": 1.0,
	"arm_pos_y": 1.3,
	"leg_pos_x": 0.4,
	"leg_pos_y": -1.0,
	"skin_color": Color(0.55, 0.28, 0.12),
	"leg_color": Color(0.45, 0.22, 0.08),
	"is_muscular": true,
	"has_tail": true,
	"has_marks": true,
	"weapon": "mace"
}

const SPEC_MONKEY = {
	"torso_scale": 0.9,
	"head_pos": Vector3(0, 1.8, 0),
	"arm_pos_x": 0.9,
	"arm_pos_y": 1.2,
	"leg_pos_x": 0.38,
	"leg_pos_y": -0.9,
	"skin_color": Color(0.6, 0.3, 0.12),
	"leg_color": Color(0.5, 0.25, 0.1),
	"is_muscular": true,
	"has_tail": true,
	"weapon": null
}

# Material presets
const MAT_SKIN_ROUGH = 0.6
const MAT_SKIN_SMOOTH = 0.5
const MAT_METAL_SHINY = 0.8
const MAT_METAL_ROUGH = 0.2
const MAT_LEATHER_ROUGH = 0.7

static func build_rama_professional(character: Node3D) -> void:
	_build_character(character, SPEC_RAMA)

static func build_hanuman_professional(character: Node3D) -> void:
	_build_character(character, SPEC_HANUMAN)

static func build_monkey_professional(character: Node3D) -> void:
	_build_character(character, SPEC_MONKEY)

static func _build_character(character: Node3D, spec: Dictionary) -> void:
	var model = character.get_node_or_null("Model")
	if not model:
		return

	_clear_character(model)

	# Build body
	var torso = _create_body_part(
		"torso",
		spec["is_muscular"],
		spec["skin_color"],
		spec["torso_scale"]
	)
	model.add_child(torso)

	var head = _create_head(
		spec["skin_light"] if spec.has("skin_light") else spec["skin_color"],
		spec["head_pos"],
		spec["is_muscular"]
	)
	model.add_child(head)

	# Limbs
	for side in [-1, 1]:
		var arm = _create_limb(
			"arm",
			spec["is_muscular"],
			spec["skin_color"],
			Vector3(side * spec["arm_pos_x"], spec["arm_pos_y"], 0)
		)
		model.add_child(arm)

		var leg = _create_limb(
			"leg",
			spec["is_muscular"],
			spec["leg_color"],
			Vector3(side * spec["leg_pos_x"], spec["leg_pos_y"], 0)
		)
		model.add_child(leg)

	# Accessories
	if spec.has("has_armor") and spec["has_armor"]:
		_add_armor(model, spec["skin_color"])
		_add_belt(model)
		_add_cape(model)

	if spec.has("has_crown") and spec["has_crown"]:
		_add_crown(model)
		_add_hair_adornments(model)

	if spec.has("has_tail") and spec["has_tail"]:
		_add_tail(model, spec["skin_color"])

	if spec.has("has_marks") and spec["has_marks"]:
		_add_divine_marks(model)

	if spec.has("weapon") and spec["weapon"]:
		match spec["weapon"]:
			"sword":
				_add_sword(model)
			"mace":
				_add_mace(model)

	# Add detailed features (hair, makeup, embellishments)
	if spec.has("is_muscular") and spec["is_muscular"]:
		_add_monkey_hair(model)
		_add_primate_marks(model)
		_add_gauntlets(model, Color(0.3, 0.3, 0.3))
		_add_arm_bindings(model)
		_add_battle_scars(model)
		_add_leg_wraps(model, Color(0.7, 0.6, 0.4))
	else:
		_add_human_hair(model, spec["skin_color"])
		_add_facial_makeup(model)
		_add_eye_detail(model)
		_add_gauntlets(model, Color(0.4, 0.35, 0.3))
		if spec.has("has_crown") and spec["has_crown"]:
			_add_necklace(model)
			_add_shoulder_guards(model)
			_add_leg_armor(model)
			_add_chest_embellishment(model)

static func _create_body_part(part: String, muscular: bool, color: Color, scale: float) -> Node3D:
	if part == "torso":
		return _create_torso(muscular, color, scale)
	return Node3D.new()

static func _create_torso(muscular: bool, color: Color, scale: float) -> Node3D:
	var torso = Node3D.new()

	if muscular:
		# Pectoral muscles
		for i in range(2):
			var pec = _create_mesh_instance(
				SphereMesh.new(),
				color,
				MAT_SKIN_SMOOTH
			)
			pec.mesh.radius = 0.35 * scale
			pec.position = Vector3(sign(i - 0.5) * 0.5, 1.3, 0.15)
			pec.scale = Vector3(1.0, 1.2, 0.8)
			torso.add_child(pec)

	var main_mesh = _create_mesh_instance(
		BoxMesh.new(),
		color,
		MAT_SKIN_ROUGH
	)
	var size = Vector3(1.1 if muscular else 1.0, 1.5 if muscular else 1.4, 0.6 if muscular else 0.5)
	main_mesh.mesh.size = size * scale
	main_mesh.position.y = 1.0
	torso.add_child(main_mesh)

	# Collision
	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = size * scale
	collision.position.y = 1.0
	torso.add_child(collision)

	return torso

static func _create_head(color: Color, pos: Vector3, monkey: bool) -> Node3D:
	var head = Node3D.new()
	head.position = pos

	var skull = _create_mesh_instance(SphereMesh.new(), color, MAT_SKIN_SMOOTH)
	skull.mesh.radius = 0.4 if not monkey else 0.45
	head.add_child(skull)

	if monkey:
		_add_monkey_head_features(head)
	else:
		_add_human_head_features(head)

	return head

static func _add_human_head_features(head: Node3D) -> void:
	# Eyes
	for i in range(2):
		# White of eye
		var white = _create_mesh_instance(SphereMesh.new(), Color.WHITE, MAT_SKIN_SMOOTH)
		white.mesh.radius = 0.09
		white.position = Vector3(sign(i - 0.5) * 0.15, 0.1, 0.36)
		head.add_child(white)

		# Pupil
		var pupil = _create_mesh_instance(SphereMesh.new(), Color.BLACK, MAT_SKIN_SMOOTH)
		pupil.mesh.radius = 0.05
		pupil.position = Vector3(sign(i - 0.5) * 0.15, 0.1, 0.38)
		head.add_child(pupil)

		# Eyebrow
		var brow = _create_mesh_instance(BoxMesh.new(), Color(0.3, 0.15, 0.05), MAT_SKIN_SMOOTH)
		brow.mesh.size = Vector3(0.15, 0.05, 0.03)
		brow.position = Vector3(sign(i - 0.5) * 0.15, 0.25, 0.35)
		head.add_child(brow)

	# Nose bridge
	var nose = _create_mesh_instance(BoxMesh.new(), Color(0.65, 0.45, 0.3), MAT_SKIN_SMOOTH)
	nose.mesh.size = Vector3(0.1, 0.15, 0.08)
	nose.position = Vector3(0, -0.05, 0.38)
	head.add_child(nose)

	# Mouth line
	var mouth = _create_mesh_instance(BoxMesh.new(), Color(0.5, 0.25, 0.15), MAT_SKIN_SMOOTH)
	mouth.mesh.size = Vector3(0.2, 0.04, 0.02)
	mouth.position = Vector3(0, -0.2, 0.35)
	head.add_child(mouth)

static func _add_monkey_head_features(head: Node3D) -> void:
	# Ears
	for i in range(2):
		var ear = _create_mesh_instance(SphereMesh.new(), Color(0.4, 0.15, 0.05), MAT_SKIN_SMOOTH)
		ear.mesh.radius = 0.15
		ear.position = Vector3(sign(i - 0.5) * 0.35, 0.3, -0.2)
		head.add_child(ear)

	# Eyes
	for i in range(2):
		var white = _create_mesh_instance(SphereMesh.new(), Color.WHITE, MAT_SKIN_SMOOTH)
		white.mesh.radius = 0.12
		white.position = Vector3(sign(i - 0.5) * 0.18, 0.15, 0.4)
		head.add_child(white)

		var pupil = _create_mesh_instance(SphereMesh.new(), Color.BLACK, MAT_SKIN_SMOOTH)
		pupil.mesh.radius = 0.06
		pupil.position = Vector3(sign(i - 0.5) * 0.18, 0.15, 0.45)
		head.add_child(pupil)

static func _create_limb(limb: String, muscular: bool, color: Color, pos: Vector3) -> Node3D:
	var limb_node = Node3D.new()
	limb_node.position = pos

	if limb == "arm":
		_build_arm(limb_node, muscular, color)
	elif limb == "leg":
		_build_leg(limb_node, muscular, color)

	return limb_node

static func _build_arm(node: Node3D, muscular: bool, color: Color) -> void:
	if muscular:
		var bicep = _create_mesh_instance(SphereMesh.new(), color, MAT_SKIN_SMOOTH)
		bicep.mesh.radius = 0.3
		bicep.position.y = 0.2
		bicep.scale = Vector3(1.0, 1.3, 0.8)
		node.add_child(bicep)

	var upper = _create_cylinder(color, 0.25 if muscular else 0.2, 0.9 if muscular else 0.8)
	upper.position.y = 0.0
	node.add_child(upper)

	var lower = _create_cylinder(color, 0.22 if muscular else 0.18, 0.85 if muscular else 0.75)
	lower.position.y = -(0.9 if muscular else 0.8)
	node.add_child(lower)

	var hand = _create_mesh_instance(SphereMesh.new(), Color(0.5, 0.25, 0.1), MAT_SKIN_SMOOTH)
	hand.mesh.radius = 0.18 if muscular else 0.15
	hand.position.y = -(1.8 if muscular else 1.6)
	node.add_child(hand)

static func _build_leg(node: Node3D, muscular: bool, color: Color) -> void:
	var thigh = _create_cylinder(color, 0.28 if muscular else 0.22, 1.0 if muscular else 0.9)
	thigh.position.y = 0.0
	node.add_child(thigh)

	var calf = _create_cylinder(color, 0.22 if muscular else 0.18, 0.9 if muscular else 0.85)
	calf.position.y = -(1.0 if muscular else 0.9)
	node.add_child(calf)

	var foot = _create_mesh_instance(BoxMesh.new(), color, MAT_SKIN_ROUGH)
	var foot_size = Vector3(0.28, 0.22, 0.45) if muscular else Vector3(0.25, 0.2, 0.4)
	foot.mesh.size = foot_size
	foot.position = Vector3(0, -(1.9 if muscular else 1.8), 0.1)
	node.add_child(foot)

static func _create_cylinder(color: Color, radius: float, height: float) -> MeshInstance3D:
	var cyl = _create_mesh_instance(CylinderMesh.new(), color, MAT_SKIN_ROUGH)
	cyl.mesh.radius = radius
	cyl.mesh.height = height
	return cyl

static func _create_mesh_instance(mesh: Mesh, color: Color, roughness: float) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	instance.set_surface_override_material(0, mat)
	return instance

static func _add_armor(model: Node3D, color: Color) -> void:
	var armor_color = Color(0.35, 0.35, 0.35)
	var trim_color = Color(0.8, 0.7, 0.5)

	# Main chest plate
	var chest = _create_mesh_instance(BoxMesh.new(), armor_color, MAT_METAL_ROUGH)
	chest.mesh.size = Vector3(1.15, 1.5, 0.3)
	chest.material_override.metallic = 0.8
	chest.position = Vector3(0, 1.0, 0.15)
	model.add_child(chest)

	# Gold trim on chest
	var chest_trim = _create_mesh_instance(BoxMesh.new(), trim_color, MAT_LEATHER_ROUGH)
	chest_trim.mesh.size = Vector3(1.2, 0.08, 0.02)
	chest_trim.position = Vector3(0, 1.0, 0.17)
	model.add_child(chest_trim)

	# Shoulder armor
	for side in [-1, 1]:
		var shoulder = _create_mesh_instance(SphereMesh.new(), armor_color, MAT_METAL_ROUGH)
		shoulder.mesh.radius = 0.3
		shoulder.material_override.metallic = 0.8
		shoulder.position = Vector3(side * 0.65, 1.5, 0)
		shoulder.scale = Vector3(1.2, 1.0, 1.0)
		model.add_child(shoulder)

		# Shoulder studs/rivets
		for j in range(3):
			var rivet = _create_mesh_instance(SphereMesh.new(), Color(0.2, 0.2, 0.2), 0.8)
			rivet.mesh.radius = 0.05
			rivet.position = Vector3(side * 0.65, 1.5 - j * 0.2, 0.12)
			model.add_child(rivet)

	# Armor straps
	for i in range(3):
		var strap = _create_mesh_instance(BoxMesh.new(), trim_color, MAT_LEATHER_ROUGH)
		strap.mesh.size = Vector3(1.0, 0.06, 0.02)
		strap.position = Vector3(0, 1.5 - i * 0.35, 0.17)
		model.add_child(strap)

static func _add_crown(model: Node3D) -> void:
	var crown = _create_mesh_instance(TorusMesh.new(), Color(1.0, 0.84, 0.0), MAT_METAL_ROUGH)
	crown.mesh.inner_radius = 0.35
	crown.mesh.outer_radius = 0.42
	crown.material_override.metallic = 0.95
	crown.position = Vector3(0, 2.1, 0)
	crown.scale = Vector3(1.0, 0.25, 1.0)
	model.add_child(crown)

	for i in range(7):
		var spike = _create_mesh_instance(CylinderMesh.new(), Color(1.0, 0.84, 0.0), MAT_METAL_ROUGH)
		spike.mesh.top_radius = 0.04
		spike.mesh.bottom_radius = 0.08
		spike.mesh.height = 0.5
		spike.material_override.metallic = 0.95
		var angle = (TAU / 7.0) * i
		spike.position = Vector3(cos(angle) * 0.4, 2.2, sin(angle) * 0.4)
		model.add_child(spike)

static func _add_tail(model: Node3D, color: Color) -> void:
	var tail = _create_mesh_instance(CylinderMesh.new(), Color(0.4, 0.2, 0.08), MAT_SKIN_ROUGH)
	tail.mesh.radius = 0.12
	tail.mesh.height = 2.0
	tail.position = Vector3(0, 0.3, -0.6)
	tail.rotation.z = 0.35
	model.add_child(tail)

static func _add_divine_marks(model: Node3D) -> void:
	for i in range(3):
		var mark = _create_mesh_instance(BoxMesh.new(), Color(1.0, 0.7, 0.0), MAT_SKIN_SMOOTH)
		mark.mesh.size = Vector3(0.08, 0.3, 0.02)
		mark.position = Vector3(0, 1.5 - i * 0.3, 0.4)
		model.add_child(mark)

static func _add_sword(model: Node3D) -> void:
	var holder = Node3D.new()
	holder.name = "Sword"
	model.add_child(holder)

	var blade_color = Color(0.75, 0.78, 0.8)
	var guard_color = Color(0.8, 0.7, 0.5)

	# Main blade
	var blade = _create_mesh_instance(BoxMesh.new(), blade_color, MAT_METAL_ROUGH)
	blade.mesh.size = Vector3(0.12, 2.5, 0.02)
	blade.material_override.metallic = 0.98
	blade.position = Vector3(1.0, 0.8, 0)
	holder.add_child(blade)

	# Blade edge highlight (sharper look)
	var edge = _create_mesh_instance(BoxMesh.new(), Color(0.9, 0.92, 0.95), 0.2)
	edge.mesh.size = Vector3(0.08, 2.5, 0.005)
	edge.material_override.metallic = 1.0
	edge.position = Vector3(1.0, 0.8, 0.013)
	holder.add_child(edge)

	# Crossguard (ornate)
	var guard = _create_mesh_instance(BoxMesh.new(), guard_color, MAT_LEATHER_ROUGH)
	guard.mesh.size = Vector3(0.5, 0.1, 0.08)
	guard.position = Vector3(1.0, 0.0, 0)
	holder.add_child(guard)

	# Guard decorative studs
	for i in range(3):
		var stud = _create_mesh_instance(SphereMesh.new(), Color(1.0, 0.84, 0.0), 0.9)
		stud.mesh.radius = 0.04
		stud.position = Vector3(1.0 + (i - 1) * 0.15, 0.0, 0.06)
		holder.add_child(stud)

	# Leather-wrapped hilt
	var hilt = _create_mesh_instance(CylinderMesh.new(), guard_color, MAT_LEATHER_ROUGH)
	hilt.mesh.radius = 0.08
	hilt.mesh.height = 0.4
	hilt.position = Vector3(1.0, -0.3, 0)
	holder.add_child(hilt)

	# Wrapping pattern on hilt
	for i in range(4):
		var wrap = _create_mesh_instance(BoxMesh.new(), Color(0.6, 0.5, 0.3), 0.8)
		wrap.mesh.size = Vector3(0.18, 0.05, 0.01)
		wrap.position = Vector3(1.0, -0.2 + i * 0.1, 0.08)
		holder.add_child(wrap)

	# Pommel (ornate sphere)
	var pommel = _create_mesh_instance(SphereMesh.new(), Color(1.0, 0.84, 0.0), 0.9)
	pommel.mesh.radius = 0.1
	pommel.position = Vector3(1.0, -0.6, 0)
	holder.add_child(pommel)

	# Pommel rim
	var pommel_rim = _create_mesh_instance(TorusMesh.new(), Color(0.8, 0.7, 0.5), MAT_LEATHER_ROUGH)
	pommel_rim.mesh.inner_radius = 0.08
	pommel_rim.mesh.outer_radius = 0.12
	pommel_rim.position = Vector3(1.0, -0.6, 0)
	holder.add_child(pommel_rim)

static func _add_mace(model: Node3D) -> void:
	var holder = Node3D.new()
	holder.name = "Mace"
	model.add_child(holder)

	var handle_color = Color(0.55, 0.4, 0.2)
	var trim_color = Color(0.8, 0.7, 0.5)
	var head_color = Color(0.45, 0.35, 0.2)

	# Main handle
	var handle = _create_mesh_instance(CylinderMesh.new(), handle_color, MAT_LEATHER_ROUGH)
	handle.mesh.radius = 0.12
	handle.mesh.height = 1.6
	handle.position = Vector3(-1.1, 0.5, 0)
	holder.add_child(handle)

	# Handle wrapping pattern (leather straps)
	for i in range(5):
		var wrap = _create_mesh_instance(BoxMesh.new(), trim_color, 0.8)
		wrap.mesh.size = Vector3(0.28, 0.05, 0.01)
		wrap.position = Vector3(-1.1, 1.3 - i * 0.25, 0.12)
		holder.add_child(wrap)

	# Guard/base ring at handle junction
	var guard = _create_mesh_instance(TorusMesh.new(), trim_color, MAT_LEATHER_ROUGH)
	guard.mesh.inner_radius = 0.1
	guard.mesh.outer_radius = 0.16
	guard.position = Vector3(-1.1, 1.55, 0)
	holder.add_child(guard)

	# Main mace head
	var head = _create_mesh_instance(SphereMesh.new(), head_color, MAT_METAL_ROUGH)
	head.mesh.radius = 0.4
	head.material_override.metallic = 0.7
	head.position = Vector3(-1.1, 2.0, 0)
	holder.add_child(head)

	# Decorative band on head (middle)
	var head_band = _create_mesh_instance(TorusMesh.new(), trim_color, MAT_METAL_ROUGH)
	head_band.mesh.inner_radius = 0.35
	head_band.mesh.outer_radius = 0.42
	head_band.position = Vector3(-1.1, 2.0, 0)
	holder.add_child(head_band)

	# Spikes - alternating heights for visual interest
	for i in range(12):
		var spike = _create_mesh_instance(CylinderMesh.new(), head_color, MAT_METAL_ROUGH)
		var height_variation = 0.25 if i % 2 == 0 else 0.3
		spike.mesh.top_radius = 0.02
		spike.mesh.bottom_radius = 0.1
		spike.mesh.height = height_variation
		spike.material_override.metallic = 0.7
		var angle = (TAU / 12.0) * i
		var radius = 0.32
		var z_offset = sin(angle) * radius * 0.5
		spike.position = Vector3(-1.1 + cos(angle) * radius, 2.0 + sin(angle) * radius * 0.7, z_offset)
		holder.add_child(spike)

	# Spike tips (ornamental)
	for i in range(12):
		if i % 2 == 0:
			var tip = _create_mesh_instance(SphereMesh.new(), Color(0.6, 0.5, 0.3), 0.9)
			tip.mesh.radius = 0.05
			var angle = (TAU / 12.0) * i
			var radius = 0.32
			var spike_height = 2.3
			tip.position = Vector3(-1.1 + cos(angle) * radius, spike_height, sin(angle) * radius * 0.5)
			holder.add_child(tip)

	# Top ornamental cap
	var cap = _create_mesh_instance(SphereMesh.new(), trim_color, 0.9)
	cap.mesh.radius = 0.12
	cap.position = Vector3(-1.1, 2.55, 0)
	holder.add_child(cap)

static func _add_human_hair(model: Node3D, base_skin: Color) -> void:
	# Hair color (darker than skin)
	var hair_color = Color(base_skin.r * 0.4, base_skin.g * 0.4, base_skin.b * 0.4)

	# Main hair mass (sphere)
	var hair_main = _create_mesh_instance(SphereMesh.new(), hair_color, 0.4)
	hair_main.mesh.radius = 0.45
	hair_main.position = Vector3(0, 2.2, 0)
	hair_main.scale = Vector3(1.0, 1.3, 0.9)
	model.add_child(hair_main)

	# Hair strands for texture (thin cylinders)
	for i in range(6):
		var strand = _create_mesh_instance(CylinderMesh.new(), hair_color, 0.5)
		strand.mesh.radius = 0.08
		strand.mesh.height = 0.6
		var angle = (TAU / 6.0) * i
		strand.position = Vector3(cos(angle) * 0.35, 2.3, sin(angle) * 0.35)
		strand.rotation.z = angle
		model.add_child(strand)

static func _add_monkey_hair(model: Node3D) -> void:
	var hair_color = Color(0.3, 0.15, 0.05)
	var highlight_color = Color(0.45, 0.25, 0.1)

	# Fur on chest
	var chest_fur = _create_mesh_instance(SphereMesh.new(), hair_color, 0.4)
	chest_fur.mesh.radius = 0.35
	chest_fur.position = Vector3(0, 1.3, 0.25)
	chest_fur.scale = Vector3(0.8, 1.0, 0.6)
	model.add_child(chest_fur)

	# Chest fur highlight (lighter shade)
	var chest_highlight = _create_mesh_instance(SphereMesh.new(), highlight_color, 0.5)
	chest_highlight.mesh.radius = 0.3
	chest_highlight.position = Vector3(0, 1.4, 0.3)
	chest_highlight.scale = Vector3(0.6, 0.7, 0.4)
	model.add_child(chest_highlight)

	# Back fur
	var back_fur = _create_mesh_instance(SphereMesh.new(), hair_color, 0.4)
	back_fur.mesh.radius = 0.3
	back_fur.position = Vector3(0, 1.2, -0.3)
	back_fur.scale = Vector3(0.7, 0.9, 0.5)
	model.add_child(back_fur)

	# Head hair (crown)
	var head_hair = _create_mesh_instance(SphereMesh.new(), hair_color, 0.4)
	head_hair.mesh.radius = 0.4
	head_hair.position = Vector3(0, 2.3, 0)
	head_hair.scale = Vector3(1.0, 1.2, 0.9)
	model.add_child(head_hair)

static func _add_primate_marks(model: Node3D) -> void:
	# Facial markings for Hanuman
	var mark_color = Color(1.0, 0.8, 0.0)

	# Forehead mark
	var forehead = _create_mesh_instance(BoxMesh.new(), mark_color, 0.7)
	forehead.mesh.size = Vector3(0.3, 0.15, 0.02)
	forehead.position = Vector3(0, 2.3, 0.42)
	model.add_child(forehead)

static func _add_facial_makeup(model: Node3D) -> void:
	# Bindi/tilaka (spiritual mark)
	var bindi = _create_mesh_instance(SphereMesh.new(), Color(1.0, 0.0, 0.0), 0.8)
	bindi.mesh.radius = 0.08
	bindi.position = Vector3(0, 2.25, 0.41)
	model.add_child(bindi)

static func _add_eye_detail(model: Node3D) -> void:
	# Eye shadow/definition for realism
	var shadow_color = Color(0.5, 0.4, 0.3)

	for i in range(2):
		# Under eye shadow
		var shadow = _create_mesh_instance(BoxMesh.new(), shadow_color, 0.6)
		shadow.mesh.size = Vector3(0.12, 0.04, 0.02)
		shadow.position = Vector3(sign(i - 0.5) * 0.15, 0.0, 0.38)
		model.add_child(shadow)

		# Eyelash definition
		var lash = _create_mesh_instance(BoxMesh.new(), Color.BLACK, 0.7)
		lash.mesh.size = Vector3(0.13, 0.02, 0.01)
		lash.position = Vector3(sign(i - 0.5) * 0.15, 0.14, 0.36)
		model.add_child(lash)

static func _add_gauntlets(model: Node3D, color: Color) -> void:
	# Gauntlets/bracers on both wrists for protection
	for side in [-1, 1]:
		# Main gauntlet
		var gauntlet = _create_mesh_instance(BoxMesh.new(), color, MAT_METAL_ROUGH)
		gauntlet.mesh.size = Vector3(0.3, 0.25, 0.2)
		gauntlet.material_override.metallic = 0.7
		gauntlet.position = Vector3(side * 0.8, -1.7, 0)
		model.add_child(gauntlet)

		# Decorative rivets on gauntlet (3 rows)
		for row in range(3):
			var rivet = _create_mesh_instance(SphereMesh.new(), Color(0.2, 0.2, 0.2), 0.8)
			rivet.mesh.radius = 0.04
			rivet.position = Vector3(side * 0.8, -1.5 - row * 0.1, 0.12)
			model.add_child(rivet)

static func _add_necklace(model: Node3D) -> void:
	# Spiritual necklace for Rama
	var necklace_color = Color(1.0, 0.84, 0.0)

	# Main necklace chain
	var chain = _create_mesh_instance(TorusMesh.new(), necklace_color, 0.9)
	chain.mesh.inner_radius = 0.4
	chain.mesh.outer_radius = 0.45
	chain.position = Vector3(0, 1.3, 0)
	model.add_child(chain)

	# Pendant (sacred jewel)
	var pendant = _create_mesh_instance(SphereMesh.new(), Color(1.0, 0.0, 0.0), 0.9)
	pendant.mesh.radius = 0.08
	pendant.position = Vector3(0, 0.95, 0.25)
	model.add_child(pendant)

	# Pendant shine/highlight
	var shine = _create_mesh_instance(SphereMesh.new(), Color(1.0, 0.5, 0.5), 0.85)
	shine.mesh.radius = 0.04
	shine.position = Vector3(0.05, 0.98, 0.28)
	model.add_child(shine)

static func _add_arm_bindings(model: Node3D) -> void:
	# Rope/cloth bindings on Hanuman's arms for warrior appearance
	var binding_color = Color(0.7, 0.6, 0.4)

	for side in [-1, 1]:
		# Spiral wrappings on arms
		for wrap in range(4):
			var binding = _create_mesh_instance(BoxMesh.new(), binding_color, 0.7)
			binding.mesh.size = Vector3(0.5, 0.08, 0.02)
			binding.position = Vector3(side * 0.8, 0.5 - wrap * 0.25, 0.2)
			model.add_child(binding)

static func _add_battle_scars(model: Node3D) -> void:
	# Battle scarification on chest and shoulders
	var scar_color = Color(0.3, 0.2, 0.1)

	# Chest scars (3 diagonal lines)
	for i in range(3):
		var scar = _create_mesh_instance(BoxMesh.new(), scar_color, 0.8)
		scar.mesh.size = Vector3(0.08, 0.4, 0.01)
		scar.position = Vector3(-0.15 + i * 0.15, 1.2, 0.3)
		scar.rotation.z = 0.3
		model.add_child(scar)

	# Arm scars (wrapped pattern)
	for side in [-1, 1]:
		for wrap in range(3):
			var scar = _create_mesh_instance(BoxMesh.new(), scar_color, 0.8)
			scar.mesh.size = Vector3(0.5, 0.03, 0.01)
			scar.position = Vector3(side * 0.8, 0.8 - wrap * 0.3, 0.22)
			model.add_child(scar)

static func _add_leg_wraps(model: Node3D, color: Color) -> void:
	# Warrior leg wraps/bindings
	for side in [-1, 1]:
		for wrap in range(5):
			var leg_wrap = _create_mesh_instance(BoxMesh.new(), color, 0.7)
			leg_wrap.mesh.size = Vector3(0.5, 0.06, 0.02)
			leg_wrap.position = Vector3(side * 0.4, -0.8 - wrap * 0.25, 0.15)
			model.add_child(leg_wrap)

static func _add_shoulder_guards(model: Node3D) -> void:
	# Additional shoulder protection for Rama
	var guard_color = Color(0.35, 0.35, 0.35)
	var trim_color = Color(0.8, 0.7, 0.5)

	for side in [-1, 1]:
		# Extended shoulder plate
		var plate = _create_mesh_instance(BoxMesh.new(), guard_color, MAT_METAL_ROUGH)
		plate.mesh.size = Vector3(0.4, 0.3, 0.15)
		plate.material_override.metallic = 0.8
		plate.position = Vector3(side * 0.7, 1.5, 0.1)
		model.add_child(plate)

		# Shoulder trim
		var trim = _create_mesh_instance(BoxMesh.new(), trim_color, MAT_LEATHER_ROUGH)
		trim.mesh.size = Vector3(0.42, 0.06, 0.02)
		trim.position = Vector3(side * 0.7, 1.35, 0.16)
		model.add_child(trim)

static func _add_leg_armor(model: Node3D) -> void:
	# Greaves/leg plates for Rama
	var armor_color = Color(0.35, 0.35, 0.35)
	var trim_color = Color(0.8, 0.7, 0.5)

	for side in [-1, 1]:
		# Main greave
		var greave = _create_mesh_instance(BoxMesh.new(), armor_color, MAT_METAL_ROUGH)
		greave.mesh.size = Vector3(0.3, 0.6, 0.12)
		greave.material_override.metallic = 0.7
		greave.position = Vector3(side * 0.35, -1.2, 0.1)
		model.add_child(greave)

		# Greave trim bands
		for band in range(2):
			var trim = _create_mesh_instance(BoxMesh.new(), trim_color, MAT_LEATHER_ROUGH)
			trim.mesh.size = Vector3(0.35, 0.06, 0.02)
			trim.position = Vector3(side * 0.35, -1.4 + band * 0.5, 0.15)
			model.add_child(trim)

static func _add_chest_embellishment(model: Node3D) -> void:
	# Sacred emblem on chest for Rama
	var emblem_color = Color(1.0, 0.84, 0.0)

	# Central jewel
	var jewel = _create_mesh_instance(SphereMesh.new(), emblem_color, 0.9)
	jewel.mesh.radius = 0.1
	jewel.position = Vector3(0, 1.0, 0.3)
	model.add_child(jewel)

	# Radial lines from jewel
	for i in range(4):
		var line = _create_mesh_instance(BoxMesh.new(), emblem_color, 0.8)
		line.mesh.size = Vector3(0.08, 0.25, 0.02)
		var angle = (TAU / 4.0) * i
		line.position = Vector3(cos(angle) * 0.2, 0.8, sin(angle) * 0.2)
		line.rotation.z = angle
		model.add_child(line)

static func _add_belt(model: Node3D) -> void:
	# Ornate belt at waist
	var belt_color = Color(0.4, 0.35, 0.25)
	var buckle_color = Color(1.0, 0.84, 0.0)

	# Main belt
	var belt = _create_mesh_instance(BoxMesh.new(), belt_color, MAT_LEATHER_ROUGH)
	belt.mesh.size = Vector3(1.2, 0.12, 0.04)
	belt.position = Vector3(0, 0.6, 0.15)
	model.add_child(belt)

	# Ornate buckle
	var buckle = _create_mesh_instance(BoxMesh.new(), buckle_color, 0.9)
	buckle.mesh.size = Vector3(0.2, 0.15, 0.05)
	buckle.position = Vector3(0, 0.6, 0.2)
	model.add_child(buckle)

	# Buckle gem
	var gem = _create_mesh_instance(SphereMesh.new(), Color(1.0, 0.0, 0.0), 0.9)
	gem.mesh.radius = 0.05
	gem.position = Vector3(0, 0.6, 0.28)
	model.add_child(gem)

static func _add_cape(model: Node3D) -> void:
	# Royal cape for Rama
	var cape_color = Color(0.5, 0.1, 0.1)

	# Left cape
	var cape_left = _create_mesh_instance(BoxMesh.new(), cape_color, 0.4)
	cape_left.mesh.size = Vector3(0.8, 1.5, 0.05)
	cape_left.position = Vector3(-0.6, 0.5, -0.4)
	cape_left.rotation.z = 0.2
	model.add_child(cape_left)

	# Right cape
	var cape_right = _create_mesh_instance(BoxMesh.new(), cape_color, 0.4)
	cape_right.mesh.size = Vector3(0.8, 1.5, 0.05)
	cape_right.position = Vector3(0.6, 0.5, -0.4)
	cape_right.rotation.z = -0.2
	model.add_child(cape_right)

	# Cape trim (gold)
	var trim_color = Color(1.0, 0.84, 0.0)
	for side in [-1, 1]:
		var trim = _create_mesh_instance(BoxMesh.new(), trim_color, 0.8)
		trim.mesh.size = Vector3(0.8, 0.08, 0.02)
		trim.position = Vector3(side * 0.6, 1.8, -0.38)
		model.add_child(trim)

static func _add_hair_adornments(model: Node3D) -> void:
	# Decorative beads and adornments in hair
	var bead_color = Color(1.0, 0.84, 0.0)

	# Beads woven into hair (scattered placement)
	var positions = [
		Vector3(-0.25, 2.5, 0.2),
		Vector3(0.25, 2.5, 0.2),
		Vector3(-0.1, 2.6, 0.35),
		Vector3(0.1, 2.6, 0.35),
		Vector3(0, 2.4, -0.1)
	]

	for pos in positions:
		var bead = _create_mesh_instance(SphereMesh.new(), bead_color, 0.9)
		bead.mesh.radius = 0.04
		bead.position = pos
		model.add_child(bead)

static func _clear_character(model: Node3D) -> void:
	for child in model.get_children():
		if child.name != "AnimationPlayer":
			child.queue_free()
