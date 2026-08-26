extends Control

class_name PauseMenu

@onready var resume_btn = $VBoxContainer/ResumeButton
@onready var objectives_btn = $VBoxContainer/ObjectivesButton
@onready var settings_btn = $VBoxContainer/SettingsButton
@onready var main_menu_btn = $VBoxContainer/MainMenuButton

signal resume_game
signal show_objectives
signal show_settings
signal return_to_menu

func _ready() -> void:
	resume_btn.pressed.connect(_on_resume)
	objectives_btn.pressed.connect(_on_objectives)
	settings_btn.pressed.connect(_on_settings)
	main_menu_btn.pressed.connect(_on_main_menu)
	modulate.alpha = 0.9

func _on_resume() -> void:
	resume_game.emit()
	queue_free()

func _on_objectives() -> void:
	show_objectives.emit()

func _on_settings() -> void:
	show_settings.emit()

func _on_main_menu() -> void:
	return_to_menu.emit()
	get_tree().reload_current_scene()
