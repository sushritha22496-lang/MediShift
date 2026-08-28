extends Node3D

class_name CombatVisualEffects

static func play_hit_effect(position: Vector3, parent: Node3D, damage: int) -> void:
	ParticleEffects.spawn_hit_effect(position, parent, Color.RED)
	ParticleEffects.spawn_damage_numbers(damage, position + Vector3(0, 1, 0), parent)
	_create_impact_shockwave(position, parent)
	_create_blood_splatter(position, parent)
	_create_dust_cloud(position, parent)

static func play_critical_hit(position: Vector3, parent: Node3D) -> void:
	_create_critical_flash(position, parent)
	_create_explosion_effect(position, parent, Color.YELLOW)
	_create_radiant_burst(position, parent)
	_create_critical_spark_rain(position, parent)

static func play_heal_effect(position: Vector3, parent: Node3D, amount: int) -> void:
	_create_heal_aura(position, parent)
	ParticleEffects.spawn_damage_numbers(amount, position + Vector3(0, 1, 0), parent)

static func play_block_effect(position: Vector3, parent: Node3D) -> void:
	_create_shield_flash(position, parent)

static func play_attack_animation(attacker: Node3D, weapon: String = "sword") -> void:
	if not attacker:
		return

	match weapon:
		"sword":
			_play_sword_swing(attacker)
		"mace":
			_play_mace_swing(attacker)
		_:
			_play_default_attack(attacker)

static func _create_impact_shockwave(position: Vector3, parent: Node3D) -> void:
	var shockwave = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.radius = 0.5
	cylinder.height = 0.1
	shockwave.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shockwave.set_surface_override_material(0, mat)
	shockwave.position = position

	parent.add_child(shockwave)

	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.tween_property(shockwave, "scale", Vector3(3, 0.1, 3), 0.3)
	tween.tween_property(shockwave, "modulate:a", 0.0, 0.3)
	await tween.finished
	shockwave.queue_free()

static func _create_critical_flash(position: Vector3, parent: Node3D) -> void:
	var flash = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2, 2, 2)
	flash.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.YELLOW
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.alpha_scissor_threshold = 0.5
	flash.set_surface_override_material(0, mat)
	flash.position = position

	parent.add_child(flash)

	var tween = parent.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.4)
	await tween.finished
	flash.queue_free()

static func _create_explosion_effect(position: Vector3, parent: Node3D, color: Color) -> void:
	var explosion = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	explosion.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	explosion.set_surface_override_material(0, mat)
	explosion.position = position

	parent.add_child(explosion)

	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(explosion, "scale", Vector3(3, 3, 3), 0.4)
	tween.tween_property(explosion, "modulate:a", 0.0, 0.4)
	await tween.finished
	explosion.queue_free()

static func _create_heal_aura(position: Vector3, parent: Node3D) -> void:
	var aura = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.8
	torus.outer_radius = 1.0
	aura.mesh = torus

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.GREEN
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.alpha_scissor_threshold = 0.5
	aura.set_surface_override_material(0, mat)
	aura.position = position

	parent.add_child(aura)

	var tween = parent.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(aura, "rotation:y", TAU, 1.0)
	await tween.finished
	aura.queue_free()

static func _create_shield_flash(position: Vector3, parent: Node3D) -> void:
	var shield = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.5
	shield.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.BLUE
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.alpha_scissor_threshold = 0.5
	shield.set_surface_override_material(0, mat)
	shield.position = position

	parent.add_child(shield)

	var tween = parent.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(shield, "scale", Vector3(0.1, 0.1, 0.1), 0.3)
	tween.tween_property(shield, "modulate:a", 0.0, 0.3)
	await tween.finished
	shield.queue_free()

static func _play_sword_swing(attacker: Node3D) -> void:
	if not attacker or not attacker.has_node("Model"):
		return

	var model = attacker.get_node("Model")
	var original_rotation = model.rotation

	var tween = attacker.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(model, "rotation:z", original_rotation.z + PI / 3, 0.2)
	tween.tween_property(model, "rotation:z", original_rotation.z, 0.1)

static func _play_mace_swing(attacker: Node3D) -> void:
	if not attacker or not attacker.has_node("Model"):
		return

	var model = attacker.get_node("Model")
	var original_rotation = model.rotation

	var tween = attacker.create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(model, "rotation:x", original_rotation.x + PI / 4, 0.15)
	tween.tween_property(model, "rotation:x", original_rotation.x, 0.15)

static func _play_default_attack(attacker: Node3D) -> void:
	if not attacker or not attacker.has_node("Model"):
		return

	var model = attacker.get_node("Model")
	var original_pos = model.position

	var tween = attacker.create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(model, "position", original_pos + Vector3(0.2, 0, 0), 0.1)
	tween.tween_property(model, "position", original_pos, 0.1)

static func _create_blood_splatter(position: Vector3, parent: Node3D) -> void:
	var splatter = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	splatter.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.1, 0.1, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	splatter.set_surface_override_material(0, mat)
	splatter.position = position + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2))

	parent.add_child(splatter)

	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(splatter, "scale", Vector3(0.2, 0.2, 0.2), 0.4)
	tween.tween_property(splatter, "modulate:a", 0.0, 0.5)
	await tween.finished
	splatter.queue_free()

static func _create_dust_cloud(position: Vector3, parent: Node3D) -> void:
	var dust = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.5, 1.5, 1.5)
	dust.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.6, 0.5, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust.set_surface_override_material(0, mat)
	dust.position = position

	parent.add_child(dust)

	var tween = parent.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(dust, "scale", Vector3(2.5, 2.5, 2.5), 0.5)
	tween.tween_property(dust, "modulate:a", 0.0, 0.5)
	await tween.finished
	dust.queue_free()

static func _create_radiant_burst(position: Vector3, parent: Node3D) -> void:
	# Multiple radiating rays for critical effect
	for i in range(8):
		var ray = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.2, 2.0, 0.2)
		ray.mesh = box

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.9, 0.2, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ray.set_surface_override_material(0, mat)

		var angle = (TAU / 8.0) * i
		ray.position = position + Vector3(cos(angle) * 0.3, 0, sin(angle) * 0.3)
		ray.rotation.y = angle

		parent.add_child(ray)

		var tween = parent.create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(ray, "scale:y", 2.5, 0.3)
		tween.tween_property(ray, "modulate:a", 0.0, 0.3)
		await tween.finished
		ray.queue_free()

static func _create_critical_spark_rain(position: Vector3, parent: Node3D) -> void:
	# Rain down sparks for critical hit
	for i in range(12):
		var spark = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.1
		spark.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.8, 0.2)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		spark.set_surface_override_material(0, mat)

		var angle = (TAU / 12.0) * i
		var start_pos = position + Vector3(cos(angle) * 1.0, 1.5, sin(angle) * 1.0)
		spark.position = start_pos

		parent.add_child(spark)

		var tween = parent.create_tween()
		tween.set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(spark, "position", start_pos + Vector3(0, -1.5, 0), 0.6)
		tween.tween_property(spark, "modulate:a", 0.0, 0.6)
		await tween.finished
		spark.queue_free()
