extends Node

class_name Bootstrapper

@export var main_scene_path: String = "res://scenes3d/chapters/game_main.tscn"
@export var auto_start: bool = true

func _ready() -> void:
	var game_ctrl = GameController.new()
	add_child(game_ctrl)
	game_ctrl._initialize_systems()

	if auto_start:
		await get_tree().process_frame
		load_main_scene()

func load_main_scene() -> void:
	var scene = load(main_scene_path)
	if scene:
		var instance = scene.instantiate()
		get_tree().root.add_child(instance)
		GameController.get().start_game()
	else:
		push_error("Failed to load main scene: " + main_scene_path)
