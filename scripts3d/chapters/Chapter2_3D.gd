extends Node3D

# Chapter 2: Rama's Journey
# Rama and Lakshman search for Sita while fighting Indrajit

@onready var player: CharacterBody3D = $Player
@onready var health_bar: ProgressBar = $HUD/Margin/VBox/HealthBar
@onready var health_label: Label = $HUD/Margin/VBox/HealthLabel
@onready var title_label: Label = $HUD/TitleLabel
@onready var boss_bar: ProgressBar = $HUD/BossBar/VBox/BossHealthBar
@onready var boss_name_label: Label = $HUD/BossBar/VBox/BossNameLabel
@onready var boss_bar_container: Control = $HUD/BossBar
@onready var objective_label: Label = $HUD/Margin/VBox/ObjectiveLabel
@onready var enemy_spawns: Node3D = $EnemySpawns
@onready var boss_spawn: Marker3D = $BossSpawn

var enemies_alive: int = 0
var chapter_manager: ChapterManager
var current_objective: String = "Defeat the forest demons"

func _ready() -> void:
	# Connect signals
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	_on_health_changed(player.health, player.max_health)

	# Setup chapter
	boss_bar_container.visible = false
	_show_title("Chapter II — Rama's Journey")
	objective_label.text = current_objective

	# Spawn initial enemies
	_spawn_enemies()

func _spawn_enemies() -> void:
	"""Spawn forest demon variations"""
	var demon_variations := [
		"res://scenes3d/enemies/demon_guard_new.tscn",
		"res://scenes3d/enemies/demon_guard_var2.tscn",
		"res://scenes3d/enemies/demon_guard_var3.tscn"
	]

	var markers := enemy_spawns.get_children()
	enemies_alive = markers.size()

	for marker in markers:
		var variation = demon_variations[randi() % demon_variations.size()]
		var scene := load(variation)
		if not scene:
			continue
		var enemy = scene.instantiate()
		add_child(enemy)
		enemy.global_position = marker.global_position
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_enemy) -> void:
	"""Called when an enemy dies"""
	enemies_alive -= 1
	if enemies_alive <= 0:
		_show_title("The path ahead reveals Indrajit...")
		current_objective = "Defeat Indrajit"
		objective_label.text = current_objective
		await get_tree().create_timer(2.5).timeout
		_spawn_boss()

func _spawn_boss() -> void:
	"""Spawn Indrajit boss"""
	var scene := load("res://scenes3d/enemies/boss_indrajit.tscn")
	if not scene:
		# Fallback: create a larger demon guard variation
		scene = load("res://scenes3d/enemies/demon_guard_var3.tscn")
	if not scene:
		return

	var boss = scene.instantiate()
	add_child(boss)
	boss.global_position = boss_spawn.global_position
	boss.died.connect(_on_boss_died)
	boss.health_changed.connect(_on_boss_health_changed)
	boss_bar_container.visible = true
	boss_name_label.text = "Indrajit"
	_show_title("BOSS: Indrajit - Ravana's Son")

func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current

func _on_boss_died(_enemy) -> void:
	boss_bar_container.visible = false
	_show_title("Indrajit falls! Sita's location revealed.")
	current_objective = "Chapter Complete!"
	objective_label.text = current_objective

	# Chapter complete - prepare for Chapter 3
	await get_tree().create_timer(3.0).timeout
	_complete_chapter()

func _complete_chapter() -> void:
	"""Complete the chapter and transition to next"""
	print("✅ Chapter 2 Complete! Proceeding to Chapter 3...")
	# TODO: Load Chapter 3

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
