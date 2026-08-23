extends Node3D

class_name ForestManager

# References
@onready var rama: RamaController = $Characters/Rama
@onready var hanuman: HanumanAI = $Characters/Hanuman
@onready var monkeys: Node3D = $Characters/Monkeys
@onready var main_label: Label = $HUD/MainLabel
@onready var objective_label: Label = $HUD/ObjectiveLabel

# State
var has_met: bool = false
var game_started: bool = false

func _ready() -> void:
	# Connect Rama's calling signal to Hanuman
	rama.rama_called.connect(_on_rama_called)

	# Connect Hanuman's signals
	hanuman.rama_detected.connect(_on_hanuman_detects_rama)
	hanuman.meeting_initiated.connect(_on_meeting_initiated)
	hanuman.agreement_reached.connect(_on_hanuman_agrees)

	# Set Hanuman's reference to Rama
	hanuman.set_rama_reference(rama)

	# Show initial HUD message
	_show_hud_message("🌲 BADRACHALAM FOREST - The Search for Sita\n\nRama searches desperately through the forest...\n\nPress SPACE to call for Sita!\nMonkeys wander the forest with Hanuman...")

	game_started = true

func _on_rama_called(intensity: float) -> void:
	"""Called when Rama calls for Sita"""
	if not game_started or has_met:
		return

	# Let Hanuman hear the call
	hanuman.detect_rama_call(rama, intensity)

	# Update HUD
	_show_hud_message("📢 Rama: SEETHA! SEETHA! WHERE ARE YOU?")

func _on_hanuman_detects_rama() -> void:
	"""Hanuman has heard Rama and is becoming curious"""
	_show_hud_message("🐵 Hanuman hears a cry of anguish...\nHe investigates the source of the voice...")

func _on_meeting_initiated() -> void:
	"""Hanuman is meeting Rama face to face"""
	_show_hud_message("🐵 Hanuman: Who are you? Why do you call with such sorrow?")
	await get_tree().create_timer(2.0).timeout

	_show_hud_message("🟦 Rama: I am Rama, son of Dasharatha. My beloved Sita has been taken by the demon Ravana. I search for her with all my might.")
	await get_tree().create_timer(3.0).timeout

	_show_hud_message("🐵 Hanuman: Sita? Taken by Ravana? I know of Ravana's Lanka. It lies across the ocean, far to the south.")
	await get_tree().create_timer(2.5).timeout

	_show_hud_message("🐵 Hanuman: I am Hanuman, mighty warrior of the monkey kingdom. I will help you find Sita!")
	await get_tree().create_timer(2.0).timeout

	_show_hud_message("🐵 Hanuman: I swear by my strength and loyalty - we shall bring her back!")

func _on_hanuman_agrees() -> void:
	"""Hanuman has agreed to help Rama"""
	has_met = true

	await get_tree().create_timer(2.0).timeout

	_show_hud_message("✅ HANUMAN JOINS THE QUEST!\n\nTogether, Rama and Hanuman begin their journey to Lanka...")

	await get_tree().create_timer(4.0).timeout

	print("\n" + "="*60)
	print("✅ CHAPTER 1 COMPLETE")
	print("="*60)
	print("Rama has found his ally in Hanuman")
	print("Together they will search for Sita")
	print("="*60 + "\n")

	# Chapter complete - transition could happen here
	# For now, just show the completion state

func _show_hud_message(message: String) -> void:
	"""Display a message on the HUD"""
	if main_label:
		main_label.text = message
	if objective_label and "Objective:" not in message:
		objective_label.text = "📍 " + message.split("\n")[0]

func _process(_delta: float) -> void:
	# Optional: Show debug info
	if Input.is_action_just_pressed("ui_cancel"):
		print("Rama position:", rama.global_position)
		print("Hanuman position:", hanuman.global_position)
		print("Distance:", rama.global_position.distance_to(hanuman.global_position))
		print("Hanuman state:", HanumanAI.State.keys()[hanuman.current_state])
