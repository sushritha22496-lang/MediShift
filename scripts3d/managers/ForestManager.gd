extends Node3D

class_name ForestManager

# References
@onready var rama: RamaController = $Characters/Rama
@onready var hanuman: HanumanAI = $Characters/Hanuman
@onready var monkeys: Node3D = $Characters/Monkeys
@onready var main_label: Label = $HUD/MainLabel
@onready var objective_label: Label = $HUD/ObjectiveLabel
@onready var inventory_label: Label = $HUD/InventoryLabel
@onready var debug_label: Label = $HUD/DebugLabel

# Systems
var quest_system: QuestSystem
var location_manager: LocationManager

# State
var has_met: bool = false
var game_started: bool = false

func _ready() -> void:
	quest_system = QuestSystem.new()
	add_child(quest_system)

	location_manager = LocationManager.new()
	add_child(location_manager)

	# Connect Rama's calling signal to Hanuman
	rama.rama_called.connect(_on_rama_called)
	rama.inventory.item_added.connect(_on_item_collected)

	# Connect Hanuman's signals
	hanuman.rama_detected.connect(_on_hanuman_detects_rama)
	hanuman.meeting_initiated.connect(_on_meeting_initiated)
	hanuman.agreement_reached.connect(_on_hanuman_agrees)

	# Set Hanuman's reference to Rama
	hanuman.set_rama_reference(rama)

	# Connect quest signals
	quest_system.quest_completed.connect(_on_quest_completed)
	quest_system.objective_updated.connect(_on_objective_updated)

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

	print("\n" + "=".repeat(60))
	print("✅ CHAPTER 1 COMPLETE")
	print("=".repeat(60))
	print("Rama has found his ally in Hanuman")
	print("Together they will search for Sita")
	print("=".repeat(60) + "\n")

	# Chapter complete - transition could happen here
	# For now, just show the completion state

func _show_hud_message(message: String) -> void:
	if main_label:
		main_label.text = message
	if objective_label and "Objective:" not in message:
		objective_label.text = "📍 " + message.split("\n")[0]

func _on_item_collected(item_name: String, quantity: int) -> void:
	_update_inventory_display()

func _on_quest_completed(quest: QuestSystem.Quest) -> void:
	_show_hud_message("✅ QUEST COMPLETE: " + quest.title)

func _on_objective_updated(objective: String) -> void:
	if objective_label:
		objective_label.text = "📍 " + objective

func _update_inventory_display() -> void:
	if not inventory_label or not rama or not rama.inventory:
		return
	var inv = rama.inventory.get_inventory()
	if inv.is_empty():
		inventory_label.text = "🎒 Inventory: Empty"
	else:
		var txt = "🎒 Inventory:\n"
		for item_name in inv.keys():
			txt += "%s: %d\n" % [item_name, inv[item_name]]
		inventory_label.text = txt.strip_edges()

func _process(_delta: float) -> void:
	# Update inventory display
	_update_inventory_display()
	_update_debug_display()

	# Optional: Show debug info
	if Input.is_action_just_pressed("ui_cancel"):
		print("Rama position:", rama.global_position)
		print("Hanuman position:", hanuman.global_position)
		print("Distance:", rama.global_position.distance_to(hanuman.global_position))
		print("Hanuman state:", HanumanAI.State.keys()[hanuman.current_state])

func _update_debug_display() -> void:
	if not debug_label or not rama or not hanuman:
		return
	var dist = rama.global_position.distance_to(hanuman.global_position)
	var spd = rama.run_speed if Input.is_action_pressed("dash") else rama.walk_speed
	var eta = "Reached!" if dist < rama.detection_range else "%.1fs" % (dist / spd)
	var rp = rama.global_position
	var hp = hanuman.global_position
	debug_label.text = "FPS: %d | Rama: (%.1f, %.1f, %.1f) | Hanuman: (%.1f, %.1f, %.1f) | Dist: %.1fm | ETA: %s | State: %s" % [
		Engine.get_frames_per_second(), rp.x, rp.y, rp.z, hp.x, hp.y, hp.z, dist, eta,
		HanumanAI.State.keys()[hanuman.current_state]
	]
