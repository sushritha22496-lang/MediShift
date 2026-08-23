extends Node3D

# Chapter 3: Ocean Crossing
# Hanuman and monkey army journey to Lanka

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
var wave_count: int = 0
var current_objective: String = "Cross the ocean safely"

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	_on_health_changed(player.health, player.max_health)

	boss_bar_container.visible = false
	_show_title("Chapter III — Ocean Crossing")
	objective_label.text = current_objective

	_spawn_enemy_wave()

func _spawn_enemy_wave() -> void:
	"""Spawn a wave of ocean demons"""
	wave_count += 1
	var demon_variations := [
		"res://scenes3d/enemies/demon_guard_new.tscn",
		"res://scenes3d/enemies/demon_guard_var2.tscn",
		"res://scenes3d/enemies/demon_guard_var3.tscn"
	]

	var markers := enemy_spawns.get_children()
	enemies_alive = mini(markers.size() + wave_count, markers.size() * 2)

	for i in range(mini(3 + wave_count, markers.size())):
		var marker = markers[i]
		var variation = demon_variations[randi() % demon_variations.size()]
		var scene := load(variation)
		if not scene:
			continue
		var enemy = scene.instantiate()
		add_child(enemy)
		enemy.global_position = marker.global_position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died(_enemy) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		if wave_count < 2:
			_show_title("More demons approach!")
			await get_tree().create_timer(1.5).timeout
			_spawn_enemy_wave()
		else:
			_show_title("Kumbhakarna emerges from the depths...")
			current_objective = "Defeat Kumbhakarna"
			objective_label.text = current_objective
			await get_tree().create_timer(2.0).timeout
			_spawn_boss()

func _spawn_boss() -> void:
	"""Spawn Kumbhakarna - the giant demon"""
	var scene := load("res://scenes3d/enemies/boss_kumbhakarna.tscn")
	if not scene:
		# Fallback: scale up a regular demon
		scene = load("res://scenes3d/enemies/demon_guard_var3.tscn")
	if not scene:
		return

	var boss = scene.instantiate()
	add_child(boss)
	boss.global_position = boss_spawn.global_position
	boss.died.connect(_on_boss_died)
	boss.health_changed.connect(_on_boss_health_changed)
	boss_bar_container.visible = true
	boss_name_label.text = "Kumbhakarna"
	_show_title("BOSS: Kumbhakarna - The Giant Demon")

func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current

func _on_boss_died(_enemy) -> void:
	boss_bar_container.visible = false
	_show_title("Kumbhakarna falls! Lanka's shores await!")
	current_objective = "Chapter Complete!"
	objective_label.text = current_objective

	await get_tree().create_timer(3.0).timeout
	_complete_chapter()

func _complete_chapter() -> void:
	print("✅ Chapter 3 Complete! Proceeding to Chapter 4...")

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
