extends Control

class_name MainMenu

@onready var title = $Title
@onready var start_btn = $StartButton
@onready var quit_btn = $QuitButton

signal game_started
signal game_quit

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	title.text = "🏹 THE RAMAYANA\nAn Epic Journey"

func _on_start_pressed() -> void:
	game_started.emit()
	get_tree().change_scene_to_file("res://scenes3d/chapters/game_main.tscn")

func _on_quit_pressed() -> void:
	game_quit.emit()
	get_tree().quit()
