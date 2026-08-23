extends Node3D

# Chapter 4: Lanka Siege (FINAL)
# Epic battle with Ravana - the ultimate boss with 3 phases

@onready var player: CharacterBody3D = $Player
@onready var health_bar: ProgressBar = $HUD/Margin/VBox/HealthBar
@onready var health_label: Label = $HUD/Margin/VBox/HealthLabel
@onready var title_label: Label = $HUD/TitleLabel
@onready var boss_bar: ProgressBar = $HUD/BossBar/VBox/BossHealthBar
@onready var boss_name_label: Label = $HUD/BossBar/VBox/BossNameLabel
@onready var phase_label: Label = $HUD/BossBar/VBox/PhaseLabel
@onready var boss_bar_container: Control = $HUD/BossBar
@onready var objective_label: Label = $HUD/Margin/VBox/ObjectiveLabel
@onready var enemy_spawns: Node3D = $EnemySpawns
@onready var boss_spawn: Marker3D = $BossSpawn

var enemies_alive: int = 0
var boss: Node3D = null
var boss_health: float = 0
var boss_max_health: float = 0
var current_phase: int = 0
var current_objective: String = "Rescue Sita and defeat Ravana"

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	_on_health_changed(player.health, player.max_health)

	boss_bar_container.visible = false
	_show_title("Chapter IV — Lanka Siege (FINAL)")
	objective_label.text = current_objective

	# Spawn initial demon army
	_spawn_demon_waves()

func _spawn_demon_waves() -> void:
	"""Spawn massive waves of demons defending Lanka"""
	var demon_variations := [
		"res://scenes3d/enemies/demon_guard_new.tscn",
		"res://scenes3d/enemies/demon_guard_var2.tscn",
		"res://scenes3d/enemies/demon_guard_var3.tscn"
	]

	var markers := enemy_spawns.get_children()
	enemies_alive = 0

	# Spawn multiple demons at each spawn point
	for marker in markers:
		for i in range(2):  # 2 demons per spawn point
			var variation = demon_variations[randi() % demon_variations.size()]
			var scene := load(variation)
			if not scene:
				continue
			var enemy = scene.instantiate()
			add_child(enemy)
			enemy.global_position = marker.global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			enemy.died.connect(_on_enemy_died)
			enemies_alive += 1

func _on_enemy_died(_enemy) -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and not boss:
		_show_title("Ravana descends from his palace...")
		current_objective = "Defeat Ravana - Phase 1"
		objective_label.text = current_objective
		await get_tree().create_timer(2.0).timeout
		_spawn_ravana_boss()

func _spawn_ravana_boss() -> void:
	"""Spawn Ravana - the ultimate final boss"""
	var scene := load("res://scenes3d/enemies/boss_ravana.tscn")
	if not scene:
		# Fallback: create a powerful boss variant
		scene = load("res://scenes3d/enemies/demon_guard_var3.tscn")
	if not scene:
		return

	boss = scene.instantiate()
	add_child(boss)
	boss.global_position = boss_spawn.global_position

	# Setup boss stats
	boss.enemy_name = "Ravana"
	boss.max_health = 500.0
	boss.health = 500.0
	boss.attack_damage = 50.0

	boss.died.connect(_on_boss_died)
	boss.health_changed.connect(_on_boss_health_changed)

	boss_bar_container.visible = true
	boss_name_label.text = "Ravana - Dark Lord"
	phase_label.text = "Phase 1"
	current_phase = 1

	_show_title("ULTIMATE BOSS: RAVANA!")

func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_health = current
	boss_max_health = maximum
	boss_bar.max_value = maximum
	boss_bar.value = current

	# Phase management based on health percentage
	var health_percent = current / maximum
	var new_phase = 3 if health_percent <= 0.33 else (2 if health_percent <= 0.66 else 1)

	if new_phase != current_phase:
		current_phase = new_phase
		_on_phase_change()

func _on_phase_change() -> void:
	"""Handle phase transitions"""
	match current_phase:
		1:
			phase_label.text = "Phase 1"
			current_objective = "Defeat Ravana - Phase 1"
		2:
			_show_title("Ravana's power grows!")
			phase_label.text = "Phase 2"
			current_objective = "Defeat Ravana - Phase 2"
			_spawn_reinforcements()
		3:
			_show_title("Ravana enters his final form!")
			phase_label.text = "Phase 3"
			current_objective = "Defeat Ravana - Final Phase!"

	objective_label.text = current_objective

func _spawn_reinforcements() -> void:
	"""Spawn additional demons during phase transitions"""
	var demon_variations := [
		"res://scenes3d/enemies/demon_guard_new.tscn",
		"res://scenes3d/enemies/demon_guard_var2.tscn",
		"res://scenes3d/enemies/demon_guard_var3.tscn"
	]

	# Spawn 3 reinforcement demons
	for i in range(3):
		var variation = demon_variations[randi() % demon_variations.size()]
		var scene := load(variation)
		if not scene:
			continue
		var enemy = scene.instantiate()
		add_child(enemy)
		var spawn_pos = boss.global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
		enemy.global_position = spawn_pos
		enemy.died.connect(_on_enemy_died)

func _on_boss_died(_enemy) -> void:
	boss = null
	boss_bar_container.visible = false
	_show_title("RAVANA FALLS! VICTORY!")
	current_objective = "GAME COMPLETE!"
	objective_label.text = current_objective

	await get_tree().create_timer(3.0).timeout
	_show_victory()

func _show_victory() -> void:
	"""Show final victory screen"""
	title_label.text = "You have completed the Ramayana!"
	title_label.visible = true
	var tween := create_tween()
	tween.tween_interval(5.0)
	tween.tween_callback(func(): print("✅ GAME COMPLETE! VICTORY!"))

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
