extends Node3D

class_name EffectsSystem

@export var particle_lifetime: float = 2.0
@export var particle_speed: float = 5.0

signal effect_created(position: Vector3, effect_type: String)

func _ready() -> void:
	pass

func create_collection_effect(position: Vector3) -> void:
	var multi_mesh = MultiMesh.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.1

	var particles = 8
	for i in range(particles):
		var angle = (TAU / particles) * i
		var particle_pos = position + Vector3(
			cos(angle) * 0.5,
			0.5,
			sin(angle) * 0.5
		)

		var particle = MeshInstance3D.new()
		particle.mesh = mesh
		particle.global_position = particle_pos

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.GOLD
		mat.emission_enabled = true
		mat.emission = Color.GOLD
		particle.material_override = mat

		add_child(particle)

		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "global_position", particle_pos + Vector3(0, 2, 0), particle_lifetime)
		tween.parallel()
		tween.tween_property(particle, "scale", Vector3.ZERO, particle_lifetime)

		await tween.finished
		particle.queue_free()

	effect_created.emit(position, "collection")

func create_impact_effect(position: Vector3, color: Color = Color.WHITE) -> void:
	var mesh = SphereMesh.new()
	mesh.radius = 0.3

	var impact = MeshInstance3D.new()
	impact.mesh = mesh
	impact.global_position = position

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	impact.material_override = mat

	add_child(impact)

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(impact, "scale", Vector3(2, 2, 2), 0.3)
	tween.parallel()
	tween.tween_property(impact, "modulate:a", 0.0, 0.3)

	await tween.finished
	impact.queue_free()

	effect_created.emit(position, "impact")

func create_level_up_effect(position: Vector3) -> void:
	var colors = [Color.GOLD, Color.YELLOW, Color.WHITE]

	for i in range(3):
		var mesh = SphereMesh.new()
		mesh.radius = 0.2 + (i * 0.1)

		var particle = MeshInstance3D.new()
		particle.mesh = mesh
		particle.global_position = position
		particle.scale = Vector3(0.5, 0.5, 0.5)

		var mat = StandardMaterial3D.new()
		mat.albedo_color = colors[i]
		mat.emission_enabled = true
		mat.emission = colors[i]
		particle.material_override = mat

		add_child(particle)

		var tween = create_tween()
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "global_position", position + Vector3(0, 3, 0), 1.0)
		tween.parallel()
		tween.tween_property(particle, "scale", Vector3.ZERO, 1.0)

		await tween.finished
		particle.queue_free()

	effect_created.emit(position, "level_up")

func create_dash_effect(start_pos: Vector3, end_pos: Vector3) -> void:
	var direction = (end_pos - start_pos).normalized()
	var distance = start_pos.distance_to(end_pos)

	for i in range(int(distance * 0.5)):
		var pos = start_pos + direction * (i * 2)

		var mesh = CylinderMesh.new()
		mesh.radius = 0.05
		mesh.height = 0.5

		var trail = MeshInstance3D.new()
		trail.mesh = mesh
		trail.global_position = pos

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.CYAN
		mat.emission_enabled = true
		mat.emission = Color.CYAN
		trail.material_override = mat

		add_child(trail)

		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(trail, "modulate:a", 0.0, 0.2)
		await tween.finished
		trail.queue_free()
