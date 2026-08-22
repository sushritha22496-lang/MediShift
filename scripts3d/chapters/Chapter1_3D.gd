extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var health_bar: ProgressBar = $HUD/Margin/VBox/HealthBar
@onready var health_label: Label = $HUD/Margin/VBox/HealthLabel
@onready var title_label: Label = $HUD/TitleLabel
@onready var boss_bar: ProgressBar = $HUD/BossBar/VBox/BossHealthBar
@onready var boss_name_label: Label = $HUD/BossBar/VBox/BossNameLabel
@onready var boss_bar_container: Control = $HUD/BossBar
@onready var enemy_spawns: Node3D = $EnemySpawns
@onready var boss_spawn: Marker3D = $BossSpawn

var guards_alive: int = 0

func _ready() -> void:
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	_on_health_changed(player.health, player.max_health)
	boss_bar_container.visible = false
	_spawn_enemies()
	_show_title("Chapter I — Rishyamukha Mountain")

func _spawn_enemies() -> void:
	var scene := load("res://scenes3d/enemies/demon_guard_3d.tscn")
	if not scene:
		_spawn_boss()
		return
	var markers := enemy_spawns.get_children()
	guards_alive = markers.size()
	for marker in markers:
		var enemy = scene.instantiate()
		add_child(enemy)
		enemy.global_position = marker.global_position
		enemy.died.connect(_on_guard_died)

func _on_guard_died(_enemy) -> void:
	guards_alive -= 1
	if guards_alive <= 0:
		_show_title("The forest is clear... something massive stirs.")
		await get_tree().create_timer(2.5).timeout
		_spawn_boss()

func _spawn_boss() -> void:
	var scene := load("res://scenes3d/enemies/boss_dundhubi_3d.tscn")
	if not scene:
		return
	var boss = scene.instantiate()
	add_child(boss)
	boss.global_position = boss_spawn.global_position
	boss.died.connect(_on_boss_died)
	boss.health_changed.connect(_on_boss_health_changed)
	boss_bar_container.visible = true
	boss_name_label.text = boss.enemy_name
	_show_title("BOSS: Dundhubi")

func _on_boss_health_changed(current: float, maximum: float) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current

func _on_boss_died(_enemy) -> void:
	boss_bar_container.visible = false
	_show_title("Dundhubi falls! Chapter I complete.")

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
