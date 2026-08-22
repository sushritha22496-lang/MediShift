extends Node2D

# ─── Chapter 4: Lanka Rampage ─────────────────────────────────────────────────
# Tasks:
# 1. Destroy Ashoka Vatika (trees, structures)
# 2. Fight guards wave 1
# 3. Boss: Jambumali
# 4. Boss: Aksha Kumar (Ravana's son)
# 5. Get captured (scripted — Brahmastra)
# 6. Ravana's court — dialogue choices
# 7. Tail set on fire — escape
# 8. Burn Lanka rooftop run
# 9. Leap back to India

enum Task {
	DESTROY_VATIKA, GUARDS_WAVE1, BOSS_JAMBUMALI, BOSS_AKSHA,
	CAPTURED, RAVANA_COURT, TAIL_FIRE, BURN_LANKA, LEAP_BACK
}
var current_task: Task = Task.DESTROY_VATIKA

var vatika_destroyed: int = 0
const VATIKA_ITEMS := 20
var buildings_burned: int = 0
const BUILDINGS_TO_BURN := 15
var wave_count: int = 0
var fire_active: bool = false

@onready var player: CharacterBody2D = $Player
@onready var vatika_objects: Node2D = $VatikaObjects
@onready var guard_spawner: Node2D = $GuardSpawner
@onready var aksha_spawn: Marker2D = $SpawnPoints/AkshaKumar
@onready var jambumali_spawn: Marker2D = $SpawnPoints/Jambumali
@onready var ravana_court_trigger: Area2D = $Triggers/RavanaCourt
@onready var rooftop_path: Path2D = $RooftopPath
@onready var fire_overlay: ColorRect = $FireOverlay

func _ready() -> void:
	AudioManager.play_bgm("rampage")
	GameManager.unlock_power("tail_fire")
	_setup_vatika()
	_show_task("DESTROY Ashoka Vatika! Make Ravana know you were here!")
	DialogueManager.start_dialogue("vatika_destruction")

func _setup_vatika() -> void:
	var scene := load("res://scenes/objects/vatika_tree.tscn")
	if not scene:
		return
	for i in VATIKA_ITEMS:
		var tree = scene.instantiate()
		vatika_objects.add_child(tree)
		tree.global_position = Vector2(200.0 + float(i) * 55.0, 580.0)
		tree.destroyed.connect(_on_vatika_item_destroyed)

	for i in 8:
		var marker := Marker2D.new()
		guard_spawner.add_child(marker)
		marker.global_position = Vector2(300.0 + float(i) * 130.0, 500.0)

func _on_vatika_item_destroyed() -> void:
	vatika_destroyed += 1
	AudioManager.play_sfx("explosion")
	GameManager.add_score(200)
	_show_task("Vatika destroyed: %d / %d" % [vatika_destroyed, VATIKA_ITEMS])
	if vatika_destroyed >= VATIKA_ITEMS:
		_start_guard_waves()

func _start_guard_waves() -> void:
	current_task = Task.GUARDS_WAVE1
	_show_task("Guards incoming! Defeat them all!")
	_spawn_guard_wave(8)

func _spawn_guard_wave(count: int) -> void:
	wave_count += 1
	var spawned: int = 0
	var guard_scene := load("res://scenes/enemies/demon_guard.tscn")
	for spawn_point in guard_spawner.get_children():
		if spawned >= count:
			break
		if guard_scene:
			var guard = guard_scene.instantiate()
			guard.global_position = spawn_point.global_position
			guard.died.connect(_on_guard_died)
			add_child(guard)
			spawned += 1
	guards_alive = spawned

var guards_alive: int = 0
func _on_guard_died(_enemy) -> void:
	guards_alive -= 1
	if guards_alive <= 0:
		_after_wave_cleared()

func _after_wave_cleared() -> void:
	match current_task:
		Task.GUARDS_WAVE1:
			_spawn_jambumali()
		Task.BOSS_JAMBUMALI:
			_spawn_aksha_kumar()

