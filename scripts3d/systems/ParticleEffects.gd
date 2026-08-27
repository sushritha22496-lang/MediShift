extends Node3D

class_name ParticleEffects

static func spawn_dust_effect(position: Vector3, parent: Node3D) -> void:
	var particles = GPUParticles3D.new()
	particles.position = position
	particles.emitting = true
	particles.amount = 30
	particles.lifetime = 1.5

	var process_mat = ParticleProcessMaterial.new()
	process_mat.initial_velocity_min = 2.0
	process_mat.initial_velocity_max = 5.0
	process_mat.gravity = Vector3(0, -5, 0)
	process_mat.scale_min = 0.5
	process_mat.scale_max = 2.0
	particles.process_material = process_mat

	var mesh = SphereMesh.new()
	mesh.radius = 0.2
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.6, 0.5)
	mesh_inst.set_surface_override_material(0, mat)
	particles.add_child(mesh_inst)

	parent.add_child(particles)
	await get_tree().create_timer(2.0).timeout
	particles.queue_free()

static func spawn_hit_effect(position: Vector3, parent: Node3D, color: Color = Color.RED) -> void:
	var particles = GPUParticles3D.new()
	particles.position = position
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 1.0

	var process_mat = ParticleProcessMaterial.new()
	process_mat.initial_velocity_min = 3.0
	process_mat.initial_velocity_max = 8.0
	process_mat.gravity = Vector3(0, -10, 0)
	process_mat.scale_min = 0.3
	process_mat.scale_max = 0.8
	particles.process_material = process_mat

	parent.add_child(particles)
	await get_tree().create_timer(1.5).timeout
	particles.queue_free()

static func spawn_victory_flash(position: Vector3, parent: Node3D) -> void:
	var light = OmniLight3D.new()
	light.position = position
	light.energy_multiplier = 3.0
	light.omni_range = 20
	light.light_color = Color.YELLOW
	parent.add_child(light)

	var tween = parent.create_tween()
	tween.tween_property(light, "energy_multiplier", 0.0, 0.5)
	await tween.finished
	light.queue_free()

static func spawn_damage_numbers(damage: int, position: Vector3, parent: Node3D) -> void:
	var label = Label3D.new()
	label.text = str(damage)
	label.position = position
	label.scale = Vector3(2, 2, 2)
	parent.add_child(label)

	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", position + Vector3(0, 3, 0), 1.0)
	tween.tween_property(label, "modulate", Color.TRANSPARENT, 0.8)
	await tween.finished
	label.queue_free()
