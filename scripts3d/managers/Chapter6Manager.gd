extends Node3D

class_name Chapter6Manager

@onready var rama: RamaController = $Characters/Rama
var progression: GameProgression
var main_label: Label
var objective_label: Label
var dialogue_label: Label
var sita_found: bool = false
var game_completed: bool = false

func _ready() -> void:
	progression = GameProgression.new()
	add_child(progression)

	main_label = $HUD/MainLabel if has_node("HUD/MainLabel") else Label.new()
	objective_label = $HUD/ObjectiveLabel if has_node("HUD/ObjectiveLabel") else Label.new()
	dialogue_label = $HUD/DialogueLabel if has_node("HUD/DialogueLabel") else Label.new()

	progression.current_stage = GameProgression.Stage.RESCUE_SITA
	progression.advance_stage()

	_create_environment()
	_show_message("🏰 CHAPTER 6: RESCUE AND RETURN\n\nWithin the throne room of Lanka...\nSita awaits her rescue!\n\nPress SPACE to meet your beloved!")

	if rama:
		rama.rama_called.connect(_on_rama_called)
		await get_tree().create_timer(1.0).timeout
		_create_sita_npc()

func _create_sita_npc() -> void:
	var sita = Node3D.new()
	sita.name = "Sita"
	sita.position = Vector3(0, 0, 30)

	var sita_model = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 1.0
	sita_model.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.6, 0.4)
	sita_model.set_surface_override_material(0, mat)
	sita_model.position.y = 1.0
	sita.add_child(sita_model)

	var sita_collision = CollisionShape3D.new()
	sita_collision.shape = CapsuleShape3D.new()
	sita_collision.shape.radius = 0.5
	sita_collision.shape.height = 2.0
	sita.add_child(sita_collision)

	if has_node("Characters"):
		$Characters.add_child(sita)
	else:
		add_child(sita)

func _on_rama_called(intensity: float) -> void:
	if sita_found or game_completed:
		return
	_rescue_sita()

func _rescue_sita() -> void:
	sita_found = true

	var dialogues = [
		["🟦 Rama: Sita! I have come for you!", 2.0],
		["👑 Sita: Rama! You came for me...", 2.5],
		["🟦 Rama: Yes, my beloved. I swore to bring you back.", 2.5],
		["👑 Sita: I knew you would succeed. You are my hero.", 2.0],
		["🐵 Hanuman: The quest is complete! Rama has saved Sita!", 2.5],
		["🏆 QUEST COMPLETE: Return to Ayodhya!", 3.0]
	]

	for dialogue in dialogues:
		_show_dialogue(dialogue[0])
		await get_tree().create_timer(dialogue[1]).timeout

	_complete_game()

func _complete_game() -> void:
	game_completed = true

	_show_message("""
🎉 THE RAMAYANA: COMPLETE!

✅ Rama met Hanuman
✅ Gathered monkey army
✅ Journeyed to Lanka
✅ Built bridge across ocean
✅ Defeated Ravana
✅ Rescued Sita

The tale of Rama's devotion and righteousness comes to an end.
He returns to Ayodhya with Sita, to be crowned king.

The monkey army celebrates their hero's victory!

THANK YOU FOR PLAYING THE RAMAYANA!
""")

	await get_tree().create_timer(5.0).timeout

	_show_ending_stats()
	await get_tree().create_timer(3.0).timeout

	SceneTransition.fade_to_scene(self, "res://scenes3d/menu/main_menu.tscn")

func _show_ending_stats() -> void:
	if main_label:
		main_label.text = """
=== GAME STATISTICS ===
Total Chapters: 6
Quest Objectives: 8
Monkeys Recruited: 5+
Enemies Defeated: Numerous
Time Elapsed: Complete

Press any key to return to main menu...
"""

func _show_message(message: String) -> void:
	if main_label:
		main_label.text = message
	if objective_label:
		var first_line = message.split("\n")[0]
		objective_label.text = "📍 " + first_line

func _show_dialogue(dialogue: String) -> void:
	if dialogue_label:
		dialogue_label.text = dialogue

func _create_environment() -> void:
	if has_node("ThroneRoom"):
		get_node("ThroneRoom").queue_free()
	var throne_room = Node3D.new()
	throne_room.name = "ThroneRoom"
	add_child(throne_room)

	var floor = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(60, 60)
	floor.mesh = plane
	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.5, 0.4, 0.3)
	floor.set_surface_override_material(0, floor_mat)
	floor.position.y = -0.5
	throne_room.add_child(floor)

	var walls = MeshInstance3D.new()
	var wall_box = BoxMesh.new()
	wall_box.size = Vector3(60, 30, 60)
	walls.mesh = wall_box
	var wall_mat = StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.3, 0.2, 0.1)
	walls.set_surface_override_material(0, wall_mat)
	walls.position.y = 15
	throne_room.add_child(walls)

	var throne = MeshInstance3D.new()
	var throne_box = BoxMesh.new()
	throne_box.size = Vector3(8, 10, 8)
	throne.mesh = throne_box
	var throne_mat = StandardMaterial3D.new()
	throne_mat.albedo_color = Color(0.8, 0.7, 0.5)
	throne.set_surface_override_material(0, throne_mat)
	throne.position = Vector3(0, 5, 30)
	throne_room.add_child(throne)

	LightingSetup.setup_throne_lighting(throne_room)
