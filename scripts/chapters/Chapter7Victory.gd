extends Node2D

# ─── Chapter 7: Victory & Epilogue ────────────────────────────────────────────
# Tasks:
# 1. Sita freed — reunion cutscene
# 2. Agni Pariksha (fire trial) — protect Sita as she enters fire
# 3. Board Pushpaka Vimana (flying palace)
# 4. Fly over Lanka, then ocean, then India
# 5. Land in Ayodhya — grand celebration
# 6. Rama Rajyabhisheka ceremony
# 7. Credits / Score Screen

enum Task { SITA_FREED, AGNI_PARIKSHA, VIMANA_BOARDING, FLY_HOME, AYODHYA, CORONATION, CREDITS }
var current_task: Task = Task.SITA_FREED

var flight_progress: float = 0.0
const FLIGHT_DISTANCE := 5000.0

@onready var player: CharacterBody2D = $Player
@onready var vimana: Node2D = $PushpakaVimana
@onready var celebration_particles: GPUParticles2D = $Celebration
@onready var lamp_group: Node2D = $Lamps
@onready var credits_panel: Control = $CreditsPanel

func _ready() -> void:
	AudioManager.play_bgm("victory")
	_start_victory_sequence()

func _start_victory_sequence() -> void:
	await get_tree().create_timer(1.0).timeout
	DialogueManager.start_dialogue("sita_freed")
	DialogueManager.dialogue_ended.connect(_after_sita_freed, CONNECT_ONE_SHOT)

func _after_sita_freed(_id: String) -> void:
	current_task = Task.AGNI_PARIKSHA
	GameManager.set_flag("sita_freed")
	_show_task("Agni Pariksha — Protect Sita as she enters the sacred fire...")
	_play_agni_pariksha()

func _play_agni_pariksha() -> void:
	var fire := ColorRect.new()
	fire.size = Vector2(60, 90)
	fire.position = Vector2(430, 375) + Vector2(0, -30)
	fire.color = Color(0.95, 0.4, 0.05, 0.0)
	add_child(fire)
	var flicker := create_tween().set_loops(8)
	flicker.tween_property(fire, "color:a", 0.75, 0.25)
	flicker.tween_property(fire, "color:a", 0.4, 0.25)
	AudioManager.play_sfx("tail_fire")

	await get_tree().create_timer(4.0).timeout

	var fade := create_tween()
	fade.tween_property(fire, "color:a", 0.0, 1.0)
	await fade.finished
	fire.queue_free()

	_show_task("Sita emerges pure! Agni — God of Fire — proclaims her innocence!")
	await get_tree().create_timer(3.0).timeout
	_board_vimana()

func _board_vimana() -> void:
	current_task = Task.VIMANA_BOARDING
	_show_task("Board the Pushpaka Vimana — the flying palace!")
	GameManager.unlock_power("fly")
	await get_tree().create_timer(2.0).timeout
	current_task = Task.FLY_HOME
	_show_task("Fly home to Ayodhya! Cross the skies!")
	_start_flight_home()

func _start_flight_home() -> void:
	_fly_home_loop()

func _fly_home_loop() -> void:
	while flight_progress < FLIGHT_DISTANCE:
		await get_tree().process_frame
		if player:
			flight_progress += 50.0
		var pct := flight_progress / FLIGHT_DISTANCE * 100.0
		if pct < 30.0:
			_show_task("Flying over Lanka...")
		elif pct < 60.0:
			_show_task("Crossing the great ocean...")
		elif pct < 90.0:
			_show_task("India! Home is near!")
	_land_in_ayodhya()

func _land_in_ayodhya() -> void:
	current_task = Task.AYODHYA
	_show_task("AYODHYA! Home at last!")
	AudioManager.play_sfx("roar")
	DialogueManager.start_dialogue("ayodhya_return")
	DialogueManager.dialogue_ended.connect(_start_celebration, CONNECT_ONE_SHOT)

func _start_celebration(_id: String) -> void:
	if celebration_particles:
		celebration_particles.emitting = true
	_light_all_lamps()
	await get_tree().create_timer(3.0).timeout
	_start_coronation()

func _light_all_lamps() -> void:
	for lamp in lamp_group.get_children():
		if lamp.has_method("light"):
			lamp.light()

func _start_coronation() -> void:
	current_task = Task.CORONATION
	_show_task("RAMA RAJYABHISHEKA — The Coronation of King Rama!")
	await get_tree().create_timer(5.0).timeout
	_show_credits()

func _show_credits() -> void:
	current_task = Task.CREDITS
	if credits_panel:
		credits_panel.visible = true
	_display_final_score()

func _display_final_score() -> void:
	var final_data := {
		"score": GameManager.score,
		"enemies": GameManager.enemies_defeated,
		"bosses": GameManager.bosses_defeated.size(),
		"chapters": 7
	}
	_show_task("JAI SHRI RAM! Score: %d | Enemies: %d | Bosses: %d" % [
		final_data.score, final_data.enemies, final_data.bosses
	])
	SaveSystem.delete_save()
	await get_tree().create_timer(8.0).timeout
	GameManager.quit_to_menu()

func _show_task(text: String) -> void:
	if $HUD:
		$HUD._show_notification(text, 5.0)
