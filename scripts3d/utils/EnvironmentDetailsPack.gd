extends Node3D

class_name EnvironmentDetailsPack

static func add_forest_details(root: Node3D) -> void:
	_add_rocks(root, 20, Vector2(100, 100), 1.0, 2.5)
	_add_shrubs(root, 30, Vector2(100, 100), 0.8, 1.5)
	_add_mushroom_clusters(root, 15, Vector2(100, 100))
	_add_fallen_logs(root, 10, Vector2(100, 100))

static func add_coast_details(root: Node3D) -> void:
	_add_rocks(root, 15, Vector2(80, 80), 1.5, 3.5)
	_add_driftwood(root, 8, Vector2(80, 80))
	_add_shells(root, 20, Vector2(80, 80))
	_add_tide_pools(root, 5, Vector2(80, 80))

static func add_fortress_details(root: Node3D) -> void:
	_add_flags(root, 4, Vector3(0, 25, 0))
	_add_barrels(root, 8, Vector3(0, 0, 0), Vector2(50, 50))
	_add_torches(root, 12, Vector3(0, 10, 0))
	_add_rubble(root, 15, Vector2(100, 100))

static func _add_rocks(root: Node3D, count: int, area: Vector2, min_scale: float, max_scale: float) -> void:
	for i in range(count):
		var rock = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		rock.mesh = sphere
		var scale_factor = randf_range(min_scale, max_scale)
		rock.scale = Vector3(scale_factor, scale_factor * 0.7, scale_factor)

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(randf_range(0.4, 0.6), randf_range(0.3, 0.5), randf_range(0.2, 0.4))
		mat.roughness = 0.9
		rock.set_surface_override_material(0, mat)

		rock.position = Vector3(randf_range(-area.x / 2, area.x / 2), 0.5 * scale_factor, randf_range(-area.y / 2, area.y / 2))

		var collision = CollisionShape3D.new()
		var collision_shape = SphereShape3D.new()
		collision_shape.radius = scale_factor
		collision.shape = collision_shape
		rock.add_child(collision)

		root.add_child(rock)

static func _add_shrubs(root: Node3D, count: int, area: Vector2, min_size: float, max_size: float) -> void:
	for i in range(count):
		var shrub = Node3D.new()
		var size = randf_range(min_size, max_size)

		var foliage = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = size
		foliage.mesh = sphere
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(randf_range(0.2, 0.4), randf_range(0.5, 0.7), randf_range(0.1, 0.3))
		foliage.set_surface_override_material(0, mat)
		shrub.add_child(foliage)

		shrub.position = Vector3(randf_range(-area.x / 2, area.x / 2), size * 0.5, randf_range(-area.y / 2, area.y / 2))
		root.add_child(shrub)

static func _add_mushroom_clusters(root: Node3D, count: int, area: Vector2) -> void:
	for i in range(count):
		var cluster = Node3D.new()
		for j in range(randi_range(3, 8)):
			var mushroom = MeshInstance3D.new()
			var cone = CylinderMesh.new()
			cone.top_radius = 0.15
			cone.bottom_radius = 0.1
			cone.height = 0.3
			mushroom.mesh = cone

			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(randf_range(0.7, 0.9), randf_range(0.2, 0.4), randf_range(0.1, 0.3))
			mushroom.set_surface_override_material(0, mat)
			mushroom.position = Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
			cluster.add_child(mushroom)

		cluster.position = Vector3(randf_range(-area.x / 2, area.x / 2), 0, randf_range(-area.y / 2, area.y / 2))
		root.add_child(cluster)

static func _add_fallen_logs(root: Node3D, count: int, area: Vector2) -> void:
	for i in range(count):
		var log = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.radius = 0.3
		cyl.height = randf_range(3.0, 8.0)
		log.mesh = cyl

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.25, 0.1)
		mat.roughness = 0.95
		log.set_surface_override_material(0, mat)

		log.position = Vector3(randf_range(-area.x / 2, area.x / 2), 0.2, randf_range(-area.y / 2, area.y / 2))
		log.rotation = Vector3(randf_range(-PI / 4, PI / 4), randf_range(-PI, PI), 0)
		root.add_child(log)

static func _add_driftwood(root: Node3D, count: int, area: Vector2) -> void:
	for i in range(count):
		var wood = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(randf_range(0.3, 0.8), 0.15, randf_range(1.5, 4.0))
		wood.mesh = box

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.45, 0.38, 0.25)
		mat.roughness = 0.8
		wood.set_surface_override_material(0, mat)

		wood.position = Vector3(randf_range(-area.x / 2, area.x / 2), 0.1, randf_range(-area.y / 2, area.y / 2))
		wood.rotation = Vector3(randf_range(-PI / 6, PI / 6), randf_range(-PI, PI), 0)
		root.add_child(wood)

