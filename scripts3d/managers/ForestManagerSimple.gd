extends Node3D

class_name ForestManagerSimple

@onready var rama: RamaControllerSimple = $Characters/Rama
@onready var hanuman: HanumanAISimple = $Characters/Hanuman
@onready var main_label: Label = $HUD/MainLabel
@onready var objective_label: Label = $HUD/ObjectiveLabel
@onready var debug_label: Label = $HUD/DebugLabel

var has_met: bool = false
var game_started: bool = false

func _ready() -> void:
	rama.rama_called.connect(_on_rama_called)
	hanuman.rama_detected.connect(_on_hanuman_detects_rama)
	hanuman.meeting_initiated.connect(_on_meeting_initiated)
	hanuman.agreement_reached.connect(_on_hanuman_agrees)

	hanuman.set_rama_reference(rama)

	_show_hud_message("🌲 BADRACHALAM FOREST\n\nWASD: Move | Shift: Run | Space: Call | E: Interact\n\nSearch for Hanuman...")

	game_started = true

func _on_rama_called(intensity: float) -> void:
	if not game_started or has_met:
		return

	hanuman.detect_rama_call(rama, intensity)
	_show_hud_message("📢 Rama: SEETHA! SEETHA!")

func _on_hanuman_detects_rama() -> void:
	_show_hud_message("🐵 Hanuman hears the call and investigates...")

func _on_meeting_initiated() -> void:
	_show_hud_message("🐵 Hanuman: Who calls with such sorrow?\n\n🟦 Rama: I am Rama, seeking my beloved Sita!")
	await get_tree().create_timer(2.0).timeout
	_show_hud_message("🐵 Hanuman: I will help you!\n\n✅ HANUMAN JOINS YOUR QUEST!")

func _on_hanuman_agrees() -> void:
	has_met = true
	await get_tree().create_timer(1.0).timeout
	print("\n" + "="*50)
	print("✅ CHAPTER 1 COMPLETE")
	print("="*50)
	print("Rama has found an ally!")
	print("="*50 + "\n")

func _show_hud_message(message: String) -> void:
	if main_label:
		main_label.text = message

func _process(_delta: float) -> void:
	if debug_label:
		var rama_pos = rama.global_position
		var hanuman_pos = hanuman.global_position
		var distance = rama_pos.distance_to(hanuman_pos)

		debug_label.text = "Debug Info:\nPosition: (%.1f, %.1f, %.1f)\nDistance to Hanuman: %.1fm\nHanuman State: %s\nMet: %s" % [
			rama_pos.x, rama_pos.y, rama_pos.z,
			distance,
			HanumanAISimple.State.keys()[hanuman.current_state],
			"Yes" if has_met else "No"
		]

	if Input.is_action_just_pressed("ui_cancel"):
		print("Rama pos:", rama.global_position)
		print("Hanuman pos:", hanuman.global_position)
		print("Distance:", rama.global_position.distance_to(hanuman.global_position))
		print("Hanuman state:", HanumanAISimple.State.keys()[hanuman.current_state])
