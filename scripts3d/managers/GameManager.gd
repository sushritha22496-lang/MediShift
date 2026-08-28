extends Node

class_name GameManager

static var instance: GameManager

var progression: GameProgression
var input_handler: InputHandler
var hud: HUDSystem
var active_scene: Node3D
var player: RamaController
var npc_manager: NPCManager

# Game systems
var dialogue_system: DialogueSystem
var quest_system: QuestSystem
var inventory_system: InventorySystem
var combat_feedback: CombatFeedbackManager

# Game state
var is_paused: bool = false
var current_level: String = ""
var play_time: float = 0.0
var game_started: bool = false

signal game_paused
signal game_resumed
signal scene_changed(scene_name: String)
signal level_completed(level_name: String)

func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	progression = GameProgression.new()
	add_child(progression)

	input_handler = InputHandler.new()
	add_child(input_handler)
	input_handler.pause_toggled.connect(_on_pause)

	# Initialize game systems
	dialogue_system = DialogueSystem.new()
	add_child(dialogue_system)

	quest_system = QuestSystem.new()
	add_child(quest_system)

	combat_feedback = CombatFeedbackManager.new()
	add_child(combat_feedback)

	set_process_mode(PROCESS_MODE_ALWAYS)

func _process(delta: float) -> void:
	if game_started and not is_paused:
		play_time += delta

func set_scene(scene: Node3D) -> void:
	active_scene = scene
	player = scene.get_node_or_null("Characters/Rama")

	# Initialize player inventory if not already done
	if player and not player.inventory:
		player.inventory = InventorySystem.new()
		player.add_child(player.inventory)
		inventory_system = player.inventory
	else:
		inventory_system = player.inventory if player else null

	# Initialize combat feedback with player camera
	if player and player.camera:
		combat_feedback.initialize(player.camera)

	scene_changed.emit(scene.name)

func get_player() -> RamaController:
	return player

func get_progression() -> GameProgression:
	return progression

func get_input_handler() -> InputHandler:
	return input_handler

func get_dialogue_system() -> DialogueSystem:
	return dialogue_system

func get_quest_system() -> QuestSystem:
	return quest_system

func get_inventory() -> InventorySystem:
	return inventory_system

func get_combat_feedback() -> CombatFeedbackManager:
	return combat_feedback

func start_game() -> void:
	game_started = true
	play_time = 0.0

func end_game() -> void:
	game_started = false

func complete_level(level_name: String) -> void:
	current_level = level_name
	level_completed.emit(level_name)

func get_play_time() -> float:
	return play_time

func get_game_stats() -> Dictionary:
	return {
		"play_time": play_time,
		"current_level": current_level,
		"player_level": progression.player_level if progression else 0,
		"quests_completed": quest_system.completed_quests.size() if quest_system else 0,
		"xp_earned": quest_system.get_total_xp_earned() if quest_system else 0
	}

func _on_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused
	if is_paused:
		game_paused.emit()
	else:
		game_resumed.emit()

static func get_instance() -> GameManager:
	return instance
