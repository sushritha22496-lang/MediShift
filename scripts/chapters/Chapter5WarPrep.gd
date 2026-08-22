extends Node2D

# ─── Chapter 5: War Preparation ───────────────────────────────────────────────
# Tasks:
# 1. Return to Rama — deliver news + Chudamani
# 2. Vibhishana defects → escort him safely
# 3. Ram Setu mini-game: carry boulders, float stones with Rama's name
# 4. March Vanara army to Lanka (wave sequence)

enum Task { RETURN_TO_RAMA, VIBHISHANA_ESCORT, RAM_SETU, ARMY_MARCH }
var current_task: Task = Task.RETURN_TO_RAMA

var setu_stones_placed: int = 0
const SETU_STONES_NEEDED := 30
var army_wave: int = 0
const ARMY_WAVES := 3

@onready var player: CharacterBody2D = $Player
@onready var rama_position: Marker2D = $Markers/Rama
@onready var setu_zone: Node2D = $SetuZone
@onready var boulder_spawner: Node2D = $BoulderSpawner
@onready var setu_progress: ProgressBar = $HUD/SetuProgress

func _ready() -> void:
	AudioManager.play_bgm("kishkindha")
	_trigger_return()

func _trigger_return() -> void:
	await get_tree().create_timer(1.0).timeout
	DialogueManager.start_dialogue("news_to_rama")
	DialogueManager.dialogue_ended.connect(_after_news, CONNECT_ONE_SHOT)

func _after_news(_id: String) -> void:
	GameManager.set_flag("met_rama")
	current_task = Task.VIBHISHANA_ESCORT
	_show_task("Protect Vibhishana — escort Ravana's brother to safety!")
	_start_vibhishana_escort()

func _start_vibhishana_escort() -> void:
	await get_tree().create_timer(0.5).timeout
	_spawn_escort_enemies(5)
	await get_tree().create_timer(8.0).timeout
	_on_vibhishana_safe()

func _spawn_escort_enemies(count: int) -> void:
	for i in count:
		var scene := load("res://scenes/enemies/demon_guard.tscn")
		if not scene:
			continue
		var e = scene.instantiate()
		e.global_position = Vector2(randf_range(200, 800), 400)
		add_child(e)

func _on_vibhishana_safe() -> void:
	current_task = Task.RAM_SETU
	_show_task("Build Ram Setu! Throw boulders into the ocean — %d stones needed!" % SETU_STONES_NEEDED)
	DialogueManager.start_dialogue("ram_setu")
	DialogueManager.dialogue_ended.connect(_start_setu_minigame, CONNECT_ONE_SHOT)

func _start_setu_minigame(_id: String) -> void:
	_show_task("Pick up boulders [E] and throw them [Attack] into the ocean!")
	_spawn_boulders()
	if setu_progress:
		setu_progress.visible = true
		setu_progress.max_value = SETU_STONES_NEEDED
		setu_progress.value = 0

const BOULDERS_ACTIVE := 10

func _spawn_boulders() -> void:
	for i in BOULDERS_ACTIVE:
		_spawn_one_boulder()

func _spawn_one_boulder() -> void:
	var b_scene := load("res://scenes/objects/boulder.tscn")
	if not b_scene:
		return
	var b = b_scene.instantiate()
	add_child(b)
	b.global_position = Vector2(randf_range(-200, 200), 300)
	if b.has_signal("placed_in_ocean"):
		b.placed_in_ocean.connect(_on_stone_placed)

func _on_stone_placed() -> void:
	setu_stones_placed += 1
	GameManager.add_score(300)
	AudioManager.play_sfx("collect")
	if setu_progress:
		setu_progress.value = setu_stones_placed
	_show_task("Ram Setu: %d / %d stones placed" % [setu_stones_placed, SETU_STONES_NEEDED])
	_spawn_bridge_stone()
	if setu_stones_placed >= SETU_STONES_NEEDED:
		_setu_complete()
	else:
		_spawn_one_boulder()

func _spawn_bridge_stone() -> void:
	var stone := ColorRect.new()
	stone.size = Vector2(26, 18)
	var step: float = 960.0 / float(SETU_STONES_NEEDED)
	stone.position = Vector2(-390.0 + float(setu_stones_placed - 1) * step, 130.0)
	stone.color = Color(0.72, 0.66, 0.5, 1)
	setu_zone.add_child(stone)

func _setu_complete() -> void:
	if setu_progress:
		setu_progress.visible = false
	GameManager.set_flag("ram_setu_built")
	_show_task("Ram Setu complete! The army marches to Lanka!")
	await get_tree().create_timer(2.0).timeout
	_start_army_march()

func _start_army_march() -> void:
	current_task = Task.ARMY_MARCH
	_show_task("Lead the Vanara army! Fight through %d waves!" % ARMY_WAVES)
	_spawn_army_wave()

func _spawn_army_wave() -> void:
	army_wave += 1
	_show_task("Wave %d / %d — Defeat all demons!" % [army_wave, ARMY_WAVES])
	var count := army_wave * 5
	var alive := count
	for i in count:
		var scene := load("res://scenes/enemies/demon_guard.tscn")
		if not scene:
			continue
		var e = scene.instantiate()
		e.global_position = Vector2(randf_range(400, 900), 400)
		e.died.connect(func(_en):
			alive -= 1
			if alive <= 0:
				_on_wave_cleared()
		)
		add_child(e)

func _on_wave_cleared() -> void:
	if army_wave < ARMY_WAVES:
		await get_tree().create_timer(2.0).timeout
		_spawn_army_wave()
	else:
		_march_complete()

func _march_complete() -> void:
	_show_task("Lanka is in sight! Prepare for the great war!")
	await get_tree().create_timer(3.0).timeout
	GameManager.complete_chapter(GameManager.Chapter.WAR_PREP)

func _show_task(text: String) -> void:
	if $HUD:
		$HUD._show_notification(text, 4.0)
