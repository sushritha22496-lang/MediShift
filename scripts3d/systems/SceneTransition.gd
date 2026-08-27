extends CanvasLayer

class_name SceneTransition

@onready var fade_rect = ColorRect.new()

var is_transitioning: bool = false
var transition_duration: float = 1.0

signal transition_started
signal transition_halfway
signal transition_ended

func _ready() -> void:
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	add_child(fade_rect)
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0

func fade_out(duration: float = 1.0) -> void:
	if is_transitioning:
		return

	is_transitioning = true
	transition_started.emit()
	transition_duration = duration

	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	transition_halfway.emit()

func fade_in(duration: float = 1.0) -> void:
	if not is_transitioning:
		return

	transition_duration = duration
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished

	is_transitioning = false
	transition_ended.emit()

func transition_to_scene(scene_path: String, duration: float = 1.0) -> void:
	await fade_out(duration)
	get_tree().change_scene_to_file(scene_path)
	await fade_in(duration)

func transition_to_packed_scene(scene: PackedScene, duration: float = 1.0) -> void:
	await fade_out(duration)
	get_tree().change_scene_to_packed(scene)
	await fade_in(duration)

static func fade_to_scene(caller: Node, scene_path: String, duration: float = 1.0) -> void:
	var canvas = CanvasLayer.new()
	caller.add_child(canvas)
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.modulate.a = 0.0
	canvas.add_child(fade_rect)
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0

	var tween = caller.create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished
	caller.get_tree().change_scene_to_file(scene_path)
