extends Control

class_name MainMenu

@onready var title = $VBoxContainer/Title
@onready var start_btn = $VBoxContainer/StartButton
@onready var settings_btn = $VBoxContainer/SettingsButton
@onready var quit_btn = $VBoxContainer/QuitButton

signal game_started
signal settings_opened
signal game_quit

func _ready() -> void:
	start_btn.pressed.connect(_on_start_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	title.text = "RAMAYANA QUEST"

func _on_start_pressed() -> void:
	game_started.emit()
	get_tree().root.remove_child(self)
	queue_free()

func _on_settings_pressed() -> void:
	settings_opened.emit()

func _on_quit_pressed() -> void:
	game_quit.emit()
	get_tree().quit()
