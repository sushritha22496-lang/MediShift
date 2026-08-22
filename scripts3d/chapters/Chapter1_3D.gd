extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var health_bar: ProgressBar = $HUD/Margin/VBox/HealthBar
@onready var health_label: Label = $HUD/Margin/VBox/HealthLabel
@onready var title_label: Label = $HUD/TitleLabel
@onready var enemy_spawns: Node3D = $EnemySpawns

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	_on_health_changed(player.health, player.max_health)
	_spawn_enemies()
	_show_title("Chapter I — Rishyamukha Mountain")

func _spawn_enemies() -> void:
	var scene := load("res://scenes3d/enemies/demon_guard_3d.tscn")
	if not scene:
		return
	for marker in enemy_spawns.get_children():
		var enemy = scene.instantiate()
		add_child(enemy)
		enemy.global_position = marker.global_position

func _on_health_changed(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "%d / %d" % [int(current), int(maximum)]

func _on_player_died() -> void:
	_show_title("You have fallen. Press R to retry.")
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cheat_enter"):
		get_tree().reload_current_scene()

func _show_title(text: String) -> void:
	title_label.text = text
	title_label.visible = true
	var tween := create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(title_label, "modulate:a", 0.0, 1.0)
