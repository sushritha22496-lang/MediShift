extends Node2D

# ─── Chapter 6: Lanka War ─────────────────────────────────────────────────────
# Tasks:
# 1. Gate battle — wave combat
# 2. Boss: Dhoomraksha
# 3. Boss: Akampana
# 4. Boss: Prahasta (Lanka commander)
# 5. Lakshmana struck → emergency quest trigger
# 6. TIMED MISSION: Sanjeevani — fly to Himalayas before dawn
#    - Fight demons mid-flight
#    - Confused by magic → carry whole mountain
# 7. Lakshmana revived
# 8. Boss: Kumbhakarna (giant — wake up + climb mechanic)
# 9. Boss: Indrajit (invisible, 3 phases)
# 10. FINAL BOSS: Ravana (10 heads, 7 phases)

enum Task {
	GATE_BATTLE, BOSS_DHOOMRAKSHA, BOSS_AKAMPANA, BOSS_PRAHASTA,
	LAKSHMANA_CRISIS, SANJEEVANI_TIMED, LAKSHMANA_REVIVED,
	BOSS_KUMBHAKARNA, BOSS_INDRAJIT, BOSS_RAVANA
}
var current_task: Task = Task.GATE_BATTLE

var sanjeevani_timer_remaining: float = 180.0
var sanjeevani_active: bool = false
var gate_enemies_alive: int = 0

@onready var player: CharacterBody2D = $Player
@onready var gate_spawner: Node2D = $GateSpawner
@onready var boss_spawns: Node2D = $BossSpawns
@onready var sanjeevani_timer_label: Label = $HUD/SanjeevaniTimer
@onready var lakshmana: Node2D = $Lakshmana

func _ready() -> void:
	AudioManager.play_bgm("war")
	_show_task("STORM Lanka's gates! Fight through the demon army!")
	_start_gate_battle()

func _process(delta: float) -> void:
	if sanjeevani_active:
		sanjeevani_timer_remaining -= delta
		if sanjeevani_timer_label:
			var mins := int(sanjeevani_timer_remaining) / 60
			var secs := int(sanjeevani_timer_remaining) % 60
			sanjeevani_timer_label.text = "DAWN: %02d:%02d" % [mins, secs]
		if sanjeevani_timer_remaining <= 0.0:
			_sanjeevani_failed()
		elif sanjeevani_timer_remaining <= 30.0:
			sanjeevani_timer_label.add_theme_color_override("font_color", Color.RED)

func _start_gate_battle() -> void:
	gate_enemies_alive = 20
	for sp in gate_spawner.get_children():
		var scene := load("res://scenes/enemies/demon_guard.tscn")
		if not scene:
			gate_enemies_alive -= 1
			continue
		var e = scene.instantiate()
		e.global_position = sp.global_position
		e.died.connect(_on_gate_enemy_died)
		add_child(e)
	if gate_enemies_alive <= 0:
		_after_gate_battle()

func _on_gate_enemy_died(_e) -> void:
	gate_enemies_alive -= 1
	if gate_enemies_alive <= 0:
		_after_gate_battle()

func _after_gate_battle() -> void:
	_show_task("Gates breached! Face Dhoomraksha!")
	_spawn_boss("dhoomraksha", Task.BOSS_DHOOMRAKSHA)

func _spawn_boss(name: String, next_task: Task) -> void:
	current_task = next_task
	AudioManager.play_bgm("boss")
	var path := "res://scenes/enemies/boss_%s.tscn" % name
	var scene := load(path)
	if not scene:
		_after_boss_defeated(next_task)
		return
	var boss = scene.instantiate()
	var spawn_node := boss_spawns.get_node_or_null(name.capitalize())
	boss.global_position = spawn_node.global_position if spawn_node else Vector2(600, 400)
	boss.died.connect(func(_e): _after_boss_defeated(next_task))
	add_child(boss)
	$HUD.show_boss_health(name.capitalize(), boss.max_health, boss.max_health)
	boss.health_changed.connect(func(c,_m): $HUD.update_boss_health(c))

