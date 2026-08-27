extends Node3D

class_name Chapter4OceanManager

var rama: RamaController
var hanuman: HanumanAI
var monkey_team: Array = []
var bridge_built: bool = false
var ocean_crossed: bool = false

signal ocean_crossing_complete

func _ready() -> void:
	rama = $Characters/Rama
	hanuman = $Characters/Hanuman
	_create_environment()
	setup_ocean_scene()

func setup_ocean_scene() -> void:
	_show_message("🌊 CHAPTER 4: THE OCEAN CROSSING\n\nWe've reached the ocean separating us from Lanka...")
	await get_tree().create_timer(2.0).timeout

	_show_message("🐵 Hanuman: The ocean is vast. We must cross it to reach Ravana's fortress.")
	await get_tree().create_timer(2.5).timeout

	_show_message("🟦 Rama: How will we build a bridge across this great expanse?")
	await get_tree().create_timer(2.0).timeout

	_show_message("🐵 Hanuman: With the strength of our united army, we shall move mountains!")
	await get_tree().create_timer(2.5).timeout

	_initiate_bridge_building()

func _initiate_bridge_building() -> void:
	_show_message("🐵 Hanuman: I will demonstrate my power first...")
	await get_tree().create_timer(1.5).timeout

	_show_message("💨 Hanuman leaps across the ocean in a single bound!")
	await get_tree().create_timer(3.0).timeout

	_show_message("🐵 Hanuman: Now, monkeys! Build the bridge!")
	await get_tree().create_timer(2.0).timeout

	bridge_built = true
	_show_message("🌉 A great bridge of stones materializes across the ocean!")
	await get_tree().create_timer(2.5).timeout

	_cross_ocean()

func _cross_ocean() -> void:
	_show_message("📍 The army marches across the bridge toward Lanka...")
	await get_tree().create_timer(3.0).timeout

	ocean_crossed = true
	_show_message("✅ We have reached Lanka! Ravana's fortress awaits...")
	await get_tree().create_timer(2.0).timeout

	ocean_crossing_complete.emit()

func get_ocean_progress() -> float:
	if ocean_crossed:
		return 1.0
	elif bridge_built:
		return 0.66
	else:
		return 0.33

func _show_message(text: String) -> void:
	print(text)

func _create_environment() -> void:
	if has_node("Environment"):
		get_node("Environment").queue_free()
	var env = Node3D.new()
	env.name = "Environment"
	add_child(env)
	EnvironmentBuilder.create_ocean_environment(env)
	LightingSetup.setup_ocean_lighting(env)

func create_ocean_environment() -> void:
	var water = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(500, 500)
	water.mesh = plane_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.8, 0.7)
	mat.roughness = 0.1
	water.material_override = mat

	water.global_position = Vector3(0, -5, 0)
	add_child(water)
