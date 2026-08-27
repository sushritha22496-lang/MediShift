extends Node3D

class_name EnvironmentBuilder

static func create_forest_environment(root: Node3D, theme: String = "dense") -> void:
	var tree_count = 50 if theme == "dense" else 25
	for i in range(tree_count):
		var pos = Vector3(randf_range(-200, 200), 0, randf_range(-200, 200))
		var tree = create_tree(pos, randf_range(0.8, 1.3))
		root.add_child(tree)

	var foliage = create_foliage_ground(root)
	root.add_child(foliage)

static func create_coast_environment(root: Node3D) -> void:
	var sand = create_sand_plane(50, 30)
	sand.position = Vector3(0, -0.1, 50)
	root.add_child(sand)

	var water = create_water(100, 100)
	water.position = Vector3(0, 0.5, 100)
	root.add_child(water)

	for i in range(15):
		var pos = Vector3(randf_range(-80, 80), 0, randf_range(-80, 0))
		var tree = create_tree(pos, randf_range(0.6, 0.9))
		root.add_child(tree)

static func create_ocean_environment(root: Node3D) -> void:
	var water = create_water(300, 300)
	water.position = Vector3(0, 0, 0)
	root.add_child(water)

	var islands = create_island_group(root)
	root.add_child(islands)

static func create_fortress_environment(root: Node3D) -> void:
	var fortress = create_fortress_structure()
	fortress.position = Vector3(0, 0, 0)
	root.add_child(fortress)

	var outer_wall = create_fortress_walls()
	outer_wall.position = Vector3(0, 0, 0)
	root.add_child(outer_wall)

static func create_tree(pos: Vector3, scale: float = 1.0) -> Node3D:
	var tree = Node3D.new()
	tree.position = pos

	var trunk = MeshInstance3D.new()
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.height = 15.0 * scale
	trunk_mesh.radius = 1.5 * scale
	trunk.mesh = trunk_mesh
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.2, 0.1)
	trunk.set_surface_override_material(0, trunk_mat)
	trunk.position.y = 7.5 * scale
	tree.add_child(trunk)

	var canopy = MeshInstance3D.new()
	var canopy_mesh = SphereMesh.new()
	canopy_mesh.radius = 6.0 * scale
	canopy.mesh = canopy_mesh
	var foliage_mat = StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.2, 0.6, 0.2)
	canopy.set_surface_override_material(0, foliage_mat)
	canopy.position = Vector3(0, 18.0 * scale, 0)
	tree.add_child(canopy)

	var collision = CollisionShape3D.new()
	collision.shape = CapsuleShape3D.new()
	collision.shape.radius = 1.5 * scale
	collision.shape.height = 15.0 * scale
	collision.position.y = 7.5 * scale
	tree.add_child(collision)

	return tree

static func create_foliage_ground(parent: Node3D) -> Node3D:
	var foliage = Node3D.new()

	var mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(600, 600)
	mesh.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.4, 0.1)
	mesh.set_surface_override_material(0, mat)
	mesh.position.y = -0.5
	foliage.add_child(mesh)

	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(600, 1, 600)
	collision.position.y = -0.5
	foliage.add_child(collision)

	return foliage

static func create_sand_plane(width: float, depth: float) -> Node3D:
	var sand = Node3D.new()

	var mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(width, depth)
	mesh.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.85, 0.6)
	mesh.set_surface_override_material(0, mat)
	sand.add_child(mesh)

	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(width, 1, depth)
	sand.add_child(collision)

	return sand

static func create_water(width: float, depth: float) -> Node3D:
	var water = Node3D.new()

	var mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(width, depth)
	mesh.mesh = plane
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.4, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.alpha_scissor_threshold = 0.5
	mesh.set_surface_override_material(0, mat)
	water.add_child(mesh)

	return water

static func create_island_group(parent: Node3D) -> Node3D:
	var islands = Node3D.new()

	for i in range(3):
		var pos = Vector3(randf_range(-150, 150), 0, randf_range(-150, 150))
		var island = create_sand_plane(40, 40)
		island.position = pos
		islands.add_child(island)

		for j in range(5):
			var tree = create_tree(pos + Vector3(randf_range(-15, 15), 0, randf_range(-15, 15)), 0.7)
			islands.add_child(tree)

	return islands

static func create_fortress_structure() -> Node3D:
	var fortress = Node3D.new()

	var main_tower = create_tower(Vector3(0, 0, 0), 30, 10)
	fortress.add_child(main_tower)

	var side_tower1 = create_tower(Vector3(25, 0, 0), 25, 8)
	fortress.add_child(side_tower1)

	var side_tower2 = create_tower(Vector3(-25, 0, 0), 25, 8)
	fortress.add_child(side_tower2)

	var main_building = create_building(Vector3(0, 0, 20), 20, 15, 15)
	fortress.add_child(main_building)

	return fortress

static func create_tower(pos: Vector3, height: float, radius: float) -> Node3D:
	var tower = Node3D.new()
	tower.position = pos

	var mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = height
	cylinder.radius = radius
	mesh.mesh = cylinder
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.4, 0.3)
	mesh.set_surface_override_material(0, mat)
	tower.add_child(mesh)

	var collision = CollisionShape3D.new()
	collision.shape = CylinderShape3D.new()
	collision.shape.height = height
	collision.shape.radius = radius
	tower.add_child(collision)

	return tower

static func create_building(pos: Vector3, width: float, height: float, depth: float) -> Node3D:
	var building = Node3D.new()
	building.position = pos

	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(width, height, depth)
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.4)
	mesh.set_surface_override_material(0, mat)
	building.add_child(mesh)

	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(width, height, depth)
	building.add_child(collision)

	return building

static func create_fortress_walls() -> Node3D:
	var walls = Node3D.new()

	var wall_north = create_wall(Vector3(0, 0, -40), 80, 15, 2)
	walls.add_child(wall_north)

	var wall_south = create_wall(Vector3(0, 0, 40), 80, 15, 2)
	walls.add_child(wall_south)

	var wall_east = create_wall(Vector3(40, 0, 0), 2, 15, 80)
	walls.add_child(wall_east)

	var wall_west = create_wall(Vector3(-40, 0, 0), 2, 15, 80)
	walls.add_child(wall_west)

	return walls

static func create_wall(pos: Vector3, width: float, height: float, depth: float) -> Node3D:
	var wall = Node3D.new()
	wall.position = pos

	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(width, height, depth)
	mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.2)
	mesh.set_surface_override_material(0, mat)
	wall.add_child(mesh)

	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(width, height, depth)
	wall.add_child(collision)

	return wall
