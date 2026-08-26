extends Node3D

class_name EffectSpawner

var dust_scene: PackedScene
var sparkle_scene: PackedScene

func _ready() -> void:
	dust_scene = preload("res://scenes3d/effects/dust_particle.tscn") if ResourceLoader.exists("res://scenes3d/effects/dust_particle.tscn") else null

func spawn_dust(position: Vector3, amount: int = 5) -> void:
	for i in range(amount):
		var p = CPUParticles3D.new()
		p.global_position = position
		p.amount = 10
		p.emitting = true
		p.lifetime = 1.0
		p.speed_scale = 1.5
		add_child(p)
		await get_tree().create_timer(1.2).timeout
		p.queue_free()

func spawn_highlight(position: Vector3, color: Color = Color.YELLOW) -> void:
	var sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.material = StandardMaterial3D.new()
	sphere.material.albedo_color = color
	sphere.material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material.alpha = 0.3
	sphere.scale = Vector3.ONE * 0.5
	sphere.global_position = position
	add_child(sphere)

	var tween = create_tween()
	tween.tween_property(sphere, "scale", Vector3.ONE * 1.2, 0.5)
	tween.parallel().tween_property(sphere.material, "alpha", 0.0, 0.5)
	await tween.finished
	sphere.queue_free()

func spawn_text(text: str, position: Vector3, duration: float = 2.0) -> void:
	var label = Label3D.new()
	label.text = text
	label.global_position = position
	label.font_size = 32
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "global_position:y", position.y + 1, duration)
	tween.parallel().tween_property(label.material, "albedo_color", Color(1, 1, 1, 0), duration)
	await tween.finished
	label.queue_free()
