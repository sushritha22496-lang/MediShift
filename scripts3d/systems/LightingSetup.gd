extends Node3D

class_name LightingSetup

static func setup_forest_lighting(root: Node3D) -> void:
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 45, 0)
	sun.energy_multiplier = 1.2
	sun.shadow_enabled = true
	root.add_child(sun)

	var ambient_light = WorldEnvironment.new()
	var environment = Environment.new()
	environment.ambient_light_enabled = true
	environment.ambient_light_source = Environment.AMBIENT_LIGHT_SKY
	environment.ambient_light_energy = 0.7
	environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_material = StandardMaterial3D.new()
	sky_material.albedo_color = Color(0.5, 0.7, 1.0)
	sky.material = sky_material
	environment.sky = sky
	ambient_light.environment = environment
	root.add_child(ambient_light)

static func setup_coast_lighting(root: Node3D) -> void:
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-60, 45, 0)
	sun.energy_multiplier = 1.5
	sun.shadow_enabled = true
	root.add_child(sun)

	var ambient = WorldEnvironment.new()
	var env = Environment.new()
	env.ambient_light_enabled = true
	env.ambient_light_energy = 1.0
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.7, 0.8, 1.0)
	ambient.environment = env
	root.add_child(ambient)

static func setup_ocean_lighting(root: Node3D) -> void:
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.energy_multiplier = 1.3
	sun.shadow_enabled = true
	root.add_child(sun)

	var fog = WorldEnvironment.new()
	var env = Environment.new()
	env.ambient_light_enabled = true
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_aerial_perspective = 0.1
	fog.environment = env
	root.add_child(fog)

static func setup_fortress_lighting(root: Node3D) -> void:
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-70, 90, 0)
	sun.energy_multiplier = 0.9
	sun.shadow_enabled = true
	root.add_child(sun)

	var torch1 = OmniLight3D.new()
	torch1.position = Vector3(20, 15, 20)
	torch1.energy_multiplier = 1.5
	torch1.omni_range = 30
	torch1.light_color = Color(1.0, 0.6, 0.2)
	root.add_child(torch1)

	var torch2 = OmniLight3D.new()
	torch2.position = Vector3(-20, 15, 20)
	torch2.energy_multiplier = 1.5
	torch2.omni_range = 30
	torch2.light_color = Color(1.0, 0.6, 0.2)
	root.add_child(torch2)

	var ambient = WorldEnvironment.new()
	var env = Environment.new()
	env.ambient_light_enabled = true
	env.ambient_light_energy = 0.5
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.05, 0.1)
	ambient.environment = env
	root.add_child(ambient)

static func setup_throne_lighting(root: Node3D) -> void:
	var throne_light = OmniLight3D.new()
	throne_light.position = Vector3(0, 20, 30)
	throne_light.energy_multiplier = 2.0
	throne_light.omni_range = 50
	throne_light.light_color = Color(1.0, 0.8, 0.4)
	root.add_child(throne_light)

	var ambient = OmniLight3D.new()
	ambient.position = Vector3(0, 10, 0)
	ambient.energy_multiplier = 0.6
	ambient.omni_range = 100
	ambient.light_color = Color(0.3, 0.2, 0.1)
	root.add_child(ambient)