static func _add_shells(root: Node3D, count: int, area: Vector2) -> void:
	for i in range(count):
		var shell = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		shell.mesh = sphere
		shell.scale = Vector3(1.0, 0.3, 0.8)

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(randf_range(0.7, 0.9), randf_range(0.65, 0.85), randf_range(0.55, 0.75))
		mat.metallic = 0.2
		shell.set_surface_override_material(0, mat)

		shell.position = Vector3(randf_range(-area.x / 2, area.x / 2), 0.05, randf_range(-area.y / 2, area.y / 2))
		root.add_child(shell)

static func _add_tide_pools(root: Node3D, count: int, area: Vector2) -> void:
	for i in range(count):
		var pool = MeshInstance3D.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(randf_range(2.0, 5.0), randf_range(2.0, 5.0))
		pool.mesh = plane

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.35, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.alpha_scissor_threshold = 0.5
		pool.set_surface_override_material(0, mat)

		pool.position = Vector3(randf_range(-area.x / 2, area.x / 2), 0.02, randf_range(-area.y / 2, area.y / 2))
		root.add_child(pool)

static func _add_flags(root: Node3D, count: int, base_pos: Vector3) -> void:
	for i in range(count):
		var flag_pole = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.radius = 0.1
		cyl.height = 10.0
		flag_pole.mesh = cyl

		var pole_mat = StandardMaterial3D.new()
		pole_mat.albedo_color = Color(0.3, 0.3, 0.3)
		flag_pole.set_surface_override_material(0, pole_mat)

		flag_pole.position = base_pos + Vector3((i % 2) * 30 - 15, 0, (i / 2) * 30 - 15)
		root.add_child(flag_pole)

		var flag = MeshInstance3D.new()
		var flag_box = BoxMesh.new()
		flag_box.size = Vector3(2.0, 1.5, 0.1)
		flag.mesh = flag_box

		var flag_mat = StandardMaterial3D.new()
		flag_mat.albedo_color = Color(randf_range(0.8, 1.0), randf_range(0.1, 0.3), randf_range(0.1, 0.3))
		flag.set_surface_override_material(0, flag_mat)
		flag.position = base_pos + Vector3((i % 2) * 30 - 15, 5.0, (i / 2) * 30 - 15)
		root.add_child(flag)

static func _add_barrels(root: Node3D, count: int, base_pos: Vector3, area: Vector2) -> void:
	for i in range(count):
		var barrel = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.radius = 0.5
		cyl.height = 1.2
		barrel.mesh = cyl

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.3, 0.15)
		barrel.set_surface_override_material(0, mat)

		barrel.position = base_pos + Vector3(randf_range(-area.x / 2, area.x / 2), 0.6, randf_range(-area.y / 2, area.y / 2))
		root.add_child(barrel)

static func _add_torches(root: Node3D, count: int, base_pos: Vector3) -> void:
	for i in range(count):
		var torch = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.radius = 0.1
		cyl.height = 3.0
		torch.mesh = cyl

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.2, 0.1)
		torch.set_surface_override_material(0, mat)

		var angle = (TAU / count) * i
		torch.position = base_pos + Vector3(cos(angle) * 20, 1.5, sin(angle) * 20)
		root.add_child(torch)

		var light = OmniLight3D.new()
		light.position = torch.position + Vector3(0, 2.5, 0)
		light.energy_multiplier = 1.5
		light.omni_range = 15
		light.light_color = Color(1.0, 0.6, 0.2)
		root.add_child(light)

static func _add_rubble(root: Node3D, count: int, area: Vector2) -> void:
	for i in range(count):
		var rubble = MeshInstance3D.new()
		var box = BoxMesh.new()
		var size = randf_range(0.5, 2.0)
		box.size = Vector3(size, size * 0.6, size * 0.8)
		rubble.mesh = box

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(randf_range(0.3, 0.5), randf_range(0.25, 0.45), randf_range(0.2, 0.4))
		rubble.set_surface_override_material(0, mat)

		rubble.position = Vector3(randf_range(-area.x / 2, area.x / 2), size * 0.3, randf_range(-area.y / 2, area.y / 2))
		rubble.rotation = Vector3(randf_range(-PI / 4, PI / 4), randf_range(-PI, PI), randf_range(-PI / 4, PI / 4))
		root.add_child(rubble)
