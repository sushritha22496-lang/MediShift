extends Node

class_name GameBootstrap

func _ready() -> void:
	_initialize_game()

func _initialize_game() -> void:
	var controller = GameController.new()
	add_child(controller)

	await get_tree().process_frame

	_load_chapter_1()

func _load_chapter_1() -> void:
	get_tree().change_scene_to_file("res://scenes3d/chapters/game_main.tscn")

func _on_chapter_complete(chapter: int) -> void:
	match chapter:
		1:
			get_tree().change_scene_to_file("res://scenes3d/chapters/chapter_2_gathering.tscn")
		2:
			get_tree().change_scene_to_file("res://scenes3d/chapters/chapter_3_coast.tscn")
		3:
			get_tree().change_scene_to_file("res://scenes3d/chapters/chapter_4_ocean.tscn")
		4:
			get_tree().change_scene_to_file("res://scenes3d/chapters/chapter_5_fortress.tscn")
		5:
			get_tree().change_scene_to_file("res://scenes3d/chapters/chapter_6_rescue.tscn")
		6:
			_end_game()

func _end_game() -> void:
	print("Game Complete!")
	get_tree().change_scene_to_file("res://scenes3d/menu/main_menu.tscn")
