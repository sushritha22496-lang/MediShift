extends Node

class_name GameManager

static var instance: GameManager

var progression: GameProgression
var input_handler: InputHandler
var hud: HUDSystem
var active_scene: Node3D
var player: RamaController
var npc_manager: NPCManager

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

	set_process_mode(PROCESS_MODE_ALWAYS)

func set_scene(scene: Node3D) -> void:
	active_scene = scene
	player = scene.get_node_or_null("Characters/Rama")

func get_player() -> RamaController:
	return player

func get_progression() -> GameProgression:
	return progression

func get_input_handler() -> InputHandler:
	return input_handler

func _on_pause() -> void:
	get_tree().paused = not get_tree().is_paused()

static func get_instance() -> GameManager:
	return instance