func _after_boss_defeated(completed_task: Task) -> void:
	$HUD.hide_boss_health()
	AudioManager.play_bgm("war")
	match completed_task:
		Task.BOSS_DHOOMRAKSHA:
			_show_task("Dhoomraksha falls! Face Akampana!")
			_spawn_boss("akampana", Task.BOSS_AKAMPANA)
		Task.BOSS_AKAMPANA:
			_show_task("Akampana defeated! Face Prahasta — Lanka's commander!")
			_spawn_boss("prahasta", Task.BOSS_PRAHASTA)
		Task.BOSS_PRAHASTA:
			_trigger_lakshmana_crisis()
		Task.BOSS_KUMBHAKARNA:
			_show_task("Kumbhakarna falls! Face Indrajit!")
			_spawn_boss("indrajit", Task.BOSS_INDRAJIT)
		Task.BOSS_INDRAJIT:
			_spawn_ravana()
		Task.BOSS_RAVANA:
			_ravana_defeated()

func _trigger_lakshmana_crisis() -> void:
	current_task = Task.LAKSHMANA_CRISIS
	DialogueManager.start_dialogue("lakshmana_falls")
	DialogueManager.dialogue_ended.connect(_start_sanjeevani_mission, CONNECT_ONE_SHOT)

func _start_sanjeevani_mission(_id: String) -> void:
	current_task = Task.SANJEEVANI_TIMED
	sanjeevani_active = true
	sanjeevani_timer_remaining = 180.0
	GameManager.unlock_power("fly")
	GameManager.unlock_power("mahima")
	if sanjeevani_timer_label:
		sanjeevani_timer_label.visible = true
	_show_task("FLY to the Himalayas! Fetch Sanjeevani before DAWN! [3 minutes]")
	get_tree().change_scene_to_file("res://scenes/chapters/ch6_sanjeevani.tscn")

func _sanjeevani_failed() -> void:
	sanjeevani_active = false
	_show_task("FAILED! Lakshmana needs the herb — try again!")
	await get_tree().create_timer(2.0).timeout
	GameManager.trigger_game_over()

func on_sanjeevani_collected() -> void:
	sanjeevani_active = false
	if sanjeevani_timer_label:
		sanjeevani_timer_label.visible = false
	current_task = Task.LAKSHMANA_REVIVED
	DialogueManager.start_dialogue("sanjeevani_quest")
	DialogueManager.dialogue_ended.connect(_lakshmana_revived, CONNECT_ONE_SHOT)
	GameManager.add_score(10000)
	AudioManager.play_sfx("sanjeevani")

func _lakshmana_revived(_id: String) -> void:
	GameManager.set_flag("lakshmana_saved")
	_show_task("Lakshmana lives! Now face Kumbhakarna!")
	_spawn_boss("kumbhakarna", Task.BOSS_KUMBHAKARNA)

func _spawn_ravana() -> void:
	current_task = Task.BOSS_RAVANA
	_show_task("FINAL BATTLE: RAVANA — 10 heads, 20 arms, 7 phases!")
	AudioManager.play_bgm("ravana_boss")
	var scene := load("res://scenes/enemies/boss_ravana.tscn")
	if not scene:
		_ravana_defeated()
		return
	var ravana = scene.instantiate()
	ravana.global_position = Vector2(800, 300)
	ravana.died.connect(func(_e): _after_boss_defeated(Task.BOSS_RAVANA))
	ravana.phase_changed.connect(_on_ravana_phase)
	add_child(ravana)
	$HUD.show_boss_health("RAVANA", ravana.max_health, ravana.max_health)
	ravana.health_changed.connect(func(c,_m): $HUD.update_boss_health(c))
	DialogueManager.start_dialogue("ravana_final")

func _on_ravana_phase(phase: int, heads: int) -> void:
	_show_task("Ravana: Phase %d — %d heads remain!" % [phase, heads])

func _ravana_defeated() -> void:
	$HUD.hide_boss_health()
	GameManager.set_flag("ravana_dead")
	AudioManager.play_bgm("victory")
	DialogueManager.start_dialogue("ravana_final")
	DialogueManager.dialogue_ended.connect(func(_id):
		GameManager.complete_chapter(GameManager.Chapter.LANKA_WAR), CONNECT_ONE_SHOT)

func _show_task(text: String) -> void:
	if $HUD:
		$HUD._show_notification(text, 4.0)
