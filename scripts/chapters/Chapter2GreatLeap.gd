extends Node2D

# ─── Chapter 2: The Great Leap ────────────────────────────────────────────────
# Tasks:
# 1. Jambavan reminds Hanuman of his power → power unlock cutscene
# 2. Grow to mountain size → leap tutorial
# 3. Mid-air flight across ocean (1000+ unit scrolling level)
# 4. Avoid storm attacks
# 5. Meet Mainaka mountain (peaceful encounter)
# 6. Boss: Surasa (shrink-to-escape puzzle)
# 7. Boss: Simhika (shadow demon mid-air kill)
# 8. Reach Lanka coast

enum Task { JAMBAVAN_TALK, GROW_AND_LEAP, FLY_OCEAN, MAINAKA, SURASA, SIMHIKA, REACH_LANKA }
var current_task: Task = Task.JAMBAVAN_TALK

var ocean_scroll: float = 0.0
const OCEAN_WIDTH := 8000.0
var mainaka_triggered: bool = false
var surasa_triggered: bool = false
var simhika_triggered: bool = false

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var jambavan_trigger: Area2D = $Triggers/Jambavan
@onready var mainaka_trigger: Area2D = $Triggers/Mainaka
@onready var surasa_spawn: Marker2D = $SpawnPoints/Surasa
@onready var simhika_spawn: Marker2D = $SpawnPoints/Simhika
@onready var ocean_bg: ParallaxBackground = $OceanParallax
@onready var storm_spawner: Node2D = $StormSpawner

func _ready() -> void:
	AudioManager.play_bgm("leap")
	jambavan_trigger.body_entered.connect(_start_jambavan)
	_show_task("The Vanaras search for a way across the ocean...")
	_start_jambavan_intro()

func _start_jambavan_intro() -> void:
	await get_tree().create_timer(1.0).timeout
	DialogueManager.start_dialogue("great_leap_narration")
	DialogueManager.dialogue_ended.connect(_after_jambavan, CONNECT_ONE_SHOT)

func _start_jambavan(_body) -> void:
	pass

func _after_jambavan(_id: String) -> void:
	GameManager.unlock_power("fly")
	GameManager.unlock_power("mahima")
	GameManager.unlock_power("anima")
	GameManager.unlock_power("laghima")
	_show_task("Press [1] to grow (Mahima) — then LEAP across the ocean!")
	current_task = Task.GROW_AND_LEAP
	_wait_for_leap()

func _wait_for_leap() -> void:
	await get_tree().create_timer(0.5).timeout
	while current_task == Task.GROW_AND_LEAP:
		if player.is_flying or player.global_position.x > 200.0:
			_start_ocean_flight()
			break
		await get_tree().create_timer(0.1).timeout

func _start_ocean_flight() -> void:
	current_task = Task.FLY_OCEAN
	_show_task("Fly across the ocean! Reach Lanka — 100 yojanas away")
	camera.position_smoothing_enabled = true
	_start_storm_attacks()

func _process(delta: float) -> void:
	if current_task != Task.FLY_OCEAN and current_task != Task.MAINAKA \
	   and current_task != Task.SURASA and current_task != Task.SIMHIKA:
		return
	ocean_scroll = player.global_position.x
	_check_checkpoints()

func _check_checkpoints() -> void:
	if ocean_scroll > 2000.0 and not mainaka_triggered:
		mainaka_triggered = true
		_trigger_mainaka()
	if ocean_scroll > 4000.0 and not surasa_triggered:
		surasa_triggered = true
		_trigger_surasa()
	if ocean_scroll > 6000.0 and not simhika_triggered:
		simhika_triggered = true
		_trigger_simhika()
	if ocean_scroll > OCEAN_WIDTH:
		_reach_lanka()

func _trigger_mainaka() -> void:
	current_task = Task.MAINAKA
	_show_task("A mountain rises from the sea — Mainaka offers rest")
	DialogueManager.start_dialogue("mainaka_meeting")
	DialogueManager.dialogue_ended.connect(func(_id): current_task = Task.FLY_OCEAN, CONNECT_ONE_SHOT)

func _trigger_surasa() -> void:
	current_task = Task.SURASA
	_show_task("BOSS: Surasa blocks the way! Shrink [2] to escape her mouth!")
	AudioManager.play_bgm("boss")
	var surasa_scene := load("res://scenes/enemies/boss_surasa.tscn")
	if surasa_scene:
		var surasa = surasa_scene.instantiate()
		surasa.global_position = surasa_spawn.global_position
		surasa.died.connect(_on_surasa_defeated)
		add_child(surasa)
		$HUD.show_boss_health("Surasa", surasa.max_health, surasa.max_health)
		surasa.health_changed.connect(func(c,_m): $HUD.update_boss_health(c))

func _on_surasa_defeated(_enemy) -> void:
	$HUD.hide_boss_health()
	AudioManager.play_bgm("leap")
	current_task = Task.FLY_OCEAN
	_show_task("Surasa blesses you! Continue to Lanka!")
	DialogueManager.start_dialogue("surasa_challenge")

func _trigger_simhika() -> void:
	current_task = Task.SIMHIKA
	_show_task("BOSS: Simhika — the shadow demon! Attack her from above!")
	AudioManager.play_bgm("boss")
	var simhika_scene := load("res://scenes/enemies/boss_simhika.tscn")
	if simhika_scene:
		var simhika = simhika_scene.instantiate()
		simhika.global_position = simhika_spawn.global_position
		simhika.died.connect(_on_simhika_defeated)
		add_child(simhika)
		$HUD.show_boss_health("Simhika", simhika.max_health, simhika.max_health)
		simhika.health_changed.connect(func(c,_m): $HUD.update_boss_health(c))

func _on_simhika_defeated(_enemy) -> void:
	$HUD.hide_boss_health()
	current_task = Task.FLY_OCEAN
	AudioManager.play_bgm("leap")
	_show_task("Lanka in sight! Descend!")

func _reach_lanka() -> void:
	current_task = Task.REACH_LANKA
	GameManager.set_flag("leaped_to_lanka")
	_show_task("You have reached Lanka!")
	await get_tree().create_timer(2.0).timeout
	GameManager.complete_chapter(GameManager.Chapter.GREAT_LEAP)

func _start_storm_attacks() -> void:
	_storm_loop()

func _storm_loop() -> void:
	while current_task in [Task.FLY_OCEAN, Task.MAINAKA, Task.SURASA, Task.SIMHIKA]:
		await get_tree().create_timer(randf_range(4.0, 8.0)).timeout
		if current_task == Task.FLY_OCEAN:
			_spawn_storm_bolt()

func _spawn_storm_bolt() -> void:
	if not player:
		return
	var bolt_pos := player.global_position + Vector2(randf_range(-300, 300), -400)
	pass

func _show_task(text: String) -> void:
	if $HUD:
		$HUD._show_notification(text, 4.0)
