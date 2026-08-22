extends Node2D

# ─── Chapter 1: Kishkindha ────────────────────────────────────────────────────
# Tasks:
# 1. Patrol Rishyamukha mountain, spot Rama & Lakshmana
# 2. Meet Rama → trigger dialogue
# 3. Escort Sugriva → alliance formation
# 4. Destroy 7 Sala trees (combat tutorial)
# 5. Boss: Dundhubi monster
# 6. Witness Vali's defeat
# 7. Search parties sent for Sita

enum Task {
	SPOT_WARRIORS,
	MEET_RAMA,
	ESCORT_SUGRIVA,
	SEVEN_SALA_TREES,
	BOSS_DUNDHUBI,
	VALI_FIGHT,
	SEARCH_PARTIES
}

var current_task: Task = Task.SPOT_WARRIORS
var sala_trees_destroyed: int = 0
const SALA_TREES_NEEDED := 7

@onready var player: CharacterBody2D = $Player
@onready var task_marker: Node2D = $TaskMarkers/Marker1
@onready var dundhubi_spawn: Marker2D = $SpawnPoints/Dundhubi
@onready var dialogue_trigger_rama: Area2D = $Triggers/RamaMeeting
@onready var sala_trees_group: Node2D = $SalaTrees
@onready var chapter_camera: Camera2D = $Camera2D

func _ready() -> void:
	AudioManager.play_bgm("kishkindha")
	GameManager.set_state(GameManager.GameState.PLAYING)
	dialogue_trigger_rama.body_entered.connect(_trigger_rama_meeting)
	_setup_sala_trees()
	_show_task("Find the two warriors on Rishyamukha mountain")
	GameManager.chapter_started.emit(GameManager.Chapter.KISHKINDHA)

func _setup_sala_trees() -> void:
	for tree in sala_trees_group.get_children():
		if tree.has_signal("destroyed"):
			tree.destroyed.connect(_on_sala_tree_destroyed)

func _trigger_rama_meeting(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	dialogue_trigger_rama.monitoring = false
	DialogueManager.start_dialogue("rama_first_meeting")
	DialogueManager.dialogue_ended.connect(_after_rama_meeting, CONNECT_ONE_SHOT)

func _after_rama_meeting(_id: String) -> void:
	current_task = Task.MEET_RAMA
	GameManager.set_flag("met_rama")
	GameManager.unlock_power("gada")
	_show_task("Follow Sugriva to Rishyamukha peak")
	current_task = Task.ESCORT_SUGRIVA

func _on_sala_tree_destroyed() -> void:
	sala_trees_destroyed += 1
	AudioManager.play_sfx("explosion")
	if sala_trees_destroyed >= SALA_TREES_NEEDED:
		_all_sala_destroyed()
	else:
		_show_task("Destroy Sala trees: %d / %d" % [sala_trees_destroyed, SALA_TREES_NEEDED])

func _all_sala_destroyed() -> void:
	current_task = Task.BOSS_DUNDHUBI
	_show_task("Defeat the Dundhubi demon!")
	_spawn_dundhubi()

func _spawn_dundhubi() -> void:
	var dundhubi_scene := load("res://scenes/enemies/boss_dundhubi.tscn")
	if dundhubi_scene:
		var dundhubi = dundhubi_scene.instantiate()
		dundhubi.global_position = dundhubi_spawn.global_position
		dundhubi.died.connect(_on_dundhubi_defeated)
		add_child(dundhubi)
		AudioManager.play_bgm("boss")
		$HUD.show_boss_health("Dundhubi", dundhubi.max_health, dundhubi.max_health)
		dundhubi.health_changed.connect(func(c, _m): $HUD.update_boss_health(c))

func _on_dundhubi_defeated(_enemy) -> void:
	$HUD.hide_boss_health()
	AudioManager.play_bgm("kishkindha")
	current_task = Task.VALI_FIGHT
	DialogueManager.start_dialogue("vali_context")
	DialogueManager.dialogue_ended.connect(_after_vali_context, CONNECT_ONE_SHOT)

func _after_vali_context(_id: String) -> void:
	current_task = Task.SEARCH_PARTIES
	_show_task("Alliance formed! Prepare the Vanara search parties for Sita")
	GameManager.set_flag("alliance_formed")
	GameManager.set_flag("vali_dead")
	await get_tree().create_timer(3.0).timeout
	_complete_chapter()

func _complete_chapter() -> void:
	_show_task("Chapter I Complete! The Great Leap awaits...")
	await get_tree().create_timer(2.0).timeout
	GameManager.complete_chapter(GameManager.Chapter.KISHKINDHA)

func _show_task(text: String) -> void:
	if $HUD:
		$HUD._show_notification(text, 4.0)
