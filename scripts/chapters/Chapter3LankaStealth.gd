extends Node2D

# ─── Chapter 3: Lanka Infiltration ───────────────────────────────────────────
# Tasks:
# 1. Defeat/bypass Lankini at the gate (use Anima to shrink through)
# 2. Stealth through palace zone 1 — avoid guards
# 3. Search Ravana's inner chambers (no Sita)
# 4. Search Mandodari's palace (no Sita)
# 5. Search Ashoka Vatika → find Sita
# 6. Witness Ravana's threats
# 7. Deliver ring to Sita → receive Chudamani

enum Task {
	ENTER_GATE, ZONE1_STEALTH, ZONE2_STEALTH, FIND_SITA,
	WITNESS_RAVANA, DELIVER_RING, RECEIVE_CHUDAMANI
}
var current_task: Task = Task.ENTER_GATE

var guards_avoided: int = 0
const GUARDS_NEEDED := 8
var is_detected: bool = false
var detection_timer: float = 0.0
const DETECTION_RESET := 3.0
var search_zones_cleared: int = 0

@onready var player: CharacterBody2D = $Player
@onready var lankini: CharacterBody2D = $Lankini
@onready var guards_zone1: Node2D = $Zone1Guards
@onready var guards_zone2: Node2D = $Zone2Guards
@onready var sita_trigger: Area2D = $Triggers/SitaFound
@onready var ring_trigger: Area2D = $Triggers/RingDelivery
@onready var alarm_label: Label = $HUD/AlarmLabel
@onready var stealth_meter: ProgressBar = $HUD/StealthMeter

func _ready() -> void:
	AudioManager.play_bgm("lanka_night")
	GameManager.unlock_power("anima")
	_setup_lankini()
	_setup_guards()
	sita_trigger.body_entered.connect(_on_sita_found)
	ring_trigger.body_entered.connect(_on_ring_delivery)
	_show_task("Enter Lanka! Shrink [2] to slip past Lankini at the gate")
	DialogueManager.start_dialogue("lanka_entry")

func _setup_lankini() -> void:
	if lankini:
		lankini.died.connect(_on_lankini_defeated)

const ZONE1_GUARD_POSITIONS: Array[Vector2] = [
	Vector2(550, 550), Vector2(800, 500), Vector2(1050, 550), Vector2(1300, 500)
]
const ZONE2_GUARD_POSITIONS: Array[Vector2] = [
	Vector2(1550, 550), Vector2(1800, 500), Vector2(2050, 550)
]

func _setup_guards() -> void:
	_spawn_guards(guards_zone1, ZONE1_GUARD_POSITIONS)
	_spawn_guards(guards_zone2, ZONE2_GUARD_POSITIONS)

func _spawn_guards(zone: Node2D, positions: Array[Vector2]) -> void:
	var scene := load("res://scenes/enemies/demon_guard.tscn")
	if not scene:
		return
	for pos in positions:
		var guard = scene.instantiate()
		zone.add_child(guard)
		guard.global_position = pos
		guard.player_detected.connect(_on_guard_alert)

func _process(delta: float) -> void:
	_update_detection(delta)

func _update_detection(delta: float) -> void:
	if is_detected:
		detection_timer -= delta
		if detection_timer <= 0.0:
			is_detected = false
			alarm_label.visible = false
			stealth_meter.value = 0.0

func _on_guard_alert() -> void:
	is_detected = true
	detection_timer = DETECTION_RESET
	alarm_label.visible = true
	alarm_label.text = "DETECTED!"
	AudioManager.play_sfx("boss_roar")

func _on_lankini_defeated(_enemy) -> void:
	current_task = Task.ZONE1_STEALTH
	_show_task("Slip through Lanka's corridors undetected — find Sita!")
	DialogueManager.start_dialogue("lanka_entry")

func _on_sita_found(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	sita_trigger.monitoring = false
	current_task = Task.WITNESS_RAVANA
	GameManager.set_flag("found_sita")
	_show_task("Stay hidden — watch Ravana threaten Sita...")
	DialogueManager.start_dialogue("sita_found")
	DialogueManager.dialogue_ended.connect(_after_sita_found, CONNECT_ONE_SHOT)

func _after_sita_found(_id: String) -> void:
	current_task = Task.DELIVER_RING
	_show_task("Approach Sita carefully and deliver Rama's ring [E]")

func _on_ring_delivery(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	ring_trigger.monitoring = false
	current_task = Task.RECEIVE_CHUDAMANI
	GameManager.set_flag("delivered_ring")
	DialogueManager.start_dialogue("ring_delivery")
	DialogueManager.dialogue_ended.connect(_after_ring_delivery, CONNECT_ONE_SHOT)

func _after_ring_delivery(_id: String) -> void:
	_show_task("Ring delivered. Chudamani received. Time to make Lanka remember you!")
	await get_tree().create_timer(2.0).timeout
	GameManager.complete_chapter(GameManager.Chapter.LANKA_STEALTH)

func _show_task(text: String) -> void:
	if $HUD:
		$HUD._show_notification(text, 4.0)
