extends Node

class_name GameController

static var instance: GameController

var progression: GameProgression
var tutorial: TutorialManager
var quests: SimpleQuestSystem
var save_manager: SaveManager
var event_bus: EventBus
var input_handler: InputHandler

var game_state: Dictionary = {
	"running": false,
	"paused": false,
	"score": 0,
	"playtime": 0.0
}

func _ready() -> void:
	if instance == null:
		instance = self
	else:
		queue_free()
		return

	_initialize_systems()
	set_process_mode(PROCESS_MODE_ALWAYS)

func _initialize_systems() -> void:
	progression = GameProgression.new()
	add_child(progression)

	tutorial = TutorialManager.new()
	add_child(tutorial)

	quests = SimpleQuestSystem.new()
	add_child(quests)

	save_manager = SaveManager.new()
	add_child(save_manager)

	event_bus = EventBus.new()
	add_child(event_bus)

	input_handler = InputHandler.new()
	add_child(input_handler)

func _process(delta: float) -> void:
	if game_state["running"] and not get_tree().paused:
		game_state["playtime"] += delta

func start_game() -> void:
	game_state["running"] = true
	game_state["score"] = 0
	game_state["playtime"] = 0.0
	tutorial.current_step = TutorialManager.TutorialStep.INTRO

func pause_game() -> void:
	game_state["paused"] = true
	get_tree().paused = true

func resume_game() -> void:
	game_state["paused"] = false
	get_tree().paused = false

func end_game() -> void:
	game_state["running"] = false
	save_manager.save_game(0)

func add_score(points: int) -> void:
	game_state["score"] += points
	event_bus.emit_event("score_changed", {"score": game_state["score"]})

func get_playtime() -> float:
	return game_state["playtime"]

static func get() -> GameController:
	return instance
