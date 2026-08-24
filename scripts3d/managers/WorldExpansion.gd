extends Node3D

class_name WorldExpansion

@export var world_width: float = 1200.0
@export var world_height: float = 1200.0
@export var trees_per_zone: int = 12
@export var rocks_per_zone: int = 8
@export var items_per_zone: int = 15

@onready var forest: Node3D = $Forest
@onready var items: Node3D = $Items
@onready var rocks: Node3D = $Rocks

var fruit_scene = preload("res://scenes3d/items/fruit_mango_3d.tscn")

func _ready() -> void:
	generate_world()

func generate_world() -> void:
	_generate_forest_zones()
	_generate_rock_formations()
	_generate_item_clusters()

func _generate_forest_zones() -> void:
	var num_zones = 4
	var zone_width = world_width / 2.0
	var zone_height = world_height / 2.0

	for zone_x in range(2):
		for zone_z in range(2):
			var zone_center_x = (zone_x - 0.5) * zone_width
			var zone_center_z = (zone_z - 0.5) * zone_height

			for i in range(trees_per_zone):
				var rand_x = zone_center_x + randf_range(-zone_width * 0.4, zone_width * 0.4)
				var rand_z = zone_center_z + randf_range(-zone_height * 0.4, zone_height * 0.4)
				_create_tree(Vector3(rand_x, 0, rand_z))

func _create_tree(position: Vector3) -> void:
	var tree = Node3D.new()
	tree.name = "Tree_%d" % hash(position)
	tree.global_position = position

	var trunk = MeshInstance3D.new()
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.radius = 1.0
	trunk_mesh.height = 25.0
	trunk.mesh = trunk_mesh
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.35, 0.25, 0.1, 1)
	trunk_mat.roughness = 1.0
	trunk.material_override = trunk_mat
	tree.add_child(trunk)

	var foliage = MeshInstance3D.new()
	foliage.global_position = position + Vector3(0, 8, 0)
	var foliage_mesh = SphereMesh.new()
	foliage_mesh.radius = 10.0
	foliage.mesh = foliage_mesh
	var foliage_mat = StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.15, 0.4, 0.1, 1)
	foliage_mat.roughness = 0.9
	foliage.material_override = foliage_mat
	tree.add_child(foliage)

	var collider = StaticBody3D.new()
	collider.global_position = position
	var collision_shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 1.0
	capsule.height = 25.0
	collision_shape.shape = capsule
	collider.add_child(collision_shape)
	tree.add_child(collider)

	forest.add_child(tree)

func _generate_rock_formations() -> void:
	var num_zones = 4
	var zone_width = world_width / 2.0
	var zone_height = world_height / 2.0

	for zone_x in range(2):
		for zone_z in range(2):
			var zone_center_x = (zone_x - 0.5) * zone_width
			var zone_center_z = (zone_z - 0.5) * zone_height

			for i in range(rocks_per_zone):
				var rand_x = zone_center_x + randf_range(-zone_width * 0.4, zone_width * 0.4)
				var rand_z = zone_center_z + randf_range(-zone_height * 0.4, zone_height * 0.4)
				_create_rock(Vector3(rand_x, 1, rand_z))

func _create_rock(position: Vector3) -> void:
	var rock = MeshInstance3D.new()
	rock.name = "Rock_%d" % hash(position)
	rock.global_position = position

	var rock_mesh = BoxMesh.new()
	rock_mesh.size = Vector3(randf_range(4, 12), randf_range(2, 6), randf_range(4, 12))
	rock.mesh = rock_mesh

	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.5, 0.45, 0.4, 1)
	rock_mat.roughness = 1.0
	rock.material_override = rock_mat

	var collider = StaticBody3D.new()
	collider.global_position = position
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = rock_mesh.size
	collision_shape.shape = shape
	collider.add_child(collision_shape)
	rock.add_child(collider)

	rocks.add_child(rock)

func _generate_item_clusters() -> void:
	var num_zones = 4
	var zone_width = world_width / 2.0
	var zone_height = world_height / 2.0

	for zone_x in range(2):
		for zone_z in range(2):
			var zone_center_x = (zone_x - 0.5) * zone_width
			var zone_center_z = (zone_z - 0.5) * zone_height

			for i in range(items_per_zone):
				var rand_x = zone_center_x + randf_range(-zone_width * 0.4, zone_width * 0.4)
				var rand_z = zone_center_z + randf_range(-zone_height * 0.4, zone_height * 0.4)
				_spawn_fruit(Vector3(rand_x, 0.5, rand_z))

func _spawn_fruit(position: Vector3) -> void:
	var fruit = fruit_scene.instantiate()
	fruit.global_position = position
	items.add_child(fruit)