func _spawn_jambumali() -> void:
	current_task = Task.BOSS_JAMBUMALI
	_show_task("BOSS: Jambumali — Ravana's general!")
	AudioManager.play_bgm("boss")
	var scene := load("res://scenes/enemies/boss_jambumali.tscn")
	if scene:
		var boss = scene.instantiate()
		boss.global_position = jambumali_spawn.global_position
		boss.died.connect(_on_jambumali_defeated)
		add_child(boss)
		$HUD.show_boss_health("Jambumali", boss.max_health, boss.max_health)
		boss.health_changed.connect(func(c,_m): $HUD.update_boss_health(c))

func _on_jambumali_defeated(_enemy) -> void:
	$HUD.hide_boss_health()
	AudioManager.play_bgm("rampage")
	_spawn_aksha_kumar()

func _spawn_aksha_kumar() -> void:
	current_task = Task.BOSS_AKSHA
	_show_task("BOSS: Aksha Kumar — Ravana's own son! Multi-hit combo fighter!")
	AudioManager.play_bgm("boss")
	var scene := load("res://scenes/enemies/boss_aksha_kumar.tscn")
	if scene:
		var boss = scene.instantiate()
		boss.global_position = aksha_spawn.global_position
		boss.died.connect(_on_aksha_defeated)
		add_child(boss)
		$HUD.show_boss_health("Aksha Kumar", boss.max_health, boss.max_health)
		boss.health_changed.connect(func(c,_m): $HUD.update_boss_health(c))

func _on_aksha_defeated(_enemy) -> void:
	$HUD.hide_boss_health()
	current_task = Task.CAPTURED
	_trigger_capture()

func _trigger_capture() -> void:
	_show_task("Captured by Brahmastra — taken to Ravana's court...")
	await get_tree().create_timer(2.0).timeout
	DialogueManager.start_dialogue("ravana_court")
	DialogueManager.dialogue_ended.connect(_after_ravana_court, CONNECT_ONE_SHOT)

func _after_ravana_court(_id: String) -> void:
	current_task = Task.TAIL_FIRE
	_show_task("Your tail is on fire — ESCAPE and BURN LANKA!")
	player.god_mode = true
	_activate_fire_mode()

func _activate_fire_mode() -> void:
	fire_active = true
	player.fire_mode_permanent = true
	GameManager.unlock_power("tail_fire")
	if fire_overlay:
		fire_overlay.modulate.a = 0.3
		fire_overlay.visible = true
	await get_tree().create_timer(1.0).timeout
	player.god_mode = false
	current_task = Task.BURN_LANKA
	_show_task("BURN LANKA! Jump rooftop to rooftop — burn %d buildings!" % BUILDINGS_TO_BURN)
	_start_burn_run()

func _start_burn_run() -> void:
	for building in get_tree().get_nodes_in_group("burnable"):
		if building.has_signal("burned"):
			building.burned.connect(_on_building_burned)

func _on_building_burned() -> void:
	buildings_burned += 1
	GameManager.add_score(500)
	AudioManager.play_sfx("explosion")
	_show_task("Buildings burned: %d / %d" % [buildings_burned, BUILDINGS_TO_BURN])
	if buildings_burned >= BUILDINGS_TO_BURN:
		_prepare_leap_back()

func _prepare_leap_back() -> void:
	current_task = Task.LEAP_BACK
	player.fire_mode_permanent = false
	DialogueManager.start_dialogue("lanka_burning")
	DialogueManager.dialogue_ended.connect(_do_leap_back, CONNECT_ONE_SHOT)

func _do_leap_back(_id: String) -> void:
	_show_task("LEAP back to India! JAI SHRI RAM!")
	await get_tree().create_timer(2.0).timeout
	GameManager.set_flag("lanka_burned")
	GameManager.complete_chapter(GameManager.Chapter.LANKA_RAMPAGE)

func _show_task(text: String) -> void:
	if $HUD:
		$HUD._show_notification(text, 4.0)
