extends Node3D

class_name ForestManagerSimple

@onready var rama: RamaControllerSimple = $Characters/Rama
@onready var hanuman: HanumanAISimple = $Characters/Hanuman
@onready var main_label: Label = $HUD/MainLabel
@onready var objective_label: Label = $HUD/ObjectiveLabel
@onready var debug_label: Label = $HUD/DebugLabel
@onready var inventory_label: Label = $HUD/InventoryLabel
@onready var quest_label: Label = $HUD/QuestLabel

var has_met: bool = false
var game_started: bool = false
var dialogue_system: DialogueSimple
var quest_system: QuestSimple
var combat_system: CombatSimple
var monkey_scouts: Array[MonkeyScoutSimple] = []

func _ready() -> void:
	dialogue_system = DialogueSimple.new()
	add_child(dialogue_system)

	quest_system = QuestSimple.new()
	add_child(quest_system)

	combat_system = CombatSimple.new()
	add_child(combat_system)

	rama.rama_called.connect(_on_rama_called)
	rama.inventory_updated.connect(_on_inventory_changed)

	hanuman.rama_detected.connect(_on_hanuman_detects_rama)
	hanuman.meeting_initiated.connect(_on_meeting_initiated)
	hanuman.agreement_reached.connect(_on_hanuman_agrees)
	hanuman.set_rama_reference(rama)

	_find_monkey_scouts()
	_setup_monkey_scouts()

	_show_hud_message("🌲 BADRACHALAM FOREST\n\nWASD: Move | Shift: Run | Space: Call\n\nSearch for Hanuman...")

	game_started = true

func _find_monkey_scouts() -> void:
	for child in get_tree().get_nodes_in_group("npcs"):
		if child is MonkeyScoutSimple:
			monkey_scouts.append(child)

func _setup_monkey_scouts() -> void:
	for scout in monkey_scouts:
		scout.set_rama_reference(rama)
		scout.monkey_dialogue.connect(_on_monkey_dialogue)

func _on_rama_called(intensity: float) -> void:
	if not game_started or has_met:
		return

	hanuman.detect_rama_call(rama, intensity)
	_show_hud_message("📢 Rama: SEETHA! SEETHA!")

	for scout in monkey_scouts:
		scout.detect_call(rama)

func _on_hanuman_detects_rama() -> void:
	_show_hud_message("🐵 Hanuman hears the call and investigates...")

func _on_meeting_initiated() -> void:
	_show_hud_message("🐵 Hanuman: Who calls with such sorrow?\n\n🟦 Rama: I am Rama, seeking my beloved Sita!")
	await get_tree().create_timer(2.0).timeout
	_show_hud_message("🐵 Hanuman: I will help you!\n\n✅ HANUMAN JOINS YOUR QUEST!")
	quest_system.complete_quest("find_hanuman")

func _on_hanuman_agrees() -> void:
	has_met = true
	await get_tree().create_timer(1.0).timeout
	print("\n" + "="*50)
	print("✅ CHAPTER 1 COMPLETE")
	print("="*50)

func _on_monkey_dialogue(text: String) -> void:
	_show_hud_message(text)

func _on_inventory_changed() -> void:
	if inventory_label:
		inventory_label.text = rama.get_inventory_text()

func _show_hud_message(message: String) -> void:
	if main_label:
		main_label.text = message

func _process(_delta: float) -> void:
	if debug_label:
		var rama_pos = rama.global_position
		var hanuman_pos = hanuman.global_position
		var distance = rama_pos.distance_to(hanuman_pos)

		debug_label.text = "Debug Info:\nPosition: (%.1f, %.1f, %.1f)\nDistance: %.1fm\nState: %s\nMet: %s" % [
			rama_pos.x, rama_pos.y, rama_pos.z,
			distance,
			HanumanAISimple.State.keys()[hanuman.current_state],
			"Yes" if has_met else "No"
		]

	if quest_label and quest_system:
		quest_label.text = quest_system.get_quest_list_text()

	if Input.is_action_just_pressed("ui_cancel"):
		print("Rama pos:", rama.global_position)
		print("Hanuman pos:", hanuman.global_position)
		print("Distance:", rama.global_position.distance_to(hanuman.global_position))
		print("Hanuman state:", HanumanAISimple.State.keys()[hanuman.current_state])
		print("Inventory:", rama.get_inventory_text())
